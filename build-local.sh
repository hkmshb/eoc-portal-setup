#!/bin/bash
set -eux

## commeted out
# export KEY=$1
# export IV=$2

# function decrypt {
#   openssl enc -aes-256-cbc -in $1 -out $2 -K ${KEY} -iv ${IV} -d
# }

# # syncjob
# mkdir -p sync_cronjob/conf
# cp conf/sync-prod-data.sh sync_cronjob/conf
# cp conf/sync-prod-data-cron sync_cronjob/conf

# # nginx
# decrypt nginx/conf/cert.pem.enc nginx/conf/cert.pem

cd ckan_setup
if [ ! -f .skip ]; then
    cp ckan_patch.patch ckan
    cd ckan

    git apply ckan_patch.patch
    touch .skip
    cd ..
fi

rsync -a conf/* ckan/conf

cp -r ckan_Dockerfile ckan/Dockerfile
cp datapusher_Dockerfile datapusher/Dockerfile

# cp sync_cronjob_Dockerfile sync_cronjob/Dockerfile

cp conf/datapusher_settings.py datapusher/deployment/datapusher_settings.py
cp conf/datapusher_main.py datapusher/datapusher/main.py
# cp nginx/conf/cert.pem datapusher

cp nginx_Dockerfile nginx/Dockerfile
cp solr_Dockerfile ckan/contrib/docker/solr/Dockerfile


## Data Portal
docker-compose build ckan
docker-compose build datapusher
# docker-compose build sync_cronjob
# docker-compose build nginx
docker-compose build solr


## ELK stack
docker-compose build elasticsearch
docker-compose build kibana
docker-compose build logstash
