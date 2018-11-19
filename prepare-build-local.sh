#!/bin/sh

abort() {
  echo >&2 '*** ABORTED ***'
}

trap 'abort' 0
set -eux

echo --env file applied--
export HOSTNAME=data-eocng.box

export CKAN_DB_PASSWORD=${CKAN_DB_PASSWORD}
export POSTGRES_PASSWORD=${CKAN_DB_PASSWORD}

export DATA_STORE_PASSWORD=${DATA_STORE_PASSWORD}

export SMTP_SERVER=${SMTP_SERVER}
export SMTP_USER=${SMTP_USER}
export SMTP_PASSWORD=${SMTP_PASSWORD}

export CKAN_VERSION=${CKAN_VERSION}
export CKAN_SITE_URL="http://${CKAN_DB_HOST}:5000"
export CKAN_DB_USER="ckan"
export CKAN_DB_HOST="db"
export CKAN_DB_NAME="ckan"

export DATASTORE_NAME="datastore"
export DATASTORE_USERNAME="datastore"
export DEBUG="true"
export ENV="local"

# # google analytics
# export GOOGLE_ANALYTICS_KEY="${GOOGLE_ANALYTICS_KEY}"
# export GOOGLE_EMAIL="${GOOGLE_EMAIL}"
# export GOOGLE_PASSWORD="${GOOGLE_PASSWORD}"

## gather2
export GATHER2_API_KEY=${GATHER2_API_KEY}
export GATHER2_RESPONSES_URL=${GATHER2_RESPONSES_URL}

## elk
export ELK_VERSION=${ELK_VERSION}


if [ -d ckan_setup ]; then
  echo ckan_setup already exists
else
  git clone --branch master --depth 1 https://github.com/ehealthAfrica/ckan_setup.git ckan_setup

  # we need more than the depth of 1 to be able to checkout to the 2.7 tag we use in build.sh
  git clone --branch ${CKAN_VERSION} --single-branch --depth 1 https://github.com/ckan/ckan.git ./ckan_setup/ckan
  git clone --branch master https://github.com/ckan/datapusher.git ./ckan_setup/datapusher
fi

cat docker-compose.yml.tmpl | envsubst > docker-compose.yml
cat ./ckan_setup/conf/postgres/ckan_init.sql.template | envsubst > ./ckan_setup/conf/postgres/ckan_init.sql

echo ----running build sh----
# exec the build script
. build-local.sh

trap : 0
echo >&2 '*** DONE ***'