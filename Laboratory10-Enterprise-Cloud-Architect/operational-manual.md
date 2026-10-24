OPERATIONAL MANUAL
CCM101 – Cloud Computing | Enterprise Cloud Architect

Project: Secure Multi-Tier Web Application

Application Stack: WordPress + MySQL

Prepared by: Solomon, Crizaldy; Suguitan, Charlo; Tabion, Maria Louisa S.; Tabayoyong, Erica V.

Section: BSIT-4I

Instructor: Jenkielyn C. Torres

Date: October 19, 2026
1. Overview
This project deploys a WordPress website and MySQL database using Docker containers on an Ubuntu Server virtual machine. Docker Compose manages both containers, while Docker volumes preserve website files and database information.

System architecture:

Host Laptop → VirtualBox → Ubuntu Server VM → UFW Firewall → Docker (WordPress + MySQL)
2. Virtual Machine Setup
1. Open VirtualBox and create a virtual machine.
2. Allocate 2 CPUs, 2 GB RAM, and a 20 GB virtual disk.
3. Install Ubuntu Server and enable OpenSSH.
4. Configure networking using Bridged Adapter or NAT with port forwarding.
5. Start Ubuntu Server and confirm that the host computer can access the VM.
3. Docker Deployment
3.1 Install Docker
Open the Ubuntu terminal and execute:
</Bash>
sudo apt update
sudo apt install -y docker.io docker-compose-v2
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"


Log out and log back in after adding your user to the Docker group.
3.2 Create the Docker Compose file
Create a project directory and open the configuration file:
</Bash>
mkdir -p ~/wordpress-project
cd ~/wordpress-project
nano compose.yaml


Enter the following configuration. Replace the password placeholders with your actual passwords, using the same database credentials in both services.

</YAML>
services:
  db:
    image: mysql:8.0
    restart: always
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wpuser
      MYSQL_PASSWORD: "CHANGE_DB_PASSWORD"
      MYSQL_ROOT_PASSWORD: "CHANGE_ROOT_PASSWORD"
    volumes:
      - db_data:/var/lib/mysql

  wordpress:
    image: wordpress:latest
    restart: always
    depends_on:
      - db
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wpuser
      WORDPRESS_DB_PASSWORD: "CHANGE_DB_PASSWORD"
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - wp_data:/var/www/html

volumes:
  db_data:
  wp_data:



Save the file in Nano using Ctrl + O, press Enter, then Ctrl + X.
3.3 Start the application
Run these commands inside the project directory:
docker compose config
docker compose up -d
docker compose ps


Open a browser and visit http://VM-IP-ADDRESS, replacing the placeholder with your Ubuntu VM's IP address. Complete the WordPress installation screen.

Check that both the WordPress and MySQL containers are running before proceeding.
4. Persistence Test
This test verifies that website data remains available after restarting the virtual machine.
1. Open the WordPress website.
2. Create a test post with a title such as Persistence Test.
3. Publish the post and confirm that it appears on the website.
4. Return to the Ubuntu terminal and execute:
</Bash>
sudo reboot


6. Wait for Ubuntu Server to restart.
7. Open the website again and check whether the test post still exists.
Expected result: The test post remains available after reboot because WordPress and MySQL use persistent Docker volumes.
5. Security Configuration
Configure the Ubuntu firewall to allow only the required incoming connections.
</Bash>
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw enable
sudo ufw status verbose


- Port 22: Allows SSH administration.
- Port 80: Allows HTTP access to WordPress.
- MySQL: Remains accessible through the internal Docker network rather than being published directly to the host.
Expected result: The firewall allows the configured SSH and HTTP traffic while blocking other incoming connections by default.
6. Backup Automation
6.1 Create the backup script
Create a backup directory and script:
</Bash>
mkdir -p ~/backups
nano ~/automation-script.sh


Enter the following script:

</Bash>
#!/bin/bash

# Daily MySQL backup with 7-day retention
BACKUP_DIR="$HOME/backups"
DB_CONTAINER=$(docker ps -qf name=db)
STAMP=$(date +%F_%H%M)

mkdir -p "$BACKUP_DIR"

if [ -z "$DB_CONTAINER" ]; then
    echo "[$(date)] ERROR: Database container not running" \
      >> "$BACKUP_DIR/backup.log"
    exit 1
fi

