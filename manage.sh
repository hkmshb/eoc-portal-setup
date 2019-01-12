#!/bin/bash

set -e

show_help() {
    echo """
COMMANDS:
    elk [--rebuild] [--up]          : manages the elk setup for eoc
    test-elk [--rebuild] [--up]     : manages the standalone elk setup (test setup)
    rsync (to-test-elk | to-elk)    : syncs specific elk folder contents 
                                        (from elk) to test-elk or
                                        (from test-elk) to elk
    """
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

case "$*" in
    help )
        show_help
    ;;
    * )
        perform_task $*
    ;;
esac
