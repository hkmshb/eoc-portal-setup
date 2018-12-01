#!/bin/bash

set -e

if [[ "$*" =~ ^elk ]]; then
    if [[ "$*" =~ \-\-rebuild ]]; then
        docker-compose build elasticsearch kibana logstash
    fi

    if [[ "$*" =~ \-\-up ]]; then
        docker-compose up elasticsearch kibana logstash
    fi
fi

if [[ "$*" =! ^test-elk ]]; then
    if [[ "$*" =~ \-\-rebuild ]]; then
        docker-compose build -f ./_elk/docker-compose.yml
    fi

    if [[ "$*" =~ \-\-up ]]; then
        docker-compose up -f ./_elk/docker-compose.yml
    fi
fi
