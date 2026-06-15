# CTN OSGeoLive 17 — Custom ISO Build Spec
## CalTekNet Nomadic Classroom Distro
**Kenneth Wyrick | github.com/calteknet/osgeo17-vcap | June 2026**

---

## Base & Philosophy

- **Base ISO:** OSGeoLive 17.0 (Lubuntu/Ubuntu 24.04 LTS)
- **Method:** `cubic` (Custom Ubuntu ISO Creator) remaster
- **Target:** 64GB+ USB or SD card with casper persistence OR direct nvme install
- **Hostname:** `vcap-classroom` (overrideable at boot)
- **Default user:** `kmw` / `vcap` (configurable)
- **Philosophy:** Boot → everything works. No internet required after first pull.

---

## What Gets Added to Base OSGeoLive

### Layer 1 — System packages (apt)
```bash
apt-get install -y \
  docker.io docker-compose-plugin \
  nginx apache2-utils \
  git curl wget python3-pip \
  cloudflared \
  ffmpeg obs-studio \
  audacity kdenlive \
  joplin-desktop \
  syncthing \
  chromium-browser \
  xdotool wmctrl
```

### Layer 2 — Docker stack pre-pull (images cached in ISO)
```bash
docker pull traefik:latest
docker pull nginx:alpine
docker pull exelearning/exelearning:latest
docker pull mariadb:11.4
docker pull postgres:18
docker pull odoo:19
docker pull portainer/portainer-ce:latest
```

### Layer 3 — CTN repo baked in
```bash
git clone https://github.com/calteknet/osgeo17-vcap.git /opt/ctn/osgeo17-vcap
# Includes:
# - stacks/ctn-local/docker-compose.yml  (Traefik-native)
# - stacks/exe-local/docker-compose.yml
# - stacks/o19-local/docker-compose.yml
# - config/apache/ctn-local.conf
# - dashboard/index.html
# - docs/operations.md (OP-01 through OP-11+)
# - scripts/ctn-boot.sh
```

### Layer 4 — .elpx library baked in
```bash
mkdir -p /opt/ctn/elpx
# Copy all current .elpx files:
cp *.elpx /opt/ctn/elpx/
# - ctn-master-index.elpx
# - ctn-exelearning-idevices-environment.elpx
# - vcap-chapter-8.elpx
# - a-wellness-framework-v2.elpx
# - exelearning-cms-architecture.elpx
# - idevice-how-to-manual-en-es.elpx
# - information-and-presentation.elpx
# - assessment-and-tracking.elpx
# - interactive-activities.elpx
# - science.elpx
# - games.elpx
```

### Layer 5 — .elp legacy converter script
```bash
cat > /opt/ctn/scripts/convert-elp.sh << 'SCRIPT'
#!/bin/bash
# Auto-convert legacy .elp files to .elpx
# Usage: ./convert-elp.sh /path/to/files/
# Drops converted .elpx into /opt/ctn/elpx/
INDIR=${1:-.}
OUTDIR=/opt/ctn/elpx
mkdir -p "$OUTDIR"
find "$INDIR" -name "*.elp" | while read f; do
  base=$(basename "$f" .elp)
  echo "Converting: $f"
  cp "$f" "$OUTDIR/${base}.elpx"
  echo "  → $OUTDIR/${base}.elpx"
done
echo "Done. Files in $OUTDIR:"
ls -lh "$OUTDIR"/*.elpx 2>/dev/null
SCRIPT
chmod +x /opt/ctn/scripts/convert-elp.sh
```

