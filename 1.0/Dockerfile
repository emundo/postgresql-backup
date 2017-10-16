# this is forked from https://github.com/jmcarbo/docker-postgres-backup
FROM ubuntu
MAINTAINER Georgi Potzkov <georgi.potzkov@e-mundo.de>

RUN apt-get update && \
    apt-get install -y wget curl cron
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main 9.5" >/etc/apt/sources.list.d/postgresql.list
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-get update && \
    apt-get install -y postgresql-9.6 curl && \
    mkdir /backup

ENV CRON_TIME="0 0 * * *"

ADD run.sh /run.sh
RUN chmod +x /run.sh
VOLUME ["/backup"]

CMD ["/run.sh"]
