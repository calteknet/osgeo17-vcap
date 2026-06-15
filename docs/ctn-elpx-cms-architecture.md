# CTN eXeLearning CMS Architecture
## Dynamic .elpx Content Management — Portainer Stack Guide
**CalTekNet | Kenneth Wyrick | June 2026**

---

## Your Question: Local VM vs. Portainer vs. Proxmox?

**Short answer: Portainer. Not the local VM. Proxmox later, for different reasons.**

Here is the breakdown:

### ❌ Local VM (VirtualBox / VMware desktop)
- Breaks portability — ties eXeLearning to your laptop hardware
- No path to swarm distribution or CI/CD
- Snapshots eat disk on nvme0n1p4
- Doesn't integrate with Cloudflare tunnel (exe.caltek.net is already live as a container)
- **Skip this entirely**

### ✅ Portainer + Docker (Current correct path)
- exe.caltek.net is already running this way — you are already here
- .elpx files persist on nvme0n1p4 via volume mounts
- Stack is committed to `github.com/calteknet/osgeo17-vcap`
- Cloudflare tunnel (ID `e7fbc420`) connects the container to the public web
- Portainer webhooks can eventually trigger .elpx auto-generation from Odoo /jobs
- Works on kmw-20hgs0cl00 (nomadic), shec.us (manager), 48gb.caltek.net (leader)
- **This is your platform**

### 🔜 Proxmox (Future — CTN Ultimate Community OS)
- Correct for: STEM54 server (Dr. Batie), 48gb.caltek.net upgrade, multi-tenant community nodes
- Proxmox VE is Debian-based — aligns with CTN stack philosophy
- Enables VM isolation per tenant org (VCAP, 29 Dines, EOYFT, ABJS etc.) on shared hardware
- **Not needed on kmw-20hgs0cl00 today** — single-tenant nomadic node doesn't benefit from KVM overhead
- **Plan for STEM54 and any community-hosted bare-metal node serving multiple orgs**

---

## eXeLearning Container Stack (Portainer YAML)

```yaml
version: "3.8"

services:
  exelearning:
    image: exelearning/exelearning:latest
    container_name: exe-caltek
    ports:
      - "8080:8080"
    volumes:
      - /mnt/nvme0n1p4/elpx:/data/elpx          # persistent .elpx library
      - /mnt/nvme0n1p4/exports:/data/exports     # exported HTML/SCORM
      - /mnt/nvme0n1p4/creds:/data/creds         # tunnel credentials (NOT in container)
    environment:
      - EXE_DATA_DIR=/data/elpx
    restart: unless-stopped
    networks:
      - ctn-overlay

networks:
  ctn-overlay:
    external: true
```

**Critical:** Tunnel credentials (`e7fbc420`) must live on nvme0n1p4, not inside the container layer. This was the root cause of the 530/Error 1033 outage. Add to systemd:

```ini
# /etc/systemd/system/cloudflared.service.d/override.conf
[Unit]
After=mnt-nvme0n1p4.mount
Requires=mnt-nvme0n1p4.mount
```

And `/etc/fstab`:
```
UUID=<nvme0n1p4-uuid>  /mnt/nvme0n1p4  ext4  defaults,nofail  0  2
```

---

## .elpx File Naming Convention and Library Structure

```
/mnt/nvme0n1p4/elpx/
├── master/
│   └── ctn-master-index.elpx          ← single source of truth
├── idevices/
│   └── ctn-idevices-reference.elpx    ← pages 1–6 (iDevice how-to)
├── curriculum/
│   ├── ctn-vcap-8week.elpx            ← VCAP Chapter 8 + weeks 1–8
│   └── ctn-idevices-howto-en-es.elpx  ← bilingual manual
├── career/
│   ├── career-food-beverage.elpx      ← Levels 1–3 certs
│   └── career-cte-vcap.elpx           ← Levels 4–7 entrepreneur track
├── events/
│   └── abjs-sofi-volunteer.elpx       ← ABJS SoFi Stadium onboarding
├── jobs/                              ← auto-generated from Odoo /jobs
│   └── jobs-food-service-musd.elpx
├── surveys/                           ← auto-generated from Ushahidi
│   └── survey-pico-union-2026.elpx
├── slides/                            ← sourced from caltek.net/slides
│   └── slides-fathers-time.elpx
└── learners/
    └── learners-dynamic.elpx          ← auto-assembled active cohort
```

---

## Dynamic .elpx Generation Pipeline — /jobs → /slides → learners.elpx

### Data Sources → iDevice Standards

| Source | API | iDevice Standard | Output File |
|--------|-----|-----------------|-------------|
| Odoo 19 /jobs | `19.caltek.net/api/v2/jobs` | Case Study + Form + Checklist | `jobs-[sector].elpx` |
| Odoo /surveys | Survey module export | Form + Progress Report + Map | `survey-[community].elpx` |
| caltek.net/slides | nginx directory | Presentation + UDL Content | `slides-[topic].elpx` |
| ABJS volunteer docs | Manual / email | Checklist + True or False | `event-abjs.elpx` |
| Ushahidi | `ctn.ushahidi.io/api/v3` | Map + Form | `survey-[area].elpx` |
| Moodle completions | MDL API | Progress Report → Odoo | `learners-dynamic.elpx` |

