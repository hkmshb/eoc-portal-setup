def summarize_line_data(fpath, *show):
    if not isinstance(fpath, Path):
        fpath = Path(fpath)
    
    with fpath.open() as fp:
        headers = fp.readline().split(',')

        for (i, ln) in enumerate(fp.readlines()):
            print("line {}: {}".format(i, len(ln.split(','))))

            if show:
                info = dict(zip(headers, ln.split(',')))
                print({k: info[k] for k in show})


def count_csv_lines(dirpath):
    def walk(pth):
        for p, dnames, fnames in os.walk(pth):
            for fn in fnames:
                yield Path(p, fn)

    filtered = filter(lambda f: f.name != '.DS_Store', walk(dirpath))
    counts = [
        len(f.open().readlines()) - 2
        for f in filtered   
    ]
    print(sum(counts))


