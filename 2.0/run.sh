#!/bin/bash

# Print version
pg_dump --version

POSTGRES_DB=${POSTGRES_DB:-${POSTGRES_USER}}
POSTGRES_BACKUP_CMD=${POSTGRES_BACKUP_CMD:-"DUMP"}

[ -z "${POSTGRES_HOST}" ] && { echo "=> POSTGRES_HOST cannot be empty" && exit 1; }
[ -z "${POSTGRES_PORT}" ] && { echo "=> POSTGRES_PORT cannot be empty" && exit 1; }
[ -z "${POSTGRES_USER}" ] && { echo "=> POSTGRES_USER cannot be empty" && exit 1; }
[ -z "${POSTGRES_PASSWORD}" ] && { echo "=> POSTGRES_PASSWORD cannot be empty" && exit 1; }
[ -z "${POSTGRES_DB}" ] && { echo "=> POSTGRES_DB cannot be empty" && exit 1; }
[ ! "DUMP" = ${POSTGRES_BACKUP_CMD} -a ! "BASEBACKUP" = ${POSTGRES_BACKUP_CMD} ]


if [ ${POSTGRES_BACKUP_CMD} = "DUMP" ]
then
	BACKUP_CMD="pg_dump -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -U ${POSTGRES_USER} -f /backup/\${POSTGRES_DB}/\${BACKUP_NAME} ${BACKUP_EXTRA_OPTS} ${POSTGRES_DB}"
fi
if [ ${POSTGRES_BACKUP_CMD} = "BASEBACKUP" ]
then
	BACKUP_CMD="pg_basebackup --dbname postgresql://${POSTGRES_USER}@${POSTGRES_HOST}:${POSTGRES_PORT}?sslmode=require --pgdata=/backup/\${POSTGRES_DB}/\${BACKUP_NAME} -X stream --checkpoint=fast --format=tar --gzip ${BACKUP_EXTRA_OPTS}"
fi
[ -z "${BACKUP_CMD}" ] && { echo "=> POSTGRES_BACKUP_CMD cannot be '${POSTGRES_BACKUP_CMD}'. POSTGRES_BACKUP_CMD must be 'BASEBACKUP' or 'DUMP'" && exit 1;  }

export PGPASSWORD="${POSTGRES_PASSWORD}"

mkdir -p /backup/${POSTGRES_DB}

echo "=> Creating backup script"
rm -f /backup.sh
cat <<EOF > /backup.sh
#!/bin/bash
BACKUP_MAX=${BACKUP_MAX}
BACKUP_NAME=\${POSTGRES_DB}\$(date +\%Y.\%m.\%d.\%H\%M\%S).backup
export PGPASSWORD="${POSTGRES_PASSWORD}"
echo "=> Backup started: \${BACKUP_NAME} - ${BACKUP_CMD}"
if ${BACKUP_CMD} ;then
		echo "   Backup succeeded"
		mail -s "Backup notice" simon.nagl@e-mundo.de <<< 'Backup succeeded'
else
		echo "   Backup failed"
		rm -rf /backup/\${POSTGRES_DB}/\${BACKUP_NAME}
fi
if [ -n "\${BACKUP_MAX}" ]; then
		echo "=> Deleting old backups started"
		while [ \$(ls /backup/\${POSTGRES_DB} | wc -l) -gt \${BACKUP_MAX} ];
		do
				BACKUP_TO_BE_DELETED=\$(ls /backup/\${POSTGRES_DB} | sort | head -n 1)
				echo "   Delete \${BACKUP_TO_BE_DELETED}"
				rm -rf /backup/\${POSTGRES_DB}/\${BACKUP_TO_BE_DELETED}
		done
		echo "=> Deleting old backups done"
fi
echo "=> Backup done"
EOF
chmod +x /backup.sh

echo "=> Creating restore script"
rm -f /restore.sh
cat <<EOF > /restore.sh
#!/bin/bash
export PGPASSWORD="${POSTGRES_PASSWORD}"
echo "=> Restore database from \$1"
if psql -h${POSTGRES_HOST} -p${POSTGRES_PORT} -U${POSTGRES_USER} ${POSTGRES_DB}< \$1 ;then
		echo "   Restore succeeded"
else
		echo "   Restore failed"
fi
echo "=> Done"
EOF
chmod +x /restore.sh

touch /postgres_backup.log
tail -F /postgres_backup.log &

if [ -n "${BACKUP_ON_INIT}" ]; then
		echo "=> Create a backup on the startup"
		export POSTGRES_DB=${POSTGRES_DB}
		export BACKUP_MAX=${BACKUP_MAX}
		/backup.sh
fi

echo "${BACKUP_CRON_TIME} export BACKUP_MAX=${BACKUP_MAX}; export POSTGRES_DB=${POSTGRES_DB}; /backup.sh >> /postgres_backup.log 2>&1" > /crontab.conf
crontab  /crontab.conf
echo "=> Running cron job"
exec cron -f
