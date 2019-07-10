help:
	@echo "Helper script for EOC development related tasks"
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  clean           to remove project docker volumes"
	@echo "  prepare-build   to prepare the env before a build to commense"
	@echo "  build   	     to build all docker images for defined services"
	@echo "  up           	 to run all available docker containers"
	@echo "  stop            to stop all running docker containers"
	@echo "  devenv          to setup the development environment"
	@echo "  test            to run unit & integration tests"


clean:
	rm -rf ./_volumes/ckan-data ./_volumes/db-data

prepare-build:
	./src/bin/manage.sh prepare-build

build:
	./src/bin/manage.sh build

up:
	docker-compose up

stop:
	docker-compose down

devenv:
	./src/bin/manage.sh devenv

test:
	pycodestyle --count --ignore=E501,E731 ./src/extensions/ckanext-eoc/ckanext/eoc
