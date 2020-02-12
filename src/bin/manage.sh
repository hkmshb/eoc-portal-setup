#!/bin/bash
set -e

EXTS_PATH=./src/extensions
EHA_GIT_PATH=git@github.com:eHealthAfrica
EHA_REPOS=( "ckan_setup" "ckanext-eoc" "gather2_integration" )

CKAN_VERSION=ckan-2.7.2
CKAN_REPOS=( "ckan" "datapusher" )
CKAN_GIT_PATH=git@github.com:ckan


envvar_template() {
  echo """
  export DEBUG="true"
  export HOSTNAME="eoc"
  export GITHUB_TOKEN=

  export PG_USERNAME=
  export PG_PASSWORD=

  export CKAN_VERSION=${CKAN_VERSION}
  export CKAN_SITE_URL=http://${HOSTNAME}:5000/
  export CKAN_DB_HOST=db
  export CKAN_DB_USER=ckan
  export CKAN_DB_NAME=ckan
  export CKAN_DB_PASS=

  export DATASTORE_NAME=datastore
  export DATASTORE_USER=datastore
  export DATASTORE_PASS=

  export SOLR_CORE=ckan
  export SOLR_HOME=/opt/solr/server/solr/${SOLR_CORE}

  export GATHER_API_KEY=
  export GATHER_RESPONSES_URL=

  export SMTP_SERVER=
  export SMTP_USER=
  export SMTP_PASS=

  export GOOGLE_EMAIL=
  export GOOGLE_PASSWORD=
  export GOOGLE_ANALYTICS_KEY=
  export GOOGLE_CLIENT_ID=
  export GOOGLE_CLIENT_SECRET=

  export AWS_ACCESS_KEY=
  export AWS_SECRET_KEY=
  """
}

show_help() {
  echo """
  Utility script to help with routine EOC development tasks.

  COMMANDS:
  -----------------------------------------------------------------------------
  help            : show this help message
  devenv          : sets up the development environment
  build           : export env vars, copy necessary files and build ckan image
  """
}

setup_devenv() {
  # clone eoc repos locally
  MAIN_REPO=${EHA_REPOS[0]}

  if [[ ! -d ${MAIN_REPO} ]]; then
    echo ">> creating the main repo ..."
    git clone ${EHA_GIT_PATH}/${MAIN_REPO}.git ${MAIN_REPO}
  fi

  if [[ ! -d ${EXTS_PATH} ]]; then
    echo ">> creating extensions folder ..."
    mkdir -p ${EXTS_PATH}
  fi

  for repo in "${EHA_REPOS[@]:1}"
  do
    if [[ ! -d ${EXTS_PATH}/${repo} ]]; then
      git clone ${EHA_GIT_PATH}/${repo}.git ${EXTS_PATH}/${repo}
    else
      echo ">> repo exists; ${repo}"
    fi
  done

  # clone ckan repos locally
  for repo in "${CKAN_REPOS[@]}"
  do
    if [[ ! -d ${MAIN_REPO}/${repo} ]]; then
      if [[ "${repo}" == "ckan" ]]; then
        git clone --branch ${CKAN_VERSION} --depth 1 ${CKAN_GIT_PATH}/${repo}.git ${MAIN_REPO}/${repo}
      else
        git clone --branch master --depth 1 ${CKAN_GIT_PATH}/${repo}.git ${MAIN_REPO}/${repo}
      fi
    else
      echo ">> repo exists; ${repo}"
    fi
  done

  # create .env file
  if [[ ! -f ./.env ]]; then
    echo ">> creating .env file ..."
    echo "$( envvar_template )" > ./.env
  else
    echo ">> file exists; .env"
  fi
}

perform_build() {
  echo ">> export env vars ..."

  source .env
  export POSTGRES_USER=${PG_USERNAME}
  export POSTGRES_PASSWORD=${PG_PASSWORD}
  export CKAN_API_KEY=e5d96aec-5f01-4065-bc74-0ada0a54f355

  echo ">> (re)generate ckan_init.sql from template ..."
  cat ckan_setup/conf/postgres/ckan_init.sql.template | envsubst > ckan_setup/conf/postgres/ckan_init.sql

  echo ">> (re)generate docker-compose.yml from template ..."
  cat src/docker-compose.yml.tmpl | envsubst > docker-compose.yml

  # patch ckan
  cd ckan_setup
  if [[ ! -f ckan/.skip ]]; then
    echo ">> patch ckan with local updates ..."

    cp ckan_patch.patch ckan
    cd ckan

    git apply ckan_patch.patch
    touch .skip
    cd ..
  fi

  echo ">> copying files in preparation for docker image build..."
  rsync -a conf/* ckan/conf

  cp datapusher_Dockerfile datapusher/Dockerfile
  cp conf/datapusher_settings.py datapusher/deployment/datapusher_settings.py
  cp conf/datapusher_main.py datapusher/datapusher/main.py
  cp solr_Dockerfile ckan/contrib/docker/solr/Dockerfile

  echo ">> (re)-build ckan image ..."
  docker-compose build datapusher solr ckan
}

case "$*" in
  help         )  show_help ;;
  devenv       )  setup_devenv ;;
  build        )  perform_build ;;
  *            )  show_help ;;
esac
