# CTN One-Time Setup Reference
CalTekNet · OSGeoLive 17 · github.com/calteknet/osgeo17-vcap

These steps happen once per physical machine. NOT run by vcap_boot.sh.

## 1 · SSH Key
    ssh-keygen -t ed25519 -C "kmw@caltek.net" -f ~/.ssh/id_ed25519 -N ""
    cat ~/.ssh/id_ed25519.pub
Add to github.com/settings/ssh · Label: {machine}-osgeo17-{year}
Save to: /mnt/p4/home/kmw/.ssh/

## 2 · Cloudflare Certificate
    cloudflared tunnel login
Cert saved: ~/.cloudflared/cert.pem
Backup: cp ~/.cloudflared/cert.pem /mnt/p4/home/kmw/cloudflared_config/

## 3 · Tunnel Creation (once ever)
    cloudflared tunnel create exe-caltek
    cloudflared tunnel route dns --overwrite-dns exe-caltek exe.caltek.net
Tunnel ID: e7fbc420-297a-4fa6-922f-c8e2e0239cee
Credentials backup: /mnt/p4/home/kmw/cloudflared_config/

## 4 · Portainer Admin Password
Set on first boot at http://localhost:9000
Store in password manager: Entry=CTN Portainer Admin · User=admin
Reset if forgotten:
    docker stop portainer
    docker run --rm -v /mnt/p4/docker-data/portainer:/data portainer/portainer-ce:latest --reset-password
    docker start portainer

## 5 · GitHub Remote
    cd /mnt/p4/home/kmw/osgeo17-vcap
    git config user.name "Kenneth Wyrick"
    git config user.email "kmw@caltek.net"
    git remote set-url origin git@github.com:calteknet/osgeo17-vcap.git
    ssh -T git@github.com

## New Machine Checklist
- [ ] Boot OSGeoLive 17
- [ ] sudo mount /dev/nvme0n1p4 /mnt/p4
- [ ] Generate SSH key + add to GitHub
- [ ] cloudflared tunnel login
- [ ] cp -r /mnt/p4/home/kmw/cloudflared_config ~/.cloudflared
- [ ] bash /mnt/p4/home/kmw/vcap/vcap_boot.sh
- [ ] Set Portainer password on first access
- [ ] git remote set-url origin git@github.com:calteknet/osgeo17-vcap.git
