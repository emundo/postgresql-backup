# docker-postgres-backup

__Version 2.0 is not released yet. Please use [Version 1.0](../v1.0)__

This image runs `pg_dump` or `pg_basebackup` to backup data using `cron`.

## Usage

```bash
    docker run -d \
        --env POSTGRES_HOST=mysql.host \
        --env POSTGRES_PORT=27017 \
        --env POSTGRES_USER=admin \
        --env POSTGRES_PASSWORD=password \
        --volume /path/to/host/folder:/backup \
        emundo/postgres-backup
```

## Parameters

Environment Variable | Description
-------------------- | -----------
POSTGRES_HOST        | the host/ip of your postgres database
POSTGRES_PORT        | the port number of your postgres database
POSTGRES_USER        | the username of your postgres database
POSTGRES_PASSWORD    | the password of your postgres database
POSTGRES_DB          | the database name to dump. Ignored for `pg_basebackup`. $POSTGRES_USER by default.
POSTGRES_BACKUP_CMD  | 'DUMP' or 'BASEBACKUP'. 'DUMP' by default.
EXTRA_OPTS           | extra options to pass to the restore command
BACKUP_CRON_TIME     | interval of cron job to run backup. `0 0 * * *` by default, which is every day at 00:00
MAX_BACKUPS          | the number of backups to keep. When reaching the limit, the old backup will be discarded. No limit by default
INIT_BACKUP          | if set, create a backup when the container starts

Build Arg              | Description
---------------------- | -----------
POSTGRES_MAJOR_VERSION | Major postgresql version _(I.e. 11, 10, 9.6)_. The build always uses the must current fix version.

## Restore from backup

This is not implemented yet.
