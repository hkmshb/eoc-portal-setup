#!/bin/bash
set -eu

show_help() {
  echo """
  Utility script to help with routine EOC development tasks.

  COMMANDS:
    help            : show this help message
    init            : setup a clean dev env
    prepare-build   : setup the env for a build
    build           : builds the docker contains for all defined services
    ckan-up         : starts up CKAN

    deprecated?
      elk [--rebuild] [--up]          : manages the elk setup for eoc
      test-elk [--rebuild] [--up]     : manages the standalone elk setup (test setup)
      rsync (to-test-elk | to-elk)    : syncs specific elk folder contents 
                                          (from elk) to test-elk or
                                          (from test-elk) to elk
  """
}

perform_init() {
  echo ">> Setup environment for ELK and EOC extensions development..."

  # clone ckan repositories
  if [[ ! -d ckan_setup/ckan ]]; then
    git clone --depth=1 --branch ckan-2.7.2 https://github.com/ckan/ckan.git ckan_setup/ckan
  fi

  if [[ ! -d ckan_setup/datapusher ]]; then
    git clone --branch master https://github.com/ckan/datapusher.git ckan_setup/datapusher
  fi

  # clone eoc repositories
  if [[ ! -d ckan_setup ]]; then
    git clone --depth=1 --branch=develop https://github.com/eHealthAfrica/ckan_setup.git
  fi

  if [[ ! -d extensions/ckanext-eoc ]]; then
    git clone https://github.com/eHealthAfrica/ckanext-eoc.git extensions/ckanext-eoc
  fi

  if [[ ! -d extensions/gather2_integration ]]; then
    git clone https://github.com/eHealthAfrica/gather2_integration.git extensions/gather2_integration
  fi

  if [[ ! -d ckan_elk ]]; then
    git clone https://github.com/hkmshb/eoc-elk.git ckan_elk
  fi

  echo ">> Done setting up environment"
}

perform_prepare_build() {
  echo ">> Preparing the environment for a build..."
  echo ">> exporting env vars..."

  source .env
  export HOSTNAME=${HOSTNAME}

  ## default creds for docker db
  export POSTGRES_USER=${POSTGRES_USER}
  export POSTGRES_PASSWORD=${POSTGRES_PASS}
  
  export CKAN_SITE_URL=${CKAN_SITE_URL}
  export CKAN_DB_HOST=${CKAN_DB_HOST}
  export CKAN_DB_NAME=${CKAN_DB_NAME}
  export CKAN_DB_USER=${CKAN_DB_USER}
  export CKAN_DB_PASSWORD=${CKAN_DB_PASSWORD}
  export CKAN_API_KEY=e5d96aec-5f01-4065-bc74-0ada0a54f355
  
  export DATASTORE_NAME=${DATASTORE_NAME}
  export DATASTORE_USERNAME=${DATASTORE_USERNAME}
  export DATA_STORE_PASSWORD=${DATASTORE_PASSWORD}

  export SMTP_SERVER=${SMTP_SERVER}
  export SMTP_USER=${SMTP_USER}
  export SMTP_PASSWORD=${SMTP_PASSWORD}

  export DEBUG=${DEBUG}

  export LOGSTASH_DBHOST=${LOGSTASH_DBHOST}
  export LOGSTASH_DBUSER=${LOGSTASH_DBUSER}
  export LOGSTASH_DBPASS=${LOGSTASH_DBPASS}

  #export GOOGLE_ANALYTICS_KEY="$(credstash get ckan-eocng-dev-analytics-key)"
  #export GOOGLE_EMAIL="$(credstash get ckan-eocng-dev-email-username)"
  #export GOOGLE_PASSWORD="$(credstash get ckan-eocng-dev-email-password)"

  #export AWS_ACCESS_KEY="$(credstash get ckan_dev_aws_access_key)"
  #export AWS_SECRET_KEY="$(credstash get ckan_dev_aws_secret_key)"

  cat conf/docker-compose.yml.tmpl | envsubst >docker-compose.yml
  cat ckan_setup/conf/postgres/ckan_init.sql.template | envsubst >ckan_setup/conf/postgres/ckan_init.sql

  perform_build
}

perform_build() {
  echo ">> Copying files in preparation for docker image build..."
  cd ckan_setup

  # syncjob
  mkdir -p sync_cronjob/conf
  cp conf/sync-prod-data.sh sync_cronjob/conf
  cp conf/sync-prod-data-cron sync_cronjob/conf

  # patch ckan
  if [[ ! -f ckan/.skip ]]; then
    cp ckan_patch.patch ckan
    cd ckan

    git apply ckan_patch.patch
    touch .skip
    cd ..
  fi

  rsync -a conf/* ckan/conf

  cp datapusher_Dockerfile datapusher/Dockerfile
  cp conf/datapusher_settings.py datapusher/deployment/datapusher_settings.py
  cp conf/datapusher_main.py datapusher/datapusher/main.py

  cp sync_cronjob_Dockerfile sync_cronjob/Dockerfile
  cp solr_Dockerfile ckan/contrib/docker/solr/Dockerfile

  echo ">> (re)-build images ..."
  docker-compose build ckan
}

perform_task() {
  if [[ "$*" =~ ^elk ]]; then
    if [[ "$*" =~ \-\-rebuild ]]; then
      docker-compose build elasticsearch kibana logstash
    fi

    if [[ "$*" =~ \-\-up ]]; then
      docker-compose up elasticsearch kibana logstash
    fi
  fi

  if [[ "$*" =~ ^test-elk ]]; then
    if [[ "$*" =~ \-\-rebuild ]]; then
      docker-compose -f ./_elk/docker-compose.yml build
    fi

    if [[ "$*" =~ \-\-up ]]; then
      docker-compose -f ./_elk/docker-compose.yml up
    fi
  fi

  if [[ "$*" =~ ^rsync ]]; then
    if [[ "$*" =~ to-test-elk ]]; then
      echo "syncing logstash contents from eoc-setup/elk to _elk"
      src=ckan_setup/elk/logstash
      dst=_elk/logstash
    elif [[ "$*" =~ to-elk ]]; then
      echo "syncing logstash contents from _elk to eoc-setup/elk"
      src=_elk/logstash
      dst=ckan_setup/elk/logstash
    else
      return
    fi
    
    echo "sync..."
    rsync -a $src/pipeline/* $dst/pipeline
    rsync -a $src/mapping/* $dst/mapping
    rsync -a $src/sql/* $dst/sql
    echo "done!"
  fi
}

sync_elk2orig() {
  src=ckan_elk/logstash
  dst=ckan_setup/elk/logstash

	rsync -a ${src}/pipeline/* ${dst}/pipeline
	rsync -a ${src}/mapping/* ${dst}/mapping
	rsync -a ${src}/sql/* ${dst}/sql
}

case "$*" in
  help )
    show_help
  ;;
  init )
    perform_init
  ;;
  prepare-build )
    perform_prepare_build
  ;;
  build )
    perform_build
  ;;
  ckan-up )
    source .env
    docker-compose up db redis solr ckan
  ;;
  sync-elk2orig )
    sync_elk2orig
  ;;
  * )
    show_help
  ;;
esac