### Layer 6 — CTN boot script (runs on first login)
```bash
cat > /opt/ctn/scripts/ctn-boot.sh << 'SCRIPT'
#!/bin/bash
# CTN Boot — starts all local services
# Runs via ~/.config/autostart/ctn-boot.desktop

echo "[CTN] Checking /mnt/p4 mount..."
mountpoint -q /mnt/p4 || sudo mount /dev/nvme0n1p4 /mnt/p4

echo "[CTN] Starting Docker stacks..."
cd /opt/ctn/osgeo17-vcap
docker compose -f stacks/ctn-local/docker-compose.yml up -d
docker compose -f stacks/o19-local/docker-compose.yml up -d

echo "[CTN] Starting Portainer..."
docker start portainer 2>/dev/null || \
docker run -d --name portainer \
  -p 9000:9000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  --restart unless-stopped \
  portainer/portainer-ce:latest

echo "[CTN] Starting cloudflared..."
systemctl start cloudflared 2>/dev/null

echo "[CTN] All services started."
echo "[CTN] Open: http://index.localhost:81"
SCRIPT
chmod +x /opt/ctn/scripts/ctn-boot.sh
```

### Layer 7 — Chromium bookmarks baked in
```
Bookmarks toolbar:
├── CTN Index        → http://index.localhost:81
├── eXeLearning      → http://elpx.localhost:81
├── Odoo             → http://odoo.localhost:81
├── Elgg             → http://elgg.localhost:81
├── VCAP Slides      → http://vcap.localhost:81
├── Portainer        → http://localhost:9000
├── OSGeoLive Docs   → http://localhost/osgeolive/en/index.html
├── exe.caltek.net   → https://exe.caltek.net
└── GitHub Repo      → https://github.com/calteknet/osgeo17-vcap
```

### Layer 8 — /etc/hosts CTN entries
```
127.0.0.1  index.localhost
127.0.0.1  elpx.localhost
127.0.0.1  exe.localhost
127.0.0.1  odoo.localhost
127.0.0.1  elgg.localhost
127.0.0.1  vcap.localhost
127.0.0.1  class.localhost
```

---

## Cubic Build Steps

```bash
# 1. Install Cubic on Ubuntu build machine
sudo apt-add-repository ppa:cubic-wizard/release
sudo apt-get install cubic

# 2. Open Cubic → select OSGeoLive 17.0 ISO as input
# 3. Set output ISO name: ctn-osgeolive17-vcap-v1.iso
# 4. In the Cubic chroot terminal, run layers 1-8 above in order
# 5. Add /etc/hosts entries
# 6. Copy .elpx files to /opt/ctn/elpx/
# 7. Git clone the repo to /opt/ctn/osgeo17-vcap
# 8. Set autostart: cp ctn-boot.desktop ~/.config/autostart/
# 9. Generate ISO → write to USB with:

sudo dd if=ctn-osgeolive17-vcap-v1.iso of=/dev/sdX bs=4M status=progress
# OR use Ventoy (preferred — drop ISO onto Ventoy drive)
```

---

## ISO Naming Convention
```
ctn-osgeolive17-vcap-v1.iso     ← first release
ctn-osgeolive17-vcap-v1.1.iso   ← minor update
ctn-osgeolive17-vcap-v2.iso     ← major (new OSGeoLive base)
```

---

## Distribution Targets
| Target | Method | Notes |
|--------|--------|-------|
| Kenneth's Lenovo | nvme install (already done) | current working node |
| STEM54 (Dr. Batie) | USB Ventoy | vcap.club server |
| Menlo Ave Pi | arm64 variant needed | menlola.net |
| Dr. Rendler (2 schools) | USB Ventoy | LAUSD VCAP |
| Dr. Wong | USB Ventoy + instruction sheet | non-technical user |
| Ghana schools | 1TB image / USB | IIAB content pack included |
| Edmondson Institute | arm64 Pi variant | gloriarjones.net / Sierra Leone |

---

## Next Steps After ISO Build
1. Push complete `stacks/ctn-local/docker-compose.yml` to GitHub
2. Test full boot → `http://index.localhost:81` loads dashboard
3. Run `convert-elp.sh` on each old laptop to rescue legacy .elp files
4. Add IIAB layer for offline content (Kiwix ZIMs, Khan Academy Lite)
5. Add Moodle stack → `class.localhost:81`
6. Build arm64 variant for Pi nodes

*Commit this file to: github.com/calteknet/osgeo17-vcap/docs/iso-build-spec.md*
