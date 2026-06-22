#!/bin/bash
# CTN First Boot Setup — runs once, then disables itself
# Place stacks in ~/stacks/ before running

echo "=== CTN First Boot Setup ==="

read -sp "Set Odoo DB password: " ODOO_PASS; echo
read -sp "Confirm password: " ODOO_PASS2; echo
if [ "$ODOO_PASS" != "$ODOO_PASS2" ]; then
  echo "Mismatch — rerun."; exit 1
fi

# Update .env files
for f in ~/osgeo17-vcap/infra/o19-local/.env ~/osgeo17-vcap/stacks/ctn-local/.env; do
  [ -f "$f" ] && sed -i "s/changeme_odoo/$ODOO_PASS/" "$f" && echo "Updated $f"
done

echo "Passwords set. Deploying stacks..."
# TODO: add docker stack deploy commands here

# Disable self if running as systemd service
systemctl is-active ctn-firstboot.service &>/dev/null && \
  sudo systemctl disable ctn-firstboot.service

echo "Done. Browse to http://localhost:8069"
