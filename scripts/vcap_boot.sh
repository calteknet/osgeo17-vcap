#!/bin/bash
# VCAP CTN LMS — Full Boot Script for OSGeoLive 17
# Run: bash /mnt/p4/home/kmw/vcap/vcap_boot.sh 2>&1 | tee ~/vcap_boot.log

echo "=== VCAP CTN Boot — $(date) ==="

# Mount nvme
sudo mkdir -p /mnt/p4
sudo mount /dev/nvme0n1p4 /mnt/p4 2>/dev/null && \
  echo "✓ nvme mounted" || echo "~ nvme already mounted"

# Install Docker if missing — always update cache first
if ! command -v docker &>/dev/null; then
  echo "Installing Docker..."
  sudo apt-get update -q 2>&1 | tail -1
  sudo apt-get install -y docker.io -q 2>&1 | tail -2
fi

# Configure Docker → nvme
sudo mkdir -p /etc/docker /mnt/p4/docker-data
sudo tee /etc/docker/daemon.json > /dev/null << 'DOCKEREOF'
{
  "storage-driver": "vfs",
  "data-root": "/mnt/p4/docker-data",
  "log-driver": "json-file",
  "log-opts": {"max-size": "10m", "max-file": "3"}
}
DOCKEREOF
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
  -v /mnt/p4/docker-data/portainer:/data \
  portainer/portainer-ce:latest
echo "✓ Portainer → http://localhost:9000"

# Traefik
docker start traefik 2>/dev/null || \
docker run -d --name traefik --restart unless-stopped \
  -p 81:81 -p 8090:8080 \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  traefik:v3.0 \
  --api.dashboard=true --api.insecure=true \
  --providers.docker=true \
  --providers.docker.exposedbydefault=false \
  --entrypoints.web.address=:81 \
  --log.level=INFO
echo "✓ Traefik → http://localhost:8090/dashboard/"

# Elgg stack
docker start elgg_db php-fpm elgg_nginx elgg_backup 2>/dev/null || \
docker compose -f /mnt/p4/home/kmw/vcap/vcap_stacks/vcap_elgg.yml up -d
echo "✓ Elgg → http://localhost:8086"

# PostGIS
sudo systemctl start postgresql
sleep 2
sudo -u postgres psql -c "CREATE DATABASE vcap_classroom;" 2>/dev/null || true
sudo -u postgres psql -c "CREATE EXTENSION IF NOT EXISTS postgis;" -d vcap_classroom 2>/dev/null || true
sudo -u postgres psql -d vcap_classroom -f /mnt/p4/home/kmw/vcap/vcap_classroom_dump.sql >/tmp/pg_restore.log 2>&1 || true
sudo -u postgres psql -c "CREATE ROLE \"user\" LOGIN SUPERUSER;" 2>/dev/null || true
sudo -u postgres psql -c "GRANT ALL ON DATABASE vcap_classroom TO \"user\";" 2>/dev/null || true
echo "✓ PostGIS → psql -d vcap_classroom"

# GeoServer on 8082
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
sudo -E bash /usr/local/lib/geoserver-2.27.1/bin/startup.sh &>/tmp/geoserver.log &
echo "~ GeoServer → http://localhost:8082/geoserver (45s warmup)"

# MapProxy
mkdir -p $HOME/mapproxy
cp /mnt/p4/home/kmw/vcap/vcap_mapproxy.yaml $HOME/mapproxy/mapproxy.yaml
cd $HOME/mapproxy
mapproxy-util serve-develop mapproxy.yaml --bind 0.0.0.0:8070 &>/tmp/mapproxy.log &
echo "✓ MapProxy → http://localhost:8070/demo"

# Jupyter
mkdir -p $HOME/vcap_notebooks
cp -r /mnt/p4/home/kmw/vcap/vcap_notebooks/* $HOME/vcap_notebooks/ 2>/dev/null || true
jupyter notebook --no-browser --ip=0.0.0.0 --port=8888 \
  --NotebookApp.token='' --NotebookApp.password='' \
  --notebook-dir=$HOME/vcap_notebooks &>/tmp/jupyter.log &
echo "✓ Jupyter → http://localhost:8888"

# eXeLearning
docker start exelearning 2>/dev/null || \
docker run -d --name exelearning --restart unless-stopped \
  -p 8084:8080 --network vcap_net \
  -e APP_ONLINE_MODE=0 \
  -v /mnt/p4/docker-data/exelearning:/mnt/data \
  ghcr.io/exelearning/exelearning:latest
echo "✓ eXeLearning → http://localhost:8084"

echo ""
echo "================================================="
echo " VCAP CTN LMS — $(date)"
echo "================================================="
echo " Portainer    → http://localhost:9000"
echo " Traefik      → http://localhost:8090/dashboard/"
echo " GeoServer    → http://localhost:8082/geoserver"
echo " MapProxy     → http://localhost:8070/demo"
echo " Jupyter      → http://localhost:8888"
echo " Elgg         → http://localhost:8086"
echo " Cesium       → http://localhost/cesium/Apps/CesiumViewer/"
echo " PostGIS      → psql -d vcap_classroom"
echo "================================================="

# Cloudflare tunnel — exe.caltek.net → localhost:8084
cp -r /mnt/p4/home/kmw/cloudflared_config ~/.cloudflared 2>/dev/null || true
cloudflared tunnel run exe-caltek &>/tmp/cloudflared.log &
echo "✓ Cloudflare tunnel → https://exe.caltek.net"

# Slides stack
mkdir -p /mnt/p4/home/kmw/vcap/slides /mnt/p4/home/kmw/config/slides
docker start vcap_slides 2>/dev/null || docker compose -f /mnt/p4/home/kmw/osgeo17-vcap/stacks/vcap-slides.yml up -d
echo "✓ Slides → http://localhost:8085 · https://caltek.net/slides"
# Cloudflare tunnel full config
cp /mnt/p4/home/kmw/osgeo17-vcap/config/cloudflared_config.yml /home/kmw/.cloudflared/config.yml
pkill cloudflared 2>/dev/null || true; sleep 2
cloudflared tunnel run exe-caltek &>/tmp/cloudflared.log &
echo "✓ Tunnel → exe.caltek.net + caltek.net/slides"
