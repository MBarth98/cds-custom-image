FROM ubuntu:latest

# Install dependencies
RUN apt-get update 
RUN apt-get -y install bash curl gpg git ca-certificates file 

# Download CDS components
WORKDIR $HOME/cds
RUN curl -L https://github.com/ovh/cds/releases/download/0.51.0/cds-engine-linux-amd64 -o cds-engine
RUN curl -L https://github.com/ovh/cds/releases/download/0.51.0/cdsctl-linux-amd64 -o cdsctl
RUN chmod +x cds-engine cdsctl
RUN mkdir -p $HOME/cds/artifacts $HOME/cds/download $HOME/cds/hatchery-basedir $HOME/cds/app $HOME/cds/cdn-buffer $HOME/cds/cdn-storage $HOME/cds/repositories

# generate config
RUN ["/bin/bash", "-c", "./cds-engine config new > config.toml"]

# exports

ENV CDS_API_HOSTNAME="localhost" CDS_HOOKS_HOSTNAME="localhost" CDS_VCS_HOSTNAME="localhost" CDS_REPOSITORIES="" \
CDS_HATCHERY_LOCAL="localhost" CDS_HATCHERY_SWARM="" CDS_ELASTICSEARCH_HOSTNAME="localhost" CDS_CDN_HOSTNAME="localhost" \
ELASTICSEARCH_HOSTNAME="localhost" REDIS_CACHE_DB="localhost" DOCKERHOST_TCP="localhost" POSTGRES_HOST="localhost" POSTGRES_DB="postgres" POSTGRES_USER="postgres" POSTGRES_PWD="postgres" REDIS_PASSWORD="cds"

EXPOSE 8080 8081 8082 8083 8084 8085 8086 8087 8088 8089 9200 6379 2375

# edit configs

RUN echo '#!/bin/sh \n \
./cds-engine config edit config.toml --output config.toml api.artifact.local.baseDirectory=$HOME/cds/artifacts \n \
./cds-engine config edit config.toml --output config.toml api.cache.redis.password=$REDIS_PASSWORD \n \
./cds-engine config edit config.toml --output config.toml api.database.host=$POSTGRES_HOST \n \
./cds-engine config edit config.toml --output config.toml api.log.level=info \n \
./cds-engine config edit config.toml --output config.toml api.cache.redis.host=$REDIS_CACHE_DB:6379 \n \
./cds-engine config edit config.toml --output config.toml api.download.directory=$HOME/cds/app \n \
./cds-engine config edit config.toml --output config.toml api.directories.download=$HOME/cds/download \n \
\n \
./cds-engine config edit config.toml --output config.toml vcs.cache.redis.password=$REDIS_PASSWORD \n \
./cds-engine config edit config.toml --output config.toml vcs.cache.redis.host=$REDIS_CACHE_DB:6379 \n \
./cds-engine config edit config.toml --output config.toml vcs.api.http.url=http://$CDS_API_HOSTNAME:8081 \n \
./cds-engine config edit config.toml --output config.toml vcs.URL=http://$CDS_VCS_HOSTNAME:8084 \n \
\n \
./cds-engine config edit config.toml --output config.toml hatchery.local.basedir=$HOME/cds/hatchery-basedir \n \
./cds-engine config edit config.toml --output config.toml hatchery.local.commonConfiguration.url=http://$CDS_HATCHERY_LOCAL:8086 \n \
./cds-engine config edit config.toml --output config.toml hatchery.local.commonConfiguration.api.http.url=http://$CDS_API_HOSTNAME:8081 \n \
\n \
./cds-engine config edit config.toml --output config.toml cdn.storageUnits.buffers.local-buffer.local.path=$HOME/cds/cdn-buffer \n \
./cds-engine config edit config.toml --output config.toml cdn.storageUnits.storages.local.local.path=$HOME/cds/cdn-storage \n \
./cds-engine config edit config.toml --output config.toml cdn.api.http.url=http://$CDS_API_HOSTNAME:8081 \n \
./cds-engine config edit config.toml --output config.toml cdn.URL=http://$CDS_CDN_HOSTNAME:8089 \n \
./cds-engine config edit config.toml --output config.toml cdn.cache.redis.password=$REDIS_PASSWORD \n \
./cds-engine config edit config.toml --output config.toml cdn.storageUnits.buffers.redis.redis.password=$REDIS_PASSWORD \n \
./cds-engine config edit config.toml --output config.toml cdn.cache.redis.host=$REDIS_CACHE_DB:6379 \n \
./cds-engine config edit config.toml --output config.toml cdn.storageUnits.buffers.redis.redis.host=$REDIS_CACHE_DB:6379 \n \
./cds-engine config edit config.toml --output config.toml cdn.database.host=$POSTGRES_HOST \n \
./cds-engine config edit config.toml --output config.toml cdn.publicTCP=$HOSTNAME:8090 \n \
\n \
./cds-engine config edit config.toml --output config.toml elasticsearch.api.http.url=http://$CDS_API_HOSTNAME:8081 \n \
./cds-engine config edit config.toml --output config.toml elasticsearch.URL=http://$CDS_ELASTICSEARCH_HOSTNAME:8088 \n \
./cds-engine config edit config.toml --output config.toml elasticsearch.elasticsearch.url=http://$ELASTICSEARCH_HOSTNAME:9200 \n \
./cds-engine config edit config.toml --output config.toml elasticsearch.elasticsearch.indexEvents=cds-index-events \n \
./cds-engine config edit config.toml --output config.toml elasticsearch.elasticsearch.indexMetrics=cds-index-metrics \n \
./cds-engine config edit config.toml --output config.toml elasticsearch.name=elasticsearch \n \
\n \
./cds-engine config edit config.toml --output config.toml hooks.url=http://$CDS_HOOKS_HOSTNAME:8083 \n \
./cds-engine config edit config.toml --output config.toml hooks.cache.redis.host=$REDIS_CACHE_DB:6379 \n \
./cds-engine config edit config.toml --output config.toml hooks.cache.redis.password=$REDIS_PASSWORD \n \
\n \
./cds-engine config edit config.toml --output config.toml ui.api.http.url=http://$CDS_API_HOSTNAME:8081 \n \
./cds-engine config edit config.toml --output config.toml ui.cdnURL=http://$CDS_CDN_HOSTNAME:8089 \n \
./cds-engine config edit config.toml --output config.toml ui.hooksURL=http://$CDS_HOOKS_HOSTNAME:8083 \n \
./cds-engine config edit config.toml --output config.toml ui.enableServiceProxy=true \n \
' > setup_config.sh

