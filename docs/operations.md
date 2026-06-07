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
