#!/bin/sh
set -x

source ~/.bashrc

# Fill in env variables
cat /etc/ckan/default/ckan.ini.template | envsubst >/etc/ckan/default/ckan.ini


# wait for postgres to come up
/opt/ckan/wait-for-it.sh  ${CKAN_DB_HOST}:5432 -t 20
# wait for redis to come up
/opt/ckan/wait-for-it.sh  redis:6379 -t 40
# wait for solr to come up
/opt/ckan/wait-for-it.sh  solr:8983 -t 20

# wait a bit more
sleep 5

# install extensionss
cd $CKAN_HOME/src/extensions
# Install EOC Extension
ckan-pip install -e ckanext-eoc
ckan-pip install -r ckanext-eoc/requirements.txt
# Install Gather 2 Integration
ckan-pip install -e gather2_integration
ckan-pip install -r gather2_integration/requirements.txt

openssl enc -d  -aes-256-cbc  -k "${GOOGLE_ANALYTICS_KEY}" -a -salt \
   -in $CKAN_HOME/src/ckanext-googleanalytics/credentials.json.enc \
   -out $CKAN_HOME/src/ckanext-googleanalytics/credentials.json

# Initializes the Database
ckan-paster --plugin=ckan db init -c "${CKAN_CONFIG}/ckan.ini"

# Rebuild datasets not already indexed
ckan-paster --plugin=ckan search-index rebuild -o -c "${CKAN_CONFIG}/ckan.ini"


# Initializes Google Analytics
cd $CKAN_HOME/src/ckanext-googleanalytics && ckan-paster initdb --config=$CKAN_CONFIG/ckan.ini
cd $CKAN_HOME/src/ckanext-googleanalytics && ckan-paster loadanalytics credentials.json --config=$CKAN_CONFIG/ckan.ini

/usr/bin/supervisord -n
