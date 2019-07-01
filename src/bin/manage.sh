#!/bin/bash
set -e


EOC_REPOS=( "ckanext-eoc" "gather2_integration" )
PATH_REPOS=./src/extensions

envvar_template() {
  ENV_TEMPLATE="""
  export DEBUG="true"
  export HOSTNAME="eoc"

  export POSTGRES_USER=
  export POSTGRES_PASS=

  export CKAN_VERSION=ckan-2.7.2
  export CKAN_SITE_URL=http://${HOSTNAME}:5000/
  export CKAN_DB_HOST=db
  export CKAN_DB_USER=ckan
  export CKAN_DB_NAME=ckan
  export CKAN_DB_PASS=

  export CKAN_HOME=/usr/lib/ckan/default
  export CKAN_CONFIG=/etc/ckan/default
  export CKAN_STORAGE_PATH=/var/lib/ckan

  export DATASTORE_NAME=
  export DATASTORE_USER=
  export DATASTORE_PASS=

  export SOLR_CORE=ckan
  export SOLR_HOME=/opt/solr/server/solr/${SOLR_CORE}

  export GATHER_API_KEY=
  export GATHER_RESPONSES_URL=

  export SMTP_SERVER
  export SMTP_USER
  export SMTP_PASS

  export GOOGLE_EMAIL=
  export GOOGLE_PASSWORD=
  export GOOGLE_ANALYTICS_KEY=
  export GOOGLE_CLIENT_ID=
  export GOOGLE_CLIENT_SECRET=
  export AWS_ACCESS_KEY=
  export AWS_SECRET_KEY=
  export GITHUB_TOKEN=
  """
}


show_help() {
  echo """
  Utility script to help with routine EOC development tasks.

  COMMANDS:
  -----------------------------------------------------------------------------
  help            : show this help message
  setup-devenv    : sets up the development environment
  """
}

setup_devenv() {
  if [[ ! -d ${PATH_REPOS} ]]; then
    echo "creating extensions folder ..."
    mkdir -p ${PATH_REPOS}
  fi

  # clone repos locally
  for repo in "${EOC_REPOS[@]}"
    if [[ ! -d ${PATH_REPOS}/${repo} ]]; then
      git clone git@github.com:eHealthAfrica/${repo}.git ${PATH_REPOS}/${repo}
    else
      echo "repo exists; ${repo}"
    fi
  done

  # create .env file
  if [[ ! -f ./.env ]]; then
    echo "creating .env file ..."
    echo envvar_template > ./.env
  else
    echo "file exists; .env"
  fi
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

  cat dev_setup/conf/docker-compose.yml.tmpl | envsubst >docker-compose.yml
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
  help         )  show_help ;;
  setup-devenv )  setup_devenv ;;
  *            )  show_help ;;
esac
