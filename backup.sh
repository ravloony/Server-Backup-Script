#!/bin/bash

# Titel: Backup-Script 
# Description: Sicherung von /srv, /etc, /var/log und MYSQL-Datenbanken anlegen und automatisch auf einen festgelegten FTP-Server hochladen. 
# Copyright: Christian Beier (http://www.beier-christian.eu/) 
# Version 1.1

# Modified by Tom Macdonald (www.thomas-macdonald.com)
# Version 1.2

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

# ENDE DER EINSTELLUNGEN

echo "Starting backup run on $DATE"

# Backup-Verzeichnis anlegen 
TMPDIR=`mktemp -d /tmp/backup.XXXX`

echo "In directory $TMPDIR"

cd $TMPDIR

echo "Collecting databases"

# Sicherung der Datenbanken
for database in $MYSQL_DATABASES
do
	echo "Dumping $database"
	mysqldump -u$MYSQL_USER -p$MYSQL_PASS $database | bzip2 > $database-$DATE.sql.bz2
	echo "Done"
done

echo "Collecting files"

for directory in $DIRECTORIES
do
	echo "copying $directory to $TMPDIR"
	cp -r $directory $TMPDIR
	dirname=`basename $directory`
	echo "Compressing $dirname"
	tar cjfp $dirname-$DATE.tar.bz2 $TMPDIR/$dirname
	echo "Done"
done

echo "Starting ftp upload"

# Alle komprimierten Dateien per FTP auf den Backup-Server laden
ftp -ni << END_UPLOAD
  open $FTP_SERVER
  user $FTP_USER $FTP_PASS
  bin
  mput *.bz2
  quit
END_UPLOAD

echo "Removing $TMPDIR"
# Anschliessend alle auf den Server angelegten Dateien wieder loeschen
rm -r -f $TMPDIR

echo "finished"
