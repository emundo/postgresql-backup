#!/bin/bash
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

if [ "${POSTGRES_ENV_POSTGRES_PASSWORD}" == "**Random**" ]; then
				unset POSTGRES_ENV_POSTGRES_PASSWORD
fi

POSTGRES_HOST=${POSTGRES_PORT_5432_TCP_ADDR:-${POSTGRES_HOST}}
POSTGRES_HOST=${POSTGRES_PORT_1_5432_TCP_ADDR:-${POSTGRES_HOST}}
POSTGRES_PORT=${POSTGRES_PORT_5432_TCP_PORT:-${POSTGRES_PORT}}
POSTGRES_PORT=${POSTGRES_PORT_1_3306_TCP_PORT:-${POSTGRES_PORT}}
POSTGRES_USER=${POSTGRES_USER:-${POSTGRES_ENV_POSTGRES_USER}}

file_env 'POSTGRES_PASSWORD'
if [ "$POSTGRES_PASSWORD" ]; then
	echo >&1 "...POSTGRES_PASSWORD was successfully set."
else
	# The - option suppresses leading tabs but *not* spaces. :)
		cat >&2 <<-'EOWARN'
				****************************************************
				WARNING: No password has been set for the database.
				This will very likely result in JIRA not starting up
				correctly. Please provide a password.

				Use "-e POSTGRES_PASSWORD=password" to set
				it in "docker run".

				Note: You can also use docker secrets with the 
				"_FILE" ending. Use 
				"-e POSTGRES_PASSWORD_FILE=/run/secrets/mysecret" to 
				set it in "docker run" 
				****************************************************
		EOWARN
fi

POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-${POSTGRES_ENV_POSTGRES_PASSWORD}}

[ -z "${POSTGRES_HOST}" ] && { echo "=> POSTGRES_HOST cannot be empty" && exit 1; }
[ -z "${POSTGRES_PORT}" ] && { echo "=> POSTGRES_PORT cannot be empty" && exit 1; }
[ -z "${POSTGRES_USER}" ] && { echo "=> POSTGRES_USER cannot be empty" && exit 1; }
[ -z "${POSTGRES_PASSWORD}" ] && { echo "=> POSTGRES_PASSWORD cannot be empty" && exit 1; }
[ -z "${POSTGRES_DB}" ] && { echo "=> POSTGRES_DB cannot be empty" && exit 1; }

export PGPASSWORD="${POSTGRES_PASSWORD}"

BACKUP_CMD="pg_dump -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -U ${POSTGRES_USER} -f /backup/\${POSTGRES_DB}/\${BACKUP_NAME} ${EXTRA_OPTS} ${POSTGRES_DB}"

mkdir /backup/${POSTGRES_DB}

echo "=> Creating backup script"
rm -f /backup.sh
cat <<EOF >> /backup.sh
#!/bin/bash

MAX_BACKUPS=${MAX_BACKUPS}

BACKUP_NAME=\${POSTGRES_DB}\$(date +\%Y.\%m.\%d.\%H\%M\%S).sql

export PGPASSWORD="${POSTGRES_PASSWORD}"

echo "=> Backup started: \${BACKUP_NAME}"
if ${BACKUP_CMD} ;then
		echo "   Backup succeeded"
else
		echo "   Backup failed"
		rm -rf /backup/\${POSTGRES_DB}/\${BACKUP_NAME}
fi

if [ -n "\${MAX_BACKUPS}" ]; then
		while [ \$(ls /backup/\${POSTGRES_DB} -N1 | wc -l) -gt \${MAX_BACKUPS} ];
		do
				BACKUP_TO_BE_DELETED=\$(ls /backup/\${POSTGRES_DB} -N1 | sort | head -n 1)
				echo "   Backup \${BACKUP_TO_BE_DELETED} is deleted"
				rm -rf /backup/\${POSTGRES_DB}/\${BACKUP_TO_BE_DELETED}
		done
fi
echo "=> Backup done"
EOF
chmod +x /backup.sh

echo "=> Creating restore script"
rm -f /restore.sh
cat <<EOF >> /restore.sh
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

if [ -n "${INIT_BACKUP}" ]; then
		echo "=> Create a backup on the startup"
		/backup.sh
fi

echo "${CRON_TIME} export MAX_BACKUPS=${MAX_BACKUPS}; export POSTGRES_DB=${POSTGRES_DB}; /backup.sh >> /postgres_backup.log 2>&1" > /crontab.conf
crontab  /crontab.conf
echo "=> Running cron job"
exec cron -f
