import sys
import json
import os.path as fs


def print_table(data):
    # determine max cols present
    max_col_count = max([len(r) for r in data])

    # determine optimal col widths
    col_widths = []
    for idx in range(max_col_count):
        col_widths.append(
            max([len(r[idx : idx + 1][0]) for r in data if r[idx: idx + 1]])
        )

    fmt = " | ".join([
        '{{{0}:{1}}}'.format(idx, val)
        for (idx, val) in enumerate(col_widths)
    ])
    for r in data:
        col_diff = max_col_count - len(r)
        if col_diff > 0:
            r += ['.'] * col_diff

        print(fmt.format(*r))


def csv2json(path, fields):
    # convert CSV input into JSON
    path = fs.abspath(fs.expanduser(path))
    if not (fs.exists(path) and fs.isfile(path)):
        print(f"file not found: {path}")
        sys.exit()

    if not isinstance(fields, (list, tuple)):
        fields = fields.strip().split(",")

    entries = []
    with open(path, 'r') as fp:
        for ln in fp.readlines():
            values = ln.strip().split(",")

            entry = dict(zip(fields[:], values))
            entries.append(entry)
    print(entries)
    return json.dumps(entries, indent=2)
