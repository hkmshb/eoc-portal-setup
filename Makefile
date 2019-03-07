help:
	@echo "Helper script for EOC development related tasks"
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  start-ckan    to run just the ckan docker containers"
	@echo "  start-elk     to run just the elk docker containers"
	@echo "  start         to run all available docker containers"
	@echo "  stop          to stop all running docker containers"

start-ckan:
	docker-compose up db redis datapusher ckan

start-elk:
	docker-compose up elasticsearch logstash kibana

start:
	docker-compose up

stop:
	docker-compose down
