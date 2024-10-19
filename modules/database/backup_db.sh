#!/bin/bash

# MySQL database credentials
DB_USER="shopizer"
DB_PASS="shopizer"

# Directory to store backups temporarily
BACKUP_DIR="/tmp/mysql_backups"
mkdir -p $BACKUP_DIR

# Timestamp for backup filename
TIMESTAMP=$(date +"%Y%m%d")

# S3 bucket name
S3_BUCKET="shopizer-database-backup-bucket"

# Dump MySQL database
BACKUP_FILE="$BACKUP_DIR/shopizer-backup-$TIMESTAMP.sql"
mysqldump -u $DB_USER -p $DB_PASS --all-databases > $BACKUP_FILE

# Upload to S3
aws s3 cp $BACKUP_FILE s3://$S3_BUCKET/

rm $BACKUP_FILE