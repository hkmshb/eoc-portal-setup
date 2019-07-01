help:
	@echo "Helper script for EOC development related tasks"
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  install         to perform a clean dev env setup and install"
	@echo "  prepare-build   to prepare the env before a build to commense"
	@echo "  build-ckan      to build just the ckan docker container"
	@echo "  start-ckan      to run just the ckan docker containers"
	@echo "  start-elk       to run just the elk docker containers"
	@echo "  start           to run all available docker containers"
	@echo "  stop            to stop all running docker containers"

install:
	./src/bin/manage.sh init

clean:
	rm -rf ./_volumes/ckan-data ./_volumes/db-data

prepare-build:
	./src/bin/manage.sh prepare-build

build:
	./src/bin/manage.sh build

ckan-build:
	docker-compose build ckan

up:
	docker-compose up -d

stop:
	docker-compose down

sync-elk2orig:
	@echo "syncing local logstash config to ${dst}...\n"
	./src/bin/manage.sh sync-elk2orig
	@echo done

test:
	pycodestyle --count --ignore=E501,E731 ./src/extensions/ckanext-eoc/ckanext/eoc