if docker exec "$DB_CONTAINER" \
    mysqldump -u root -p'CHANGE_ROOT_PASSWORD' wordpress \
    > "$BACKUP_DIR/wp_$STAMP.sql"; then
    echo "[$(date)] Backup done" >> "$BACKUP_DIR/backup.log"
else
    echo "[$(date)] ERROR: Backup failed" >> "$BACKUP_DIR/backup.log"
    rm -f "$BACKUP_DIR/wp_$STAMP.sql"
    exit 1
fi

find "$BACKUP_DIR" -name "*.sql" -mtime +7 -delete



Replace CHANGE_ROOT_PASSWORD with the same MySQL root password configured in compose.yaml.

Save the file, then make it executable:
</Bash>
chmod +x ~/automation-script.sh


6.2 Test the backup script
Run:
</Bash>
~/automation-script.sh


Verify that the backup was created:
</Bash>
ls -lh ~/backups
cat ~/backups/backup.log


Expected result: A dated .sql file appears in the backup directory, and the log records whether the backup succeeded.

The script deletes SQL backups older than seven days. Note that this is a local backup; copying backups to another machine or storage location is recommended for better disaster recovery.
6.3 Schedule automatic backups using Cron
Open the cron editor:
</Bash>
crontab -e


Add this line at the bottom:
0 2 * * * /home/YOUR_USERNAME/automation-script.sh


Replace YOUR_USERNAME with your actual Ubuntu username. Save and exit.

Verify the schedule:
</Bash>
crontab -l


Check the backup log after the scheduled run:
</Bash>
cat ~/backups/backup.log


Expected result: The script is scheduled to run daily at 2:00 AM according to the VM's system time. Check the configured timezone because the VM may use UTC.
7. Restore and Disaster Recovery
This procedure restores a MySQL database from a backup file.
7.1 Identify the backup
</Bash>
ls -lh ~/backups


Choose the SQL backup file you want to restore.
7.2 Restore the database
Replace YOUR_BACKUP_FILE.sql with the actual backup filename.
</Bash>
docker exec -i "$(docker ps -qf name=db)" \
  mysql -u root -p'CHANGE_ROOT_PASSWORD' wordpress \
  < ~/backups/YOUR_BACKUP_FILE.sql


Use the correct root password. Restoring a backup may overwrite existing records or introduce older data, so perform this procedure carefully.
7.3 Verify the restoration
1. Open the WordPress website.
2. Check whether the restored posts and other expected records are present.
3. If possible, conduct the test in a separate test environment to avoid damaging the live data.
4. Record the result and capture screenshots as evidence.
Expected result: The database records contained in the selected backup are restored successfully.

For the final requirements, do not rely on the restore command alone. Actually perform a restore test and capture evidence showing that the restored data is accessible.
8. Maintenance and Troubleshooting
8.1 Common maintenance commands
Task	Command
View container status	docker compose ps
View application logs	docker compose logs -f
Restart containers	docker compose restart
Download updated images	docker compose pull
Apply updated images	docker compose up -d
Stop and remove containers	docker compose down

Important: docker compose down does not normally remove named volumes. Avoid adding -v unless you intentionally want to delete the associated persistent data.
8.2 Troubleshooting
Problem	Recommended solution
Website unreachable	Check the VM IP, firewall, port 80, and container status.
Database connection error	Check that database credentials match and wait for MySQL to initialize.
YAML configuration error	Check indentation and run docker compose config.
Backup script fails	Check the database container, password, permissions, and backup log.
Cron does not run	Check crontab -l, use the full script path, and inspect the log.
Restore fails	Check the backup filename, database container, password, and SQL file contents.

9. Final Reflection
Throughout this project, the team learned how to deploy a multi-tier web application using Ubuntu Server, Docker, Docker Compose, WordPress, and MySQL. The project demonstrated how persistent Docker volumes preserve website data after a virtual machine reboot.

The team also encountered challenges involving SSH connectivity, YAML indentation, firewall configuration, and scheduled backups. These experiences improved the team's troubleshooting, system administration, and teamwork skills.

Future improvements include enabling HTTPS, improving password security, storing backups off-site, and deploying the application on a public cloud platform such as AWS.
10. References
- Docker Documentation — https://docs.docker.com/
- Ubuntu Server Documentation — https://ubuntu.com/server/docs
- WordPress Official Docker Image — https://hub.docker.com/_/wordpress
