#!/bin/bash

GENERAL_DIR=/var/mariadb/backup/ #general directory of the backup tool
DAY_DIR=/var/mariadb/backup/`date +%Y-%m-%d`/ #directory where all backups done during a day are stored
TARGET_DIR=${DAY_DIR}`date +%T_inc`/ #directory of a single backup

source ./functions.sh #reference to functions.sh script

if [[ -e $TARGET_DIR ]] #checking if the target directory exists (-e flag means that the script will be terminated if an error appears)
then

	printf "Error: Directory ${TARGET_DIR} already exists\n"
	printf "[`date --iso-8601=ns`] Directory ${TARGET_DIR} already exists\n" >> "${TARGET_DIR}"my_error.log #saving an error message to my_error.log
else

	mkdir -p $DAY_DIR
	
	if [[ -e ${GENERAL_DIR}last_completed_backup ]] #checking if last_completed_backup file exists (-e flag means that the script will be terminated if an error appears)
	then
	
		BASE_DIR=$(head -n 1 ${GENERAL_DIR}last_completed_backup) #reading the first line of the last_completed_backup file in order to know the path to the previous backup
		FULL_DIR=$(head -n 1 ${GENERAL_DIR}last_completed_full_backup) #reading the first line of the last_completed_full_backup file in order to know the path to the previous full backup
		
		if [[ -z ${BASE_DIR} ]] #checking if lenght of the string is zero
		then
		
			printf "Error: Base dir is an empty string.\n"
			printf "[`date --iso-8601=ns --utc`] Base dir is an empty string\n" >> "${DAY_DIR}"my_error.log #saving an error message to my_error.log
		else
			
			extractFiles "${BASE_DIR}" #extracting backup files by using extractFiles function
			
			mkdir -p $TARGET_DIR #creating a directory for the backup
			
			SECONDS=0
			
			sudo mariabackup --backup --target-dir ${TARGET_DIR} --incremental-basedir ${BASE_DIR} -u mariabackup -p mypassword | gzip > ${TARGET_DIR}compressed_backup_files.gz
			2>>${TARGET_DIR}my_output.log; #creating a backup in TARGET_DIR and compressing it using gzip
			
			printf "[`date --iso-8601=ns`] Incremental backup performed successfully\n" >> "${TARGET_DIR}"my_output.log #saving a message to the my_output.log
			
			printf "completed in ${SECONDS} seconds\n" >> "${TARGET_DIR}"my_output.log #saving a message to the my_output.log
			printf $TARGET_DIR > "/var/mariadb/backup/"last_completed_backup #saving a directory to the backup that was just made to the last_completed_backup file
			printf $FULL_DIR > "${TARGET_DIR}"last_completed_full_backup_atm.log #saving a path to the latest full_backup existing when this incremental backup was made
			
		fi
	else
	
		printf "Error: No base dir for incremental backup\n"
		printf "[`date --iso-8601=ns --utc`] No base dir for incremental backup\n" >> "${DAY_DIR}"my_error.log #saving an error message in my_error.log
	fi
fi
