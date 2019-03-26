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
	./dev_setup/bin/manage.sh init

clean:
	rm -rf ./dev_setup/_data/ckan-data ./dev_setup/_data/db-data

prepare-build:
	./dev_setup/bin/manage.sh prepare-build

ckan-build:
	docker-compose build ckan

ckan-up:
	docker-compose up db redis datapusher ckan

start-elk:
	docker-compose up elasticsearch logstash kibana

start:
	docker-compose up

stop:
	docker-compose down

sync-elk2orig:
	@echo "syncing local logstash config to ${dst}...\n"
	./dev_setup/bin/manage.sh sync-elk2orig
	@echo done