### Generation Script Concept (Python)

```python
#!/usr/bin/env python3
"""
ctn_elpx_generator.py — generates named .elpx files from Odoo /jobs
Run via Portainer scheduled task or Odoo webhook
"""
import zipfile, json, requests, shutil, os
from datetime import datetime

ODOO_URL = "https://19.caltek.net"
ELPX_TEMPLATE = "/mnt/nvme0n1p4/elpx/master/ctn-master-index.elpx"
OUTPUT_DIR = "/mnt/nvme0n1p4/elpx/jobs/"

def fetch_jobs():
    r = requests.get(f"{ODOO_URL}/api/v2/jobs", 
                     headers={"Authorization": "Bearer $ODOO_API_KEY"})
    return r.json()['records']

def build_elpx_page(job):
    """Returns XML string for one job as a Case Study + Checklist iDevice block"""
    title = job['name']
    org = job.get('company_id', {}).get('name', 'CTN Partner')
    desc = job.get('description', '')
    reqs = job.get('requirements', '')
    
    return f"""
<odeNavStructure>
  <odePageId>page-job-{job['id']}</odePageId>
  <odeParentPageId></odeParentPageId>
  <pageName>Job: {title} — {org}</pageName>
  <odeNavStructureOrder>99</odeNavStructureOrder>
  ...
  <!-- Case Study iDevice with job description -->
  <!-- Checklist iDevice with requirements -->
  <!-- Form iDevice with application self-assessment -->
</odeNavStructure>
"""

if __name__ == "__main__":
    jobs = fetch_jobs()
    # Group by sector, build one .elpx per sector
    # (implementation continues)
    print(f"Generated {len(jobs)} job pages")
```

---

## Application Interoperability Map

```
idea.caltek.net (ideation)
        ↓
exe.caltek.net (eXeLearning authoring — Docker/Portainer)
        ↓ .elpx export
   ┌────┴────────────────────┬──────────────────┐
   ↓                         ↓                  ↓
Moodle 4.4 LTS          caltek.net/slides    IIAB/Kolibri
(SCORM/IMS upload)      (HTML export/nginx)  (offline USB/SD)
(badge issuance)        (Port 8085)          (nomadic class)
   ↓
Learning Locker (xAPI/LRS)
   ↓
Odoo 19 CE (19.caltek.net)
├── /jobs → elpx_generator.py → new .elpx → exe.caltek.net
├── /surveys → community needs → .elpx → Moodle enrollment
├── /events → volunteer onboarding .elpx (ABJS, Allensworth, etc.)
└── /timesheets → ASNTB TimeBank credits for facilitators
        ↓
GitHub (github.com/calteknet/osgeo17-vcap)
└── version-controlled .elpx + compose YMLs
```

---

## Planned Named .elpx Export Library

| File | Source Pages | Audience | Distribution |
|------|-------------|----------|-------------|
| `ctn-master-index.elpx` | All 25+ pages | CTN team | exe.caltek.net only |
| `ctn-idevices-reference.elpx` | Pages 1–6 | Curriculum authors | Moodle + exe |
| `ctn-idevices-howto-en-es.elpx` | How-To Manual page | All facilitators | exe + USB |
| `ctn-vcap-8week.elpx` | VCAP Ch.8 + Weeks 1–8 | Rendler/Batie cohorts | Kolibri + IIAB |
| `career-food-beverage.elpx` | Career Levels 1–3 | 29 Dines, ABJS | Moodle + HTML |
| `career-cte-vcap.elpx` | Career Levels 4–7 | CTE students | vcap.club USB |
| `abjs-sofi-volunteer.elpx` | ABJS SoFi page | ABJS volunteers | Email + Moodle |
| `ctn-cms-architecture.elpx` | CMS Architecture page | Josh Santos, DevOps | GitHub |
| `jobs-[sector].elpx` | Generated from Odoo | Job seekers | Dynamic |
| `survey-[community].elpx` | Generated from Ushahidi | Cohort members | Dynamic |
| `learners-dynamic.elpx` | Auto-assembled | Active cohort | Moodle trigger |

---

## Proxmox — CTN Ultimate Community OS Roadmap

| Deployment | Timing | Use Case |
|-----------|--------|---------|
| kmw-20hgs0cl00 (nomadic) | Now | Portainer only — no Proxmox |
| STEM54 (Dr. Batie) | Q3 2026 | Proxmox host → Docker VM for vcap.club |
| 48gb.caltek.net upgrade | Q4 2026 | Proxmox → isolate tenants (VCAP, 29Dines, EOYFT) |
| Community-hosted nodes | 2027 | Proxmox → multi-org bare-metal at partner sites |

**Proxmox install recommendation when ready:** Debian 12 ISO base → Proxmox VE 8.x → 
configure ZFS pool → LXC containers for lightweight services, KVM VMs for 
isolated tenant environments → Portainer agent in each container.

---

*Generated by CalTekNet CTN Architecture Session — June 14, 2026*
*Commit to: github.com/calteknet/osgeo17-vcap/docs/cms-architecture.md*
