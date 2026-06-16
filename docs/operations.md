# CTN Operations Reference
CalTekNet · OSGeoLive 17 · github.com/calteknet/osgeo17-vcap
Named procedures for per-session and recurring operations.

## OP-01 · Start Full Stack
    bash /mnt/p4/home/kmw/vcap/vcap_boot.sh 2>&1 | tee ~/vcap_boot.log
From GitHub on any machine without p4:
    bash <(curl -fsSL https://raw.githubusercontent.com/calteknet/osgeo17-vcap/main/scripts/vcap_boot.sh)

## OP-02 · Restart Cloudflare Tunnel
    yes | cp /mnt/p4/home/kmw/osgeo17-vcap/config/cloudflared_config.yml ~/.cloudflared/config.yml
    pkill cloudflared 2>/dev/null; sleep 2
    cloudflared tunnel run exe-caltek &>/tmp/cloudflared.log &
    sleep 5 && tail -5 /tmp/cloudflared.log

## OP-03 · Deploy or Update Stack via Portainer
1. http://localhost:9000 → Stacks → Add stack
2. Name: vcap-{service}
3. Paste YAML from stacks/{name}.yml
4. Deploy — never use bare docker run or docker compose

## OP-04 · Add a Slide Deck
1. Author in eXeLearning → Export as HTML5 Website
2. Copy folder to: /mnt/p4/home/kmw/vcap/slides/{deck-name}/
3. Add link to slides/index.html
4. No restart needed — nginx reads bind mount directly
5. Verify: http://localhost:8085/{deck-name}/

## OP-05 · Save Work Before Shutdown
    sudo -u postgres pg_dumpall > /mnt/p4/home/kmw/vcap/postgis_dump_$(date +%Y%m%d).sql
    cd /mnt/p4/home/kmw/osgeo17-vcap
    git add -A && git commit -m "session: $(date +%Y%m%d)" && git push

## OP-06 · Add New Tunnel Ingress Rule
1. Edit: config/cloudflared_config.yml — add hostname before catch-all
2. git add -A && git commit -m "infra: add [hostname] ingress" && git push
3. Run OP-02
Current rules:
  exe.caltek.net       → localhost:8084  eXeLearning
  caltek.net/slides    → localhost:8085  Slides
  portainer.caltek.net → localhost:9000  Portainer

## OP-07 · Check All Services
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    tail -5 /tmp/cloudflared.log

## OP-08 · .elpx Round-Trip (chat ↔ exe.caltek.net)
1. https://exe.caltek.net → edit → Save → Export .elpx → upload to chat
2. Receive updated .elpx from chat
3. docker cp updated.elpx exelearning:/mnt/data/
4. Reload in browser

## Service URLs
| Service      | Local                          | Public                        |
|---|---|---|
| eXeLearning  | http://localhost:8084          | https://exe.caltek.net        |
| Slides       | http://localhost:8085          | https://caltek.net/slides     |
| Portainer    | http://localhost:9000          | https://portainer.caltek.net  |
| Elgg         | http://localhost:8086          | —                             |
| Traefik      | http://localhost:8090          | —                             |
| GeoServer    | http://localhost:8082/geoserver| —                             |
| MapProxy     | http://localhost:8070/demo     | —                             |
| Jupyter      | http://localhost:8888          | —                             |
| PostGIS      | localhost:5432                 | —                             |

## Tunnel Reference
  ID:          e7fbc420-297a-4fa6-922f-c8e2e0239cee
  Credentials: /home/user/.cloudflared/e7fbc420-297a-4fa6-922f-c8e2e0239cee.json
  Backup:      /mnt/p4/home/kmw/cloudflared_config/
## OP-09 — elgg_db init failure, recovery, and host hardening (2026-06-09 → 2026-06-11)

**Stack:** live-osgoe-ctn-vcap · **Host:** kmw-20hgs0cl00 (OSGeoLive 17, data on /mnt/p4)

### Symptom
elgg_db crash-looped for ~1 week. Elgg unreachable at localhost:8086.

### Root cause
`command: mariadbd-safe --skip-grant-tables` left in the compose db service.
It bypassed the official MariaDB entrypoint, so the 2026-06-01 first boot never
completed initialization (zeroed ibdata1, no elgg database, auth disabled).
All backups to that date were raw-file tars of the broken datadir — unusable.

### Fix
1. Destroyed the volume through Docker (`docker volume rm`), not host paths.
2. Corrected compose: removed skip-grant-tables, pinned `mariadb:11.4`,
   backup switched to `mariadb-dump --single-transaction | gzip` (14-day retention),
   added db healthcheck. Redeployed via Portainer; Elgg reinstalled 2026-06-11.

### Verification (2026-06-11)
- elgg_db `Up (healthy)`; Elgg renders and admin login works at localhost:8086.
- Manual dump: 679.5K `db_20260611_174200.sql.gz` containing real SQL.
- Root password identical across elgg_db and elgg_backup (md5 compare).
- Empty/corrupt Jun-11 dump files removed.

### Host hardening applied
- `/etc/fstab`: `UUID=e6ab2220-… /mnt/p4 ext4 defaults,nofail 0 2`
- `/etc/systemd/system/docker.service.d/p4-mount.conf`: `RequiresMountsFor=/mnt/p4`
- cloudflared tunnel `exe-caltek` moved from a bare user process to
  `/etc/systemd/system/cloudflared-exe.service` (enabled, Restart=always).
  This closes the multi-day exe.caltek.net outage vector.
- `docker swarm init --advertise-addr 127.0.0.1` — laptop is its own
  single-node swarm for stack-syntax parity with production. It never joins
  the 48gb/shec.us/la.caltek.net swarm.
- Backup loop hardened with `set -o pipefail` so a failed mariadb-dump can
  no longer report OK via gzip's exit code.

### Lessons
- Never leave recovery flags (`--skip-grant-tables`) in stack definitions.
- Backups must be logical dumps, verified by size and `zcat | head`.
- In a pipeline, test the producer's exit status (`pipefail`), not the consumer's.
- Anything public-facing runs under systemd or Docker restart policy — never nohup.

## OP-10 — Power failure recovery test (2026-06-13)
**Result: PASS — full auto-recovery, no intervention required.**
- /mnt/p4 mounted via fstab on boot ✓
- All 10 containers restarted via unless-stopped/swarm ✓
- cloudflared-exe tunnel auto-started via systemd ✓
- Odoo 19 local (http://localhost:8069) ✓
- Elgg (http://localhost:8086) ✓
- exe.caltek.net tunnel ✓
**This boot sequence is the replication target for all CTN nodes.**

## OP-21 — CTN VCAP ISO Remaster (2026-06-16)
- Base: OSGeoLive 17 (sda1 · /media/kmw/OSGEOLIVE17)
- Build workspace: /dev/sda4 → /mnt/sd4/iso-build/
- Output: /mnt/sd4/ctn-vcap-17.iso (4.0GB)
- Docker 29.5.3 pre-installed
- Apache vhosts pre-configured (8 *.localhost domains)
- vcap_boot.sh enabled as systemd service
- osgeo17-vcap repo cloned to /home/user/osgeo17-vcap
- Build command: see scripts/build-iso.sh
