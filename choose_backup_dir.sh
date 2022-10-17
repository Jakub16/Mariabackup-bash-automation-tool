#/bin/bash

printf "Select date of the backup that you want to restore:\n"
select dir in /var/mariadb/backup/*/; do test -n "$dir" && break; echo "Invalid directory"; done #reading the answer from user (from which day do they want to restore backup) and assigning it to the $dir variable
printf "Select a backup that you want to restore:\n"
cd "$dir"
select backup_dir in */; do test -n "$backup_dir" && break; echo "Invalid directory"; done #reading the answer from user (exactly which backup do they want to restore) and assigning it to the $backup_dir variable 

if [[ "$backup_dir" == *full/ ]] #checking if the chosen backup is a full backup
then

	validation=1 
	type=full	
elif [[ "$backup_dir" == *inc/ ]] #checking if the chosen backup is an incremental backup
then

	validation=1
	type=inc
else

	validation=0
fi
