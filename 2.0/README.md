# docker-postgres-backup

__Version 2.0 is not released yet. Please use [Version 1.0](../v1.0)__

This image runs `pg_dump` or `pg_basebackup` to backup data using `cron`.

## Usage

## Parameters

## Restore from a backup

See the list of backups, you can run:

    docker exec docker-postgres-backup ls /backup

To restore database from a certain backup, simply run:

    docker exec docker-postgres-backup /restore.sh /backup/2015.08.06.171901
