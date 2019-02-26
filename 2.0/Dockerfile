FROM ubuntu:18.04

LABEL maintainer="Simon Nagl <simon.nagl@e-mundo.de"

ARG POSTGRES_MAJOR_VERSION=11

RUN apt-get update && \
    apt-get install -y wget curl cron gnupg2
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main ${POSTGRES_MAJOR_VERSION}" >/etc/apt/sources.list.d/pgdg.list

RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

RUN apt-get update && \
    apt-get install -y postgresql-client-${POSTGRES_MAJOR_VERSION}

ADD run.sh /run.sh
RUN chmod +x /run.sh
RUN mkdir /backup
VOLUME [ "/backup" ]

ENV BACKUP_CRON_TIME="0 0 * * *"

CMD ["/run.sh"]
