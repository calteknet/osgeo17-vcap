#!/bin/bash
# CTN VCAP Boot — OSGeoLive 17 · CalTekNet Nomadic Classroom
# Usage: bash /opt/ctn/osgeo17-vcap/scripts/vcap_boot.sh 2>&1 | tee ~/vcap_boot.log
# Or from GitHub: bash <(curl -fsSL https://raw.githubusercontent.com/calteknet/osgeo17-vcap/main/scripts/vcap_boot.sh)

set -euo pipefail
echo "=== CTN VCAP Boot — $(date) ==="

# Repo path — ISO bakes to /opt/ctn, live nvme uses /home/kmw
REPO=/opt/ctn/osgeo17-vcap
[ -d /home/kmw/osgeo17-vcap ] && REPO=/home/kmw/osgeo17-vcap
echo "✓ Repo → $REPO"

# Mount nvme p4
sudo mkdir -p /mnt/p4
sudo mount /dev/nvme0n1p4 /mnt/p4 2>/dev/null && \
  echo "✓ nvme mounted → /mnt/p4" || echo "~ /mnt/p4 already mounted"

# Docker — install if missing, point data-root → nvme
if ! command -v docker &>/dev/null; then
  echo "Installing docker.io..."
  sudo apt-get update -q 2>&1 | tail -1
  sudo apt-get install -y docker.io docker-compose-plugin -q 2>&1 | tail -2
fi

sudo mkdir -p /mnt/p4/docker-data
sudo cp "$REPO/host/daemon.json" /etc/docker/daemon.json
sudo systemctl restart docker
sleep 4
sudo chmod 666 /var/run/docker.sock
echo "✓ Docker VFS → /mnt/p4/docker-data"

# Shared network
docker network create vcap_net 2>/dev/null || true

# Portainer
docker start portainer 2>/dev/null || \
docker run -d --name portainer --restart unless-stopped \
  -p 9000:9000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest
echo "✓ Portainer → http://localhost:9000"

# Traefik (reverse proxy, port 81)
docker start traefik 2>/dev/null || \
docker run -d --name traefik --restart unless-stopped \
  -p 81:81 -p 8090:8080 \
  --network vcap_net \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  traefik:v3.0 \
  --api.dashboard=true --api.insecure=true \
  --providers.docker=true \
  --providers.docker.exposedbydefault=false \
  --entrypoints.web.address=:81 \
  --log.level=INFO
echo "✓ Traefik → http://localhost:8090/dashboard/"

# CTN Local stack (dashboard · eXeLearning · Elgg · vcap-slides · class)
docker compose -f "$REPO/stacks/ctn-local/docker-compose.yml" up -d
echo "✓ CTN stack → http://index.localhost:81"

# Odoo 19 (optional — skip if no env file)
ODOO_ENV="$REPO/infra/o19-local/.env"
if [ -f "$ODOO_ENV" ]; then
  docker compose --env-file "$ODOO_ENV" \
    -f "$REPO/infra/o19-local/docker-compose.yml" up -d
  echo "✓ Odoo 19 → http://localhost:8069"
else
  echo "~ Odoo skipped (no $ODOO_ENV — run setup-once.sh first)"
fi

# Mailpit (SMTP catch-all)
docker compose -f "$REPO/stacks/mailpit/docker-compose.yml" up -d
echo "✓ Mailpit → http://localhost:8025"

# /etc/hosts CTN entries
for host in index elpx exe odoo elgg vcap class mail; do
  grep -q "^127\.0\.0\.1.*${host}\.localhost" /etc/hosts 2>/dev/null || \
    echo "127.0.0.1  ${host}.localhost" | sudo tee -a /etc/hosts >/dev/null
done
echo "✓ /etc/hosts patched"

