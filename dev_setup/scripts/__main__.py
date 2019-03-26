import os, sys
import os.path as fs
import argparse, logging
from pathlib import Path
from pprint import pprint
from enum import Enum
from . import util

logger = logging.getLogger(__file__)
BASE_DIR = fs.dirname(__file__) or os.getcwd()


class CSVDataEnum(Enum):
    CHECK_DUPLICATE = 1
    COUNT_RECORDS = 2
    SHOW_COLUMN_DATA = 3

    @classmethod
    def to_list(cls):
        return [
            i.name.lower().replace('_', '-') for i in cls
        ]


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


def csv_data(args):
    '''Processes CSV data file as specified by flags.
    
    :param infile: file path for csv file to be processed
    :param columns: list of columns to process
    :param action: one of CSVDataAction enum value
    '''
    import csv

    def collect_files(path):
        def get(pth, files):
            if pth.is_file():
                files.append(pth)
            else:
                for item in pth.iterdir():
                    get(item, files)
        
        found_files = []
        get(path, found_files)
        return found_files

    def find_duplicates(fileobj, col_values, dup_values):
        with fileobj.open('r') as fp:
            reader = csv.DictReader(fp)
            fname = fileobj.name
            for idx, row in enumerate(reader):
                for col in args.columns:
                    values = col_values.get(col, set())
                    value = row.get(col, None)
                    if not value:
                        print("x column '{}' of {}:line {} is blank".format(
                            value, fname, idx
                        ))
                    else:
                        value = value.lower().strip()
                        if value not in values:
                            values.add(value)
                        else:
                            msg = "'{}={}' of {}:line {} already exists"
                            dup_values.append(msg.format(col, value, fname, idx))

            if dup_values:
                print('\n'.join(dup_values))
            else:
                print('no duplicates found in {} lines of {}'.format(idx, fname))

    def task_check_duplicate():
        # read in csv data and collected specified columns
        col_values = {}
        dup_values = []

        # set defaults
        for col in args.columns:
            col_values.setdefault(col, set())

        for fp in collect_files(args.infile):
            find_duplicates(fp, col_values, dup_values)

        for col, values in col_values.items():
            print('col={} has {} lines'.format(col, len(values)))

    def task_count_records():
        counts, summary = [], []
        for fp in collect_files(args.infile):
            try:
                with fp.open('r') as _fp:
                    count = max(len(_fp.readlines()) -2, 0)
                    counts.append(count)
                    summary.append(
                        '{0:<10,} lines from {1}'.format(count, fp.name)
                    )
            except Exception as ex:
                print('Unable to process file: {!r}'.format(fp))

        summary.append('-' * 25)
        summary.append('{:<10} {:,}'.format('TOTAL', sum(counts)))
        print('\n'.join(summary))

    def task_show_column_data():
        values = []

        with args.infile.open('r') as fp:
            for row in csv.DictReader(fp):
                values.append([row.get(col) for col in args.columns])

        util.print_table(values)

    tasks = {
        'check-duplicate': task_check_duplicate,
        'count-records': task_count_records,
        'show-column-data': task_show_column_data,
    }
    tasks[args.action]()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        prog='eoc-scripts',
        description='A collection of task that support with eoc development'
    )
    parser.set_defaults(func=lambda args: parser.print_help())
    subparsers = parser.add_subparsers(title='Commands')

    # sub-command: elk-mapping
    sparser = subparsers.add_parser('elk-mapping')
    sparser.set_defaults(func=elk_mapping)
    sparser.add_argument('infile', type=Path)

    # sub-command: csv
    sparser = subparsers.add_parser('csv')
    sparser.set_defaults(func=csv_data)
    sparser.add_argument('infile', type=Path)
    sparser.add_argument('-c', '--columns', nargs='+')
    sparser.add_argument(
        '-a', '--action', default='check-duplicate',
        choices=CSVDataEnum.to_list()
    )

    ## parser arguments
    try:
        args = parser.parse_args(sys.argv[1:])
        args.func(args)
    except Exception as ex:
        logger.exception(ex)
