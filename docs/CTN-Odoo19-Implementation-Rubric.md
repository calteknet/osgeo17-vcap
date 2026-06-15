# CTN Odoo 19 CE — Implementation Rubric
*Post-install sequence for every new CTN node*

---

## 1. Backup confirmed
`o19-local_2026-06-13_15-49-25.zip` — 77 files including `dump.sql` + filestore.
✓ Valid Odoo backup. Restore via: Settings → Backup/Restore → Restore.
Store a copy: `cp ~/Downloads/o19-local_*.zip /mnt/p4/backups/odoo/`

---

## 2. Apps to install (in order)

| # | App | Why |
|---|---|---|
| 1 | eLearning | courses, slides (done) |
| 2 | Surveys | intake forms, A-Z quiz (done) |
| 3 | Project | tasks, activities (done) |
| 4 | Contacts | res.partner pool — people + orgs |
| 5 | Events | Allensworth, workshops, FIFA pattern |
| 6 | Email Marketing | campaign templates |
| 7 | Invoicing | accounting core; required for T$ timebank currency |
| 8 | Discuss | internal channels + DM (local email alternative) |
| 9 | Employees | staff/volunteer roster tied to users |
| 10 | Recruitment | volunteer pipeline (the 397-record model) |

Install 4–6 now; 7–10 when a project specifically needs them.

---

## 3. User creation plan

### Step 1 — Second admin (do first, before anything else)
Settings → Users → New
- Name: `CTN Admin` · Login: `admin@caltek.net`
- Role: **Administrator** (Internal User + Administration/Settings)
- This account = the key operational admin; your personal account becomes the owner/fallback

### Step 2 — User types rubric

| Type | Odoo Group | Use case |
|---|---|---|
| Owner | Administrator + Technical | Kenneth — full access including debug |
| Admin | Administrator | Josh, Candy — operational management |
| Staff | Internal User | Charles, volunteers with task access |
| Portal | Portal | Clients, community members — see their own records only |
| Public | Public | Anonymous website/eLearning visitors |

### Step 3 — Bulk user import
CSV columns for `res.users` import:
```
id,name,login,groups_id/id,lang,tz
ctn.user_josh,Josh Santos,josh@santos.cloud,base.group_user,en_US,America/Los_Angeles
ctn.user_candy,Candy Tanamachi,candy@tutortronics.net,base.group_user,en_US,America/Los_Angeles
```
Import via: Settings → Users list view → ⚙ → Import records

---

## 4. Local domain + email system

### Local domain pattern for CTN nodes
```
caltek.local        (production-mirror nodes)
vcap.local          (classroom nodes)
stem54.local        (STEM54 node)
```
Set in `/etc/hosts` on each machine + in Odoo:
Settings → General Settings → Discuss → **Email Domain** = `caltek.local`

### Username assignment
- Format: `firstname.lastname@caltek.local` (staff) or `handle@caltek.local` (community)
- Set at user creation; becomes their Discuss channel identity automatically
- Import CSV sets the `login` field = their email address

### Local email options (no internet required)

| Option | Stack | Best for |
|---|---|---|
| Discuss only | built-in | internal channels, no SMTP needed |
| Postfix + Dovecot | TurnkeyLinux Mail Server ISO | full SMTP/IMAP on LAN |
| Mailpit | Docker container | dev/test — catches all outbound, no delivery |

For classroom/offline: **Discuss only** — zero config, works immediately.
For production caltek.net: Mailgun or SendGrid SMTP relay (already pattern from Elgg).

### Mailpit (dev email catcher) — add to o19-local stack:
```yaml
  mailpit:
    image: axllent/mailpit
    restart: unless-stopped
    ports:
      - target: 8025
        published: 8025
        protocol: tcp
        mode: host
    networks: [o19local]
```
Then Settings → Outgoing Mail → host `mailpit`, port `1025`, no auth.
Browse caught emails: http://localhost:8025

---

## 5. API Key — manual workaround (Odoo 19 UI gap)

Settings → Technical → **API Keys** (direct menu, dev mode required)
URL shortcut: `http://localhost:8069/odoo/action-73`
→ New → Description: `o19-local-api` → Generate → copy immediately
→ `echo "ODOO_API_KEY=thekey" >> ~/stacks/o19-local/.env`

---

## 6. LibreOffice / document access on OSGeoLive 17

```bash
sudo apt install -y libreoffice
```
Opens .docx, .xlsx, .pdf — including the 20 Bazetti aquaponics files in tilapia_pricing.zip.

Extract and open:
```bash
mkdir -p ~/Documents/aquaponics
cd ~/Documents/aquaponics
unzip ~/Downloads/tilapia_pricing.zip
libreoffice *.docx &
```

---

## 7. Replication targets — distro options

| Distro base | Method | Best for |
|---|---|---|
| OSGeoLive 17 (current) | Cubic remaster | VCAP classroom nodes — keeps all geo tools |
| TurnkeyLinux Core | tklpatch | Headless server nodes (48gb, shec.us pattern) |
| TurnkeyLinux LAMP | tklpatch | Nodes needing Apache + PHP (photobooth) |
| Makulu Linux | manual layer | Desktop-first community workstations |

**Common layer on all of them:**
```bash
# setup-once.sh (lives in repo root)
apt install -y docker.io git
docker swarm init --advertise-addr 127.0.0.1
git clone https://github.com/calteknet/osgeo17-vcap /opt/ctn
# then deploy stacks from /opt/ctn/infra/ via Portainer
```

---

## 8. Tilapia/aquaponics files (for Dr. Batie session)
20 documents in tilapia_pricing.zip covering:
- Aquaponics system specs + pricing (Nelson and Pade)
- CORE California aquaculture project proposal
- Tilapia market reports + fry pricing
- LED photosynthesis + grow light specs
- EXECUTIVE SUMMARY training docs
- Federal New Markets Tax Credit program

Next step: create Odoo Project task `ctn.tk_tilapia_review`, attach files as chatter attachments, assign to Dr. Batie meeting followup.