# PostGIS (OSGeoLive ships postgres)
sudo systemctl start postgresql 2>/dev/null || true
sleep 2
sudo -u postgres psql -c "CREATE DATABASE vcap_classroom;" 2>/dev/null || true
sudo -u postgres psql -c "CREATE EXTENSION IF NOT EXISTS postgis;" -d vcap_classroom 2>/dev/null || true
sudo -u postgres psql -c "CREATE ROLE \"user\" LOGIN SUPERUSER;" 2>/dev/null || true
sudo -u postgres psql -c "GRANT ALL ON DATABASE vcap_classroom TO \"user\";" 2>/dev/null || true
echo "✓ PostGIS → psql -d vcap_classroom"

# GeoServer
export JAVA_HOME
JAVA_HOME=$(dirname "$(dirname "$(readlink -f "$(which java)")")")
GEOSERVER_HOME=${GEOSERVER_HOME:-/usr/local/lib/geoserver}
if [ -f "$GEOSERVER_HOME/bin/startup.sh" ]; then
  sudo -E bash "$GEOSERVER_HOME/bin/startup.sh" &>/tmp/geoserver.log &
  echo "~ GeoServer → http://localhost:8082/geoserver (45s warmup)"
fi

# MapProxy
if command -v mapproxy-util &>/dev/null; then
  MPCFG=/mnt/p4/home/kmw/vcap/vcap_mapproxy.yaml
  [ ! -f "$MPCFG" ] && MPCFG="$REPO/config/vcap_mapproxy.yaml"
  mkdir -p "$HOME/mapproxy"
  cp "$MPCFG" "$HOME/mapproxy/mapproxy.yaml" 2>/dev/null || true
  mapproxy-util serve-develop "$HOME/mapproxy/mapproxy.yaml" \
    --bind 0.0.0.0:8070 &>/tmp/mapproxy.log &
  echo "✓ MapProxy → http://localhost:8070/demo"
fi

# Jupyter
if command -v jupyter &>/dev/null; then
  mkdir -p "$HOME/vcap_notebooks"
  cp -r /mnt/p4/home/kmw/vcap/vcap_notebooks/* "$HOME/vcap_notebooks/" 2>/dev/null || true
  jupyter notebook --no-browser --ip=0.0.0.0 --port=8888 \
    --NotebookApp.token='' --NotebookApp.password='' \
    --notebook-dir="$HOME/vcap_notebooks" &>/tmp/jupyter.log &
  echo "✓ Jupyter → http://localhost:8888"
fi

# Cloudflare tunnel
cp "$REPO/config/cloudflared_config.yml" "$HOME/.cloudflared/config.yml" 2>/dev/null || true
if command -v cloudflared &>/dev/null && ls "$HOME/.cloudflared/"*.json &>/dev/null; then
  pkill cloudflared 2>/dev/null; sleep 2
  cloudflared tunnel run exe-caltek &>/tmp/cloudflared.log &
  echo "✓ Cloudflare → https://exe.caltek.net"
else
  echo "~ cloudflared skipped (no credentials)"
fi

# Apache — disable default vhost
sudo a2dissite 000-default.conf 2>/dev/null || true
sudo systemctl reload apache2 2>/dev/null || true

echo ""
echo "════════════════════════════════════════════════"
echo " CTN VCAP · $(date '+%Y-%m-%d %H:%M')"
echo "════════════════════════════════════════════════"
echo " Dashboard    → http://index.localhost:81"
echo " eXeLearning  → http://elpx.localhost:81"
echo " Elgg         → http://elgg.localhost:81"
echo " Odoo 19      → http://odoo.localhost:81 | :8069"
echo " VCAP Slides  → http://vcap.localhost:81"
echo " Mailpit      → http://mail.localhost:81 | :8025"
echo " Portainer    → http://localhost:9000"
echo " Traefik      → http://localhost:8090/dashboard/"
echo " GeoServer    → http://localhost:8082/geoserver"
echo " MapProxy     → http://localhost:8070/demo"
echo " Jupyter      → http://localhost:8888"
echo " eXe (public) → https://exe.caltek.net"
echo "════════════════════════════════════════════════"