#./cds-engine config edit config.toml --output config.toml hatchery.swarm.dockerEngines.sample-docker-engine.maxContainers=4 \n \
#./cds-engine config edit config.toml --output config.toml hatchery.swarm.dockerEngines.sample-docker-engine.host=tcp://$DOCKERHOST_TCP:2375 \n \
#./cds-engine config edit config.toml --output config.toml hatchery.swarm.commonConfiguration.url=http://$CDS_HATCHERY_SWARM:8086 \n \
#./cds-engine config edit config.toml --output config.toml hatchery.swarm.commonConfiguration.api.http.url=http://$CDS_API_HOSTNAME:8081 \n \
#./cds-engine config edit config.toml --output config.toml hatchery.swarm.commonConfiguration.provision.workerApiHttp.url=http://$CDS_API_HOSTNAME:8081 \n \

#./cds-engine config edit config.toml --output config.toml repositories.basedir=$HOME/cds/repositories \n \
#./cds-engine config edit config.toml --output config.toml repositories.api.http.url=http://$CDS_API_HOSTNAME:8081 \n \
#./cds-engine config edit config.toml --output config.toml repositories.URL=http://$CDS_REPOSITORIES:8085 \n \
#./cds-engine config edit config.toml --output config.toml repositories.cache.redis.password=$REDIS_PASSWORD \n \
#./cds-engine config edit config.toml --output config.toml repositories.cache.redis.host=$REDIS_CACHE_DB:6379 \

RUN echo '#!/bin/sh \n \
./cds-engine database upgrade --db-host $POSTGRES_HOST --db-user $POSTGRES_USER --db-password $POSTGRES_PWD --db-name $POSTGRES_DB --db-schema public --db-sslmode disable --db-port 5432 --migrate-dir sql/api \n \
PGPASSWORD=$POSTGRES_PWD psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c "CREATE SCHEMA IF NOT EXISTS cdn AUTHORIZATION cds;" \n \
./cds-engine database upgrade --db-host $POSTGRES_HOST --db-user $POSTGRES_USER --db-password $POSTGRES_PWD --db-name $POSTGRES_DB --db-schema cdn --db-sslmode disable --db-port 5432 --migrate-dir sql/cdn \n \
./cds-engine start api hooks hatchery:local --config config.toml \n \
' > startup.sh

RUN chmod +x setup_config.sh startup.sh

RUN ./setup_config.sh

# download dependencies
RUN ["/bin/bash", "-c", "./cds-engine download sql --config config.toml"]
RUN ["/bin/bash", "-c", "./cds-engine download workers --config config.toml"]
RUN ["/bin/bash", "-c", "./cds-engine download ui --config config.toml"]

ENTRYPOINT ./startup.sh
