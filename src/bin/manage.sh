#!/usr/bin/env bash
set -Eeuo pipefail

LINE=`printf -v row "%${COLUMNS:-$(tput cols)}s"; echo ${row// /=}`

function echo_msg {
  if [ -z "$1" ]; then
    echo -e "\033[90m$LINE\033[0m"
  else
    msg=" $1 "
    color=${2:-\\033[39m}
    echo -e "\033[90m${LINE:${#msg}}\033[0m$color$msg\033[0m"
  fi
}

function purge_env {
  rm -rf ckan_setup
  rm -rf src/extensions
}

function fetch_codes {
  local CKAN_VERSION=ckan-2.7.2
  local DATAPUSHER_GIT_BRANCH=0.0.14

  local CKAN_GITHUB_BASEURL=git@github.com:ckan
  local CKAN_GITHUB_REPO_NAMES=( "ckan" "datapusher" )

  local CKANEXT_BASEDIR=./src/extensions
  local EHA_GITHUB_BASEURL=git@github.com:eHealthAfrica
  local EHA_GITHUB_REPO_NAMES=( "ckan_setup" "ckanext-eoc" "gather2_integration" )

  # clone eoc repos locally
  MAIN_REPO=${EHA_GITHUB_REPO_NAMES[0]}

  if [[ ! -d ${MAIN_REPO} ]]; then
    echo_msg "Creating the main repo ..."
    git clone ${EHA_GITHUB_BASEURL}/${MAIN_REPO}.git ${MAIN_REPO}
  fi

  if [[ ! -d ${CKANEXT_BASEDIR} ]]; then
    echo_msg "Creating extensions folder ..."
    mkdir -p ${CKANEXT_BASEDIR}
  fi

  for repo in "${EHA_GITHUB_REPO_NAMES[@]:1}"
  do
    if [[ ! -d ${CKANEXT_BASEDIR}/${repo} ]]; then
      git clone ${EHA_GITHUB_BASEURL}/${repo}.git ${CKANEXT_BASEDIR}/${repo}
    else
      echo ">> repo exists; ${repo}"
    fi
  done

  # clone ckan repos locally
  for repo in "${CKAN_GITHUB_REPO_NAMES[@]}"
  do
    if [[ ! -d ${MAIN_REPO}/${repo} ]]; then
      if [[ "${repo}" == "ckan" ]]; then
        git clone --branch ${CKAN_VERSION} --depth 1 ${CKAN_GITHUB_BASEURL}/${repo}.git ${MAIN_REPO}/${repo}
      else
        git clone --branch ${DATAPUSHER_GIT_BRANCH} --depth 1 ${CKAN_GITHUB_BASEURL}/${repo}.git ${MAIN_REPO}/${repo}
      fi
    else
      echo ">> repo exists; ${repo}"
    fi
  done
}

function build_docker_images {
  source .env.local

  echo_msg "(Re)generate ckan_init.sql from template ..."
  cat ckan_setup/conf/postgres/ckan_init.sql.template | envsubst > ckan_setup/conf/postgres/ckan_int.sql

  # patch ckan
  cd ckan_setup
  if [[ ! -f ckan/.skip ]]; then
    echo_msg "Patch CKAN with local updates ..."

    cp ckan_patch.patch ckan
    cd ckan

    git apply ckan_patch.patch
    touch .skip
    cd ..
  fi

  echo_msg "Copying files in preparation for docker image build ..."
  rsync -a conf/* ckan/conf

  cp datapusher_Dockerfile datapusher/Dockerfile
  cp conf/datapusher_settings.py datapusher/deployment/datapusher_settings.py
  cp conf/datapusher_main.py datapusher/datapusher/main.py
  cp solr_Dockerfile ckan/contrib/docker/solr/Dockerfile

  echo_msg "(Re)-build docker images ..."
  docker-compose build --no-cache --force-rm datapusher solr ckan
}

case "$*" in
  purge )
    echo_msg "Purging the local development env setup ..."
    purge_env
  ;;

  init )
    if [ ! -e .env.local ]; then
      ./src/bin/gen_env_file.sh
      echo -e "\033[93mUpdate created .env file then re-issue 'make init' again\033[0m"
    else
      source .env.local

      fetch_codes
      build_docker_images
    fi
  ;;

esac