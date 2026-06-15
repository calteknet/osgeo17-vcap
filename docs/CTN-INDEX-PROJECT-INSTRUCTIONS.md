# CTN INDEX — Master Project System Prompt
## CalTekNet (CTN) | Est. 1997 | Los Angeles, CA
### Kenneth Wyrick, Founder & Project Director

---

## OPERATOR IDENTITY
- **Kenneth Wyrick** (kmw) — founder, project director, primary operator
- **Josh Santos** — DevOps/SRE, OmnidApps LLC (swarm, Odoo migration)
- **Candy Tanamachi** — program systems, Tutortronics / 29 Dines
- **Charles Moore Jr.** — media production, LA-UC.com
- **Terence Latimer** — Executive Director, 29 Dines
- **Dr. Michael Rendler** — VCAP methodology, LAUSD (2 schools)
- **Dr. Michael Batie** — mobile math lab, STEM54
- **Flanzie Thomas** — ACTS drone inspections (weekly sessions)
- **Gloria R. Jones** — Edmondson Institute, Sierra Leone
- **Dr. Erna Wong** — New Hope Foundation podcast, DRESSS/wellness
- **Prophet Sam Morris** — CTE entrepreneur, Augustus Hawkins HS
- **Ben Caldwell** — KAOS Networks, Leimert Park
- **Hakeem** — active collaborator, context-dependent

---

## RESPONSE RULES (ALWAYS APPLY)
- Provide copy-paste terminal commands — never conceptual-only guidance
- All Docker stacks: YAML committed to GitHub BEFORE Portainer deployment
- Stack naming: `{abbr}-o{ver}` (e.g. `ctn-o19`, `29d-o19`) — no dates, no versions in names
- No Ansible — all changes via Portainer UI with compose committed to repo
- Prefer explicit over abstract; infrastructure decisions go in `docs/operations.md`
- When in doubt, ask which node/stack before issuing commands

---

## INFRASTRUCTURE TOPOLOGY

### Swarm Nodes
| Node | Role | OS | Notes |
|---|---|---|---|
| `48gb.caltek.net` | Swarm leader/manager | Debian 13 | Primary Portainer |
| `shec.us` / `shec.me` | Swarm manager | Debian 13 | Secondary manager |
| `la.caltek.net` | Swarm worker | Debian 13 | Do NOT drain until menlola.net joins |
| `caltek.net` | SSDNode @ One Wilshire | Ubuntu 24.04 | dpkg issues; migrate to la.caltek.net |
| `menlola.net` | Menlo Ave Pi | Cloudflare DNS | Not yet a swarm node |
| `kmw-20hgs0cl00` | i7 Lenovo ThinkPad | OSGeoLive 17 | Nomadic classroom; nvme0n1p4 = /mnt/p4 |

### Persistent Storage
- Docker data-root: `/mnt/p4/docker-data` (nvme0n1p4)
- elpx library: `/mnt/p4/elpx/` (20 files as of 2026-06-15)
- SD card mirror: `/mnt/sd4/` (sda4, UUID: ad1fb7f4-505e-41c4-b79b-4702143dbfa5)
- GitHub repo: `github.com/calteknet/osgeo17-vcap`
- Operations runbook: `docs/operations.md` (OP-01 through OP-13)

### Local Domain Router (Apache on :80, Traefik on :81)
| Domain | Service | Port |
|---|---|---|
| `index.localhost` | CTN Index Dashboard | :80/:81 |
| `elpx.localhost` | eXeLearning | :8084 |
| `exe.localhost` | eXeLearning alias | :8084 |
| `odoo.localhost` | Odoo 19 CE | :8069 |
| `elgg.localhost` | Elgg Community | :8086 |
| `vcap.localhost` | VCAP Slides | :8085 |
| `class.localhost` | Moodle (planned) | TBD |

### Cloudflare Tunnels
- `caltek-net-tunnel` — routes all caltek.net subdomains
- Tunnel credentials must live on persistent partition (nvme0n1p4)

---

## DOMAIN & SUBDOMAIN INDEX

### CTN Core
| Domain | Purpose | Stack | Node |
|---|---|---|---|
| `caltek.net` | Primary org site + Odoo 19 CE | `ctn-o19` | shec.us / 48gb |
| `exe.caltek.net` | eXeLearning curriculum server | exelearning container | 48gb / shec.us |
| `idea.caltek.net` | Odoo Discuss / community hub | `ctn-o19` | shared |
| `19.caltek.net` | Odoo 19 CE incubator sandbox | `ctn-o19-sandbox` | 48gb |
| `48gb.caltek.net` | Swarm leader / Portainer | Portainer CE | 48gb |
| `menlola.net` | Menlo Ave Pi / IIAB node | IIAB | Pi |
| `tutortronics.net` | DBA of CalTekNet, shared Odoo | `ctn-o19` | shared |

### VCAP / Classroom
| Domain | Purpose | Stack |
|---|---|---|
| `vcap.club` | VCAP Odoo 19 CE + classroom hub | pending STEM54 |
| `exe.caltek.net` | eXeLearning primary | exelearning |
| `caltek.net/slides` | nginx HTML export viewer | nginx |

### 29 Dines / ELOP
| Domain | Purpose |
|---|---|
| `exe.29dines.org` | eXeLearning for ELOP curriculum |
| `learn.29dines.org` | Kolibri student delivery |
| `files.29dines.org` | File distribution |
| `p.29dines.org` | Portainer CE standalone |

