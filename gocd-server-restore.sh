#!/bin/bash
# to execute the restore place this script in the same directory as the files to restore. 


GO_HOME=/var/lib/go-server/

echo '------------------------------------------------------------------'
echo 'GoCD Restore'
echo '------------------------------------------------------------------'

if systemctl is-active --quiet go-server.service >/dev/null 2>&1 ; then
    echo "alert: GoCD service is running, stop it before starting the restoration"
    exit 1
fi

if ! command -v unzip >/dev/null 2>&1 ; then
    echo "alert: unzip not found, install unzip package"
    exit 1
fi

# TODO: check version! version del backup debe ser menor a la del servidor

if [[ -e db.zip ]] && [[ -e config-dir.zip ]] && [[ -e config-repo.zip ]]; then

	unzip db.zip
	unzip config-dir.zip -d go
	unzip config-repo.zip -d config.git

	if [[ -e cruise.h2.db ]] && [ "$(ls -A go)" ] && [ "$(ls -A config.git)" ]; then
				
		if [[ -e $GO_HOME/db/h2db/cruise.h2.db ]] && [[ -d /etc/go ]]; then

			mkdir localBackup

			# restore db.zip
			echo "+ file: db.zip"
			mv $GO_HOME/db/h2db/cruise.h2.db localBackup/
			echo "   backed: localBackup/cruise.h2.db"
			mv cruise.h2.db $GO_HOME/db/h2db/
			chown go:go $GO_HOME/db/h2db/cruise.h2.db
			echo "   restored: ${GO_HOME}/db/h2db/cruise.h2.db"

			# restore config-dir.zip
			echo "+ file: config-dir.zip"
			mv /etc/go localBackup/
			echo "   backed: localBackup/go"
			mv go /etc/
			chown -R go:go /etc/go
			echo "   restored: /etc/go"

			# restore config-repo.zip
			echo "+ file: db.zip"
			if [[ -d $GO_HOME/db/config.git ]]; then
				mv $GO_HOME/db/config.git localBackup/
				echo "   backed: localBackup/config.git"
			else 
				echo "   info: diretory ${GO_HOME}/db/config.git does not exist"
			fi
			mv config.git $GO_HOME/db/
			chown -R go:go $GO_HOME/db/config.git
			echo "   restored: ${GO_HOME}/db/config.git"

		else
			echo "error: missing local files to restore [${GO_HOME}/db/h2db/cruise.h2.db, /etc/go]"
			exit 1
		fi
	else
		echo "error: incomplete unzipped files [cruise.h2.db, go/, config.git/]"
		exit 1
	fi
else
	echo "error: missing files to restore [db.zip, config-dir.zip, config-repo.zip]"
fi
