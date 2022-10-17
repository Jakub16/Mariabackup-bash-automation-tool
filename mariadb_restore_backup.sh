#!/bin/bash

source ./functions.sh #reference to functions.sh script
source /var/mariadb/backup/choose_backup_dir.sh #reference to choose_backup_dir.sh script

GENERAL_DIR=/var/mariadb/backup/ #general directory of the backup tool

if [[ "$validation" == 1 ]] #checking if a backup chosen by user is valid
then

	if [[ -e ${GENERAL_DIR}last_completed_full_backup ]] # checking if last_completed_full_backup file exists
	then
	
		FULL_DIR=$(head -n 1 ${GENERAL_DIR}last_completed_full_backup) #reading the first line of the last_completed_full_backup file in order to know the path to the previous full backup
		
		printf "Do you want to remove all content from /var/lib/mysql/ and restore the chosen backup? Type [Y/N]" #asking user if they want to proceed
		read decision
	
		if [[ "$decision" == Y || "$decision" == y ]] #checking if user wants to proceed the restore process
		then
		
			if [[ "$type" == full ]] #checking if the chosen backup is a full backup
			then
				
				extractFiles "$dir$backup_dir" #exececuting extractFiles function
				
				BACKUP_TYPE_STATUS=$(sudo head -n 1 "$dir$backup_dir"xtrabackup_checkpoints) #reading the first line of the xtrabackup_checkpoints document (information about the type of the backup), which is a file created by mariabackup that specifies characteristics of the backup
			
				if [[ ${BACKUP_TYPE_STATUS} == 'backup_type = log-applied' ]] #checking if the backup is already prepared 
				then
				
					copyBack "$dir$backup_dir" #exececuting copyBack function
				
					printf "[`date --iso-8601=ns --utc`] Full backup: $dir$backup_dir restored successfully.\n" >> "$dir$backup_dir"my_output.log #saving a message to my_output.log file
					2>>"$dir$backup_dir"my_error.log
				elif [[ ${BACKUP_TYPE_STATUS} == 'backup_type = full-backuped' ]] #checking if the backup is not prepared
				then
					
					prepareFullBackup "$dir$backup_dir" #exececuting prepareFullBackup function
					copyBack "$dir$backup_dir" #exececuting copyBack function
					
				else
				
					printf "Error: Uknown type of backup"
					printf "[`date --iso-8601=ns --utc`] $dir$backup_dir : Uknown type of backup.\n" >> "$dir$backup_dir"my_error.log #saving an error message to my_error.log
				fi	
				
			elif [[ "$type" == inc ]] #checking if the chosen backup is an incremental backup
			then
				
				extractFiles "$dir$backup_dir"
			
				if [[ -e "$dir$backup_dir"last_completed_full_backup_atm.log ]] #checking if last_completed_full_backup_atm.log file exists
				then
					
					FULL_DIR_ATM=$(head -n 1 "$dir$backup_dir"last_completed_full_backup_atm.log) #reading the first line of the last_completed_full_backup_atm.log file in order to know which full backup should we reffer to when preparing the incremental backup
					
					extractFiles "${FULL_DIR_ATM}" #exececuting extractFiles function
					
					BACKUP_TYPE_STATUS=$(sudo head -n 1 ${FULL_DIR_ATM}xtrabackup_checkpoints) #reading the first line of the xtrabackup_checkpoints document of a full backup created before the chosen incremental backup
					
					if [[ ${BACKUP_TYPE_STATUS} == 'backup_type = log-applied' ]] #checking if the full backup is already prepared
					then
					
						sudo mariabackup --prepare --target-dir ${FULL_DIR_ATM} --incremental-dir "$dir$backup_dir" -u mariabackup -p mypassword >> "$dir$backup_dir"my_output.log #preparing the incremental backup based on FULL_DIR_ATM
						2>>"$dir$backup_dir"my_error.log
					
						printf "[`date --iso-8601=ns`] Incremental backup prepared successfully\n\n" >> "$dir$backup_dir"my_output.log #saving a message to my_output.log file
				
						copyBack "${FULL_DIR_ATM}" #exececuting copyBack function
					
						printf "[`date --iso-8601=ns --utc`] Incremental backup: $dir$backup_dir restored successfully.\n" >> "$dir$backup_dir"my_output.log #saving a message to my_output.log file
						2>>"$dir$backup_dir"my_error.log
					elif [[ ${BACKUP_TYPE_STATUS} == 'backup_type = full-backuped' ]] #checking if the backup is not prepared
					then
					
						prepareFullBackup "${FULL_DIR_ATM}" #exececuting prepareFullBackup function
						
						sudo mariabackup --prepare --target-dir ${FULL_DIR_ATM} --incremental-dir "$dir$backup_dir" -u mariabackup -p mypassword >> "$dir$backup_dir"my_output.log #preparing the incremental backup based on FULL_DIR_ATM
						2>>"$dir$backup_dir"my_error.log
					
						printf "[`date --iso-8601=ns`] Incremental backup prepared successfully\n\n" >> "$dir$backup_dir"my_output.log #saving a message to my_output.log file
						
						copyBack "${FULL_DIR_ATM}" #exececuting copyBack function
					else
					
						printf "Error: Uknown type of backup\n"
						printf "[`date --iso-8601=ns --utc`] ${FULL_DIR_ATM} :  Uknown type of backup.\n" "$dir$backup_dir"my_error.log #saving an error message to my_error.log file
					fi
					
				else
				
					printf "[`date --iso-8601=ns --utc`] Error: Cannot find path to the full backup completed before this incremental backup.\n" >> "$dir$backup_dir"my_error.log  #saving a message to my_error.log
					printf "Error: Cannot find path to the full backup completed before this incremental backup\n"
				fi
			fi
		fi
	else
	
		printf "Error: Cannot find path to the last completed full backup.\n"
		printf "[`date --iso-8601=ns --utc`] Cannot find path to the last completed full backup\n" >> "$dir$backup_dir"my_error.log #saving a message to my_error.log file
	fi
else

	printf "Error: Backup directory is not valid.\n"
	printf "[`date --iso-8601=ns --utc`] Error: Backup directory is not valid.\n" >> "$dir$backup_dir"my_error.log #saving a message to my_error.log
fi
