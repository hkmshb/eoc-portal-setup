# EOC Setup

This repository provides scripts and a code structure that simplifies CKAN extension
development for the EOC Data Portal and eases the development environment setup. The
target EOC CKAN extensions for local development are:

* [ckanext-eoc](https://github.com/eHealthAfrica/ckanext-eoc)
* [gather2_integration](https://github.com/eHealthAfrica/gather2_integration)

## Setup

### Step 1: Fetch Codes

Begin by issuing the command below. This creates a `.env.local` file if it does not
already exist then terminates.

```bash
# creates .env.local file on first run if missing
$ make init
```

Edit the `.env.local` file and replace all `<required>` placeholers with appropriate
values; these environment variabls are necessary for a proper CKAN setup and build.
The `GITHUB_TOKEN` variable is required for accessing private code repositories like
`ckanext-eoc` necessary for a complete and functional CKAN build.

Issue the command above again if the initial run created the `.env.local` file. This
will fetch necessary code repositories (CKAN and EOC ckan extensions), then initial
docker image builds for services defined within the `docker-compose.yml` file.

### Step 2: Create Python egg for EOC Extensions

The local Docker setup uses a mapped volume for the `ckan` service to watch and effect
local change to the EOC extensions within a running container. However, due to this
mapping installing these extensions from within Docker has no effect; they end up being
reported missing.

To solve this a *pseudo-install* needs to happen by creating a Python egg packages for
these extensions outside of Docker. These eggs carry into the container via the mapping
and these packages are taken to be installed.

```bash
# create and activte a temporary virtualenv (using pyenv)
$ pyenv virtualenv -p python2 ckan-eoc
$ pyenv activate ckan-eoc

# 'pseudo-install' extensions
(ckan-eoc) $ cd src/extentions
(ckan-eoc) $ pip install -e ckanext-eoc/.
(ckan-eoc) $ pip install -e gather2_integration/.

# drop created virtualenv
(ckan-eoc) $ pyenv deactivate
$ pyenv uninstall ckan-eoc
```

## Run
s
To run the local EOC Data Portal setup:

```bash
$ make run
```