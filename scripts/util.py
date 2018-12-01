

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
