# elgg-local seed data
Fresh-install snapshot (Elgg 6.3.5, verified styled at idea.localhost:8086)
Location: /opt/ctn/backups/elgg-fresh-20260705/ (also bank to Seagate)
Contents: elgg_mariadb (2.4M), elgg_data (380K), elgg_static (89B, legitimately
empty — Elgg 6 serves assets via PHP), elgg_db_backup (2.3M), elgg_backup (4.5M)
Purpose: seed volumes for elgg persona firstboot in ctn-apps.iso (TKL base)
Restore: tar xzf into named volumes before first stack deploy
