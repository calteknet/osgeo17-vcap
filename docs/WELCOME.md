# CTN OSGeoLive 17 — VCAP Nomadic Classroom
**CalTekNet Independent Media Production · caltek.net · Est. 1997**

## What is running on this machine

| Service | URL | Purpose |
|---|---|---|
| Portainer | http://localhost:9000 | Manage all stacks |
| Elgg (idea) | http://localhost:8086 | Community platform |
| eXeLearning | https://exe.caltek.net | Course authoring |
| Odoo 19 local | http://localhost:8069 | ERP incubator twin |
| VCAP Slides | http://localhost:8085 | Published curriculum |

## Quick health check
```bash
docker ps --format 'table {{.Names}}\t{{.Status}}'
systemctl status cloudflared-exe --no-pager | head -3
```

## Stack locations
```
~/stacks/
  live-osgoe-ctn-vcap/   # Elgg community platform
  o19-local/             # Odoo 19 CE incubator
~/osgeo17-vcap/          # Git repo — source of truth
  infra/                 # All stack compose files
  docs/operations.md     # OP-01 through OP-09+
  odoo/import/           # CSV starter sets
```

## The six CTN service lines
1. Instructional Development — eXeLearning · SCORM · xAPI
2. Learning Resources Hosting — Moodle · Kolibri · IIAB
3. ERP & Business Systems — Odoo 19 CE
4. Open Source Software Stewardship — Docker Swarm · Portainer
5. Multi-Media Production — OBS · PreSonus · YouTube
6. Civic Engagement Platforms — Ushahidi · TimeBank · Elgg

## Replication recipe (new machine)
```bash
# 1. Install Docker + Portainer
# 2. docker swarm init --advertise-addr 127.0.0.1
# 3. git clone https://github.com/calteknet/osgeo17-vcap
# 4. Copy .env files into ~/stacks/ (NOT from git — secrets)
# 5. Deploy stacks from infra/ via Portainer
# 6. Restore DB volumes from /backup dumps
# 7. sudo systemctl enable --now cloudflared-exe
```

## Key contacts
- Josh Santos — DevOps/SRE · josh@santos.cloud
- Candy Tanamachi — Program Systems · Tutortronics/29 Dines
- Charles Moore Jr. — Media Production · LA-UC.com
- Dr. Michael Batie — STEM54 · stem54.com
- Dr. Michael Rendler — VCAP/LAUSD
- Ben Caldwell — KAOS Networks · Leimert Park

*Repo: github.com/calteknet/osgeo17-vcap*
