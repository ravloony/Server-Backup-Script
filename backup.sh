#!/bin/bash

# Titel: Backup-Script 
# Description: Sicherung von /srv, /etc, /var/log und MYSQL-Datenbanken anlegen und automatisch auf einen festgelegten FTP-Server hochladen. 
# Copyright: Christian Beier (http://www.beier-christian.eu/) 
# Version 1.1

# Modified by Tom Macdonald (www.thomas-macdonald.com)
# Version 1.2

# Repurposed to use git and dual ftp files
# Version 2.0

# Allgemeine Angaben
MYSQL_USER=Benutzername_fuer_MySQL_meistens_root
MYSQL_PASS=Passwort_fuer_MySQL
MYSQL_DATABASES="database1 database2"

FTP_SERVER=Adresse_des_FTP-Servers_auf_dem_gesichert_werden_soll # Bsp. Strato: backup.serverkompetenz.de
FTP_USER=Benutzername
FTP_PASS=Passwort

DIRECTORIES="/var/www/website /etc /var/log"

# Festlegung des Datums - Format: 20050710
DATE=`date +"%Y%m%d"`

GIT_DIR="/root/backup"
BACKUP_FILE_NAME=file_name
TMP_DIR=`mktemp -d /tmp/backup.XXXX`

# ENDE DER EINSTELLUNGEN

echo "Starting backup run on $DATE"

cd $GIT_DIR

echo "In directory $GIT_DIR"

echo "Collecting databases"

# Sicherung der Datenbanken
for database in $MYSQL_DATABASES
do
	echo "Dumping $database"
	mysqldump -u$MYSQL_USER -p$MYSQL_PASS $database > $database.sql
	echo "Done"
done

echo "Collecting files"

for directory in $DIRECTORIES
do
	echo "copying $directory to $GIT_DIR"
	cp -r $directory $GIT_DIR
	echo "Done"
done

echo "Adding files to git"

git add .

echo "Committing backup point"

git commit -m "`date`"

cd $TMP_DIR

echo "Compressing git directory"

tar -cjpf $BACKUP_FILE_NAME.tar.bz2 $GIT_DIR

echo "Starting ftp upload"

# Alle komprimierten Dateien per FTP auf den Backup-Server laden
ftp -ni << END_UPLOAD
  open $FTP_SERVER
  user $FTP_USER $FTP_PASS
  bin
  delete $BACKUP_FILE_NAME-past.tar.bz2
  rename $BACKUP_FILE_NAME.tar.bz2 $BACKUP_FILE_NAME-past.tar.bz2
  send $BACKUP_FILE_NAME.tar.bz2
  quit
END_UPLOAD

cd

echo "Removing $TMP_DIR"
# Anschliessend alle auf den Server angelegten Dateien wieder loeschen
rm -r -f $TMP_DIR

echo "Finished"
