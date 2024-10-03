#!/bin/bash

# MySQL database credentials
DB_USER="shopizer"
DB_PASS="shopizer"
DB_NAME="mystore"

# Directory to store backups temporarily
BACKUP_DIR="/tmp/mysql_backups"
mkdir -p $BACKUP_DIR

# Timestamp for backup filename
TIMESTAMP=$(date +"%Y%m%d%H%M%S")

# S3 bucket name
S3_BUCKET="mystore-dbbackup"

# Dump MySQL database
BACKUP_FILE="$BACKUP_DIR/$DB_NAME-$TIMESTAMP.sql"
mysqldump -u $DB_USER -p $DB_PASS $DB_NAME > $BACKUP_FILE

# Upload to S3
aws s3 cp $BACKUP_FILE s3://$S3_BUCKET/

# Optional: Remove the local backup file after upload
rm $BACKUP_FILE