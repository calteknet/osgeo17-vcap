# OSGeoLive 17 — VCAP Nomadic Classroom
CalTekNet distro customization. Boot any machine with OSGeoLive 17 and run:

    bash <(curl -fsSL https://raw.githubusercontent.com/calteknet/osgeo17-vcap/main/scripts/vcap_boot.sh)

## Services after boot
| Service | URL |
|---|---|
| eXeLearning | https://exe.caltek.net |
| Portainer | http://localhost:9000 |
| Elgg | http://localhost:8086 |
| Traefik | http://localhost:8090/dashboard/ |
| GeoServer | http://localhost:8082/geoserver |
| MapProxy | http://localhost:8070/demo |
| Jupyter | http://localhost:8888 |

## Structure
- `scripts/` — vcap_boot.sh master bootstrap
- `stacks/` — Docker Compose stack definitions
- `config/` — MapProxy, cloudflared configs
- `docs/` — Runbook HTML and reference docs

CalTekNet · FLOSS TekNowledgy · caltek.net · Est. 1997
