#!/bin/bash
# vcap_boot.sh — CTN VCAP post-boot sequence · OSGeoLive 17
# Run after reboot to ensure all services and mounts are ready
# OP-20 · github.com/calteknet/osgeo17-vcap

echo "=== CTN VCAP Boot Sequence ==="

# 1. Mount sda4 if not already mounted
if ! mountpoint -q /mnt/sd4; then
  echo "[mount] Mounting /dev/sda4 → /mnt/sd4"
  sudo mount /dev/sda4 /mnt/sd4 && echo "[mount] OK" || echo "[mount] FAILED"
else
  echo "[mount] /mnt/sd4 already mounted"
fi

# 2. Ensure Apache is running
sudo systemctl is-active --quiet apache2 && \
  echo "[apache] running" || \
  { sudo systemctl start apache2 && echo "[apache] started"; }

# 3. Domain health check
echo ""
echo "=== Domain Status ==="
for domain in index elpx exe odoo elgg vcap class mail; do
  code=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Host: $domain.localhost" http://localhost/)
  printf "  %-20s %s\n" "$domain.localhost" "$code"
done

echo ""
echo "=== Container Status ==="
docker ps --format "  {{.Names}}\t{{.Status}}" | sort

echo ""
echo "=== Boot sequence complete ==="
echo "  Portainer: http://localhost:9000"
echo "  Index:     http://index.localhost"
echo "  Mail:      http://mail.localhost"