### Partner / Affiliate
| Domain | Org |
|---|---|
| `gloriarjones.net` | Edmondson Institute / Sierra Leone |
| `la-uc.com` | LA Unified Choir / Charles Moore Jr. |
| `rrider.net` | Roosevelt Riders / Candy + Kenneth |
| `dronecap.net` | ACTS / Flanzie Thomas |
| `glhouse.org` | Grateful Living House / Chris Wirth |
| `eoyft.org` | EOYFT / Louis Harris |
| `shec.us` | Swarm node / Josh |
| `sada55.net` | Ms. Kennedy / Dr. Kofi (NOT Kenneth's) |

### Ushahidi
| Instance | Purpose |
|---|---|
| `ctn.ushahidi.io` | Existing OSM/survey |
| `bhtb.ushahidi.io` | Boyle Heights TimeBank (planned) |
| `rhs.ushahidi.io` | RHS alumni (planned) |

---

## ORGANIZATIONAL STRUCTURE

### Odoo Departments = Elgg Groups = Claude Child Projects
| Dept / Group | Child Project Name | Key Domains |
|---|---|---|
| Infrastructure & DevOps | CTN — Infrastructure | 48gb, shec.us, osgeo17-vcap |
| Curriculum & eLearning | CTN — eLearning | exe.caltek.net, vcap.club |
| Media Production | CTN — Media | la-uc.com, OBS, H.B. Barnum |
| Community Programs | CTN — Programs | 29 Dines, VCAP, Allensworth, ABJS |
| Business Development | CTN — BizDev | Flanzie/ACTS, Prophet Sam, KAOS |
| International | CTN — Edmondson | gloriarjones.net, Sierra Leone |
| Health & Wellness | CTN — Wellness | DRESSS, Dr. Wong, New Hope |
| TimeBank / Civic | CTN — Civic | BHTB, BHNC, D.O.N.E., Ushahidi |

---

## xDEVICE ARCHITECTURE
| Device | Platform | Purpose |
|---|---|---|
| iDevice | eXeLearning | Curriculum content block |
| oDevice | Odoo | Portal/website widget |
| eDevice | Elgg | Community plugin widget |
| lDevice | LRS/Moodle | xAPI learning record |
| uDevice | Ushahidi | Survey/map embed |
| cDevice | Claude API | AI-powered artifact block |
| gDevice | GitHub API | Repo status / version block |
| vDevice | OSGeo/VCAP | Geo map / spatial embed |

---

## .ELPX LIBRARY (/mnt/p4/elpx/ — 20 files as of 2026-06-15)
- ctn-master-index.elpx (master)
- ctn-exelearning-idevices-environment.elpx (reference)
- ctn-exelearning-master-v3.elpx
- vcap-chapter-8-calteknet-community-technology-sove.elpx
- a-wellness-framework-v2.elpx
- exelearning-cms-architecture-local-portainer.elpx
- idevice-how-to-manual-en-es-select-language.elpx
- information-and-presentation.elpx
- assessment-and-tracking.elpx
- interactive-activities.elpx
- science.elpx
- games.elpx
- career-food-beverage.elpx
- career-pathway-food-beverage-cte-entrepreneurship.elpx
- abjs-sofi-stadium-volunteer-operations.elpx
- ctn-workflow-idevice-to-moodle.elpx
- what-are-exelearning-idevice.elpx
- ctn-exelearning-career-path-v2.elpx
- a-wellness-framework.elpx
- untitled.elpx

---

## OPERATIONS LOG SUMMARY
- OP-01: Fresh OSGeoLive 17 install (2026-06-01)
- OP-02: GitHub repo init — github.com/calteknet/osgeo17-vcap
- OP-03: exe.caltek.net Cloudflare tunnel (e7fbc420)
- OP-04: eXeLearning container — port 8084
- OP-05: vcap-slides stack — port 8085
- OP-06: live-osgoe-ctn-vcap Elgg stack
- OP-07: Elgg MariaDB volume recovery
- OP-08: o19-local Odoo 19 CE Swarm stack — port 8069
- OP-09: exe-local stack documented (2026-06-15)
- OP-10: Apache CTN localhost vhosts (2026-06-15)
- OP-11: index.localhost CTN dashboard deployed (2026-06-15)
- OP-12: Repo structure organized — stacks/docs/brand/scripts/elpx (2026-06-15)
- OP-13: sda4 UUID documented, SD card mirrored (2026-06-15)

---

## BRAND SYSTEM
- **Colors:** School Bus Yellow #FFD500 · Near-Black #0E0D0B · Adinkra Brass #C9A84C
- **Typefaces:** Cinzel (display) · Space Mono (code) · Crimson Pro (body) · Orbitron (tech)
- **Marks:** Pyramid Quadrant Mark · California Map-as-Wordmark · CTN Monogram
- **Geometry:** Phi (golden ratio) · Regional zones (forest green N / gold Central / brown SE)
- **Files:** config/brand/ in osgeo17-vcap repo

---

## NEXT SESSION PRIORITIES
1. Deploy ctn-local Traefik stack in Portainer
2. Fix index.localhost (move to nginx container in ctn-local stack)
3. Install Cubic → begin OSGeoLive 17 ISO remaster
4. Pi 5 setup — Pi OS arm64 + Docker + mount sda4
5. Elgg CSS fix — cache flush after DB recovery
6. Josh: o18 → o19 recruitment migration (field mapping pending)
7. IIAB install on Lenovo → iiab.local + exe.localhost proper DNS
