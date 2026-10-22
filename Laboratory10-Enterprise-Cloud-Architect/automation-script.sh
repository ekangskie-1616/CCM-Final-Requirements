#!/bin/bash
# Daily MySQL backup, 7-day retention
BACKUP_DIR="$HOME/backups"
DB_CONTAINER=$(docker ps -qf name=db)
STAMP=$(date +%F_%H%M)
mkdir -p "$BACKUP_DIR"
 
docker exec "$DB_CONTAINER" mysqldump -u root \
  -p'<root-password>' wordpress \
  > "$BACKUP_DIR/wp_$STAMP.sql"
 
find "$BACKUP_DIR" -name "*.sql" -mtime +7 -delete
echo "[$(date)] Backup done" >> "$BACKUP_DIR/backup.log"

chmod +x automation-script.sh
crontab -e
0 2 * * * /home/<user>/automation-script.sh
