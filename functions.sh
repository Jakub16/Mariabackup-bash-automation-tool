#/bin/bash

copyBack() { #a function which restores the backup (created in order to avoid duplicating the code)

	copy_back_dir=$1

	sudo systemctl stop mariadb.service #stopping the mariadb service
	sudo rm -rf /var/lib/mysql/* #removing all mysql files in order to replace them with backup files
	sudo mariabackup --copy-back --target-dir="$copy_back_dir" #restoring the backup
	sudo chown -R mysql. /var/lib/mysql #restoring necessary permissions to mysql files
	sudo systemctl start mariadb.service #starting mariadb service
}

prepareFullBackup() { #a function which prepares full backup (created in order to avoid duplicating the code)
	
	prepare_dir=$1 #reading first argument passed by the user
	
	sudo mariabackup --prepare --target-dir "$prepare_dir" -u mariabackup -p mypassword >> "$prepare_dir"my_output.log #preparing a backup
	2>>"$dir$backup_dir"my_error.log
	printf "[`date --iso-8601=ns`] Full backup prepared successfully\n\n" >> "$prepare_dir"my_output.log #saving a message into my_output.log file
	2>>"$prepare_dir"my_error.log
}

extractFiles() { #a function which extracts compressed files (by using gzip tool)
	
	extract_dir=$1 #reading first argument passed by the user
	echo "$extract_dir"
	cd "$extract_dir" #moving to the directory (of files to be extracted) chosen by user
	
	if [[ -e compressed_backup_files.gz ]] #checking if compressed backup files exists in the chosen directory
	then
	
		sudo gunzip -c compressed_backup_files.gz | mbstream -x #decompressing backup directory in order to prepare it
		sudo rm compressed_backup_files.gz #removing compressed backup files after the extraction
	else
	
		printf "Warning: Backup files are not compressed, compressed_backup_files.gz file doesn't exist."
		printf "[`date --iso-8601=ns --utc`] Warning: Backup files are not compressed, compressed_backup_files.gz file doesn't exist.\n" >> "$extract_dir"my_error.log  #saving a message to my_error.log
	fi
}

