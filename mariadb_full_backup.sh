#!/bin/bash

DAY_DIR=/var/mariadb/backup/`date +%Y-%m-%d`/ #directory where all backups done during a day are stored
TARGET_DIR=${DAY_DIR}`date +%T_full`/ #directory of a single backup

if [[ -e $TARGET_DIR ]] #checking if the target directory exists (-e flag means that the script will be terminated if an error appears)
then

	printf "[`date --iso-8601=ns`] Directory ${TARGET_DIR} already exists\n" >> "${TARGET_DIR}"my_error.log #saving an error message to my_error.log
else

	mkdir -p "$TARGET_DIR" #creating a directory for the backup
	
	SECONDS=0
	
	sudo mariabackup --backup --target-dir ${TARGET_DIR}  -u mariabackup -p mypassword --stream=xbstream | gzip > ${TARGET_DIR}compressed_backup_files.gz #creating a backup in TARGET_DIR and compressing it using gzip
	2>>${TARGET_DIR}my_output.log
	printf "[`date --iso-8601=ns`] Full backup performed successfully\n" >> "${TARGET_DIR}"my_output.log #saving a message into my_output.log file
	
	printf "completed in ${SECONDS} seconds\n\n" >> "${TARGET_DIR}"my_output.log #saving a message into my_output.log file
	printf $TARGET_DIR > "/var/mariadb/backup/"last_completed_backup #saving directory of the last completed backup in order to be able to create incremental backups referring to the previous backup
	printf $TARGET_DIR > "/var/mariadb/backup/"last_completed_full_backup #saving directory of the last completed FULL backup in order to be able to prepare an incremental backup referring to the latest full backup
fi
