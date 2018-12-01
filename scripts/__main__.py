import os, sys
import os.path as fs
import argparse, logging
from pathlib import Path
from pprint import pprint
from . import util

logger = logging.getLogger(__file__)
BASE_DIR = fs.dirname(__file__) or os.getcwd()


def elk_mapping(args):
    '''Processes ELK mapping files as indicated by specified flags.
    '''
    import json
    data = json.load(args.infile.open('r'))
    props = data.get('mappings', {}).get('doc', {}).get('properties', {})
    if not props:
        print("Invalid mapping. '/mappings/doc/properties' object not found")
        return

    entries = []
    for key, val in props.items():
        entry = [key, val.get('type')]
        if 'fields' in val:
            keyword = val.get('fields', {}).get('keyword', None)
            if keyword:
                entry.extend(['+keyword'])
        entries.append(entry)

    util.print_table(entries)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        prog='eoc-scripts',
        description='A collection of task that support with eoc development'
    )
    parser.set_defaults(func=lambda args: parser.print_help())
    subparsers = parser.add_subparsers(title='Commands')

    # subcommand: elk-mapping
    sparser = subparsers.add_parser('elk-mapping')
    sparser.set_defaults(func=elk_mapping)
    sparser.add_argument('infile', type=Path)

    ## parser arguments
    try:
        args = parser.parse_args(sys.argv[1:])
        args.func(args)
    except Exception as ex:
        logger.exception(ex)
