# EOC-Setup

An end-to-end deployment setup for the EOC data portal and associated ELK stack for
local development which tries to replicate the exact workings of the production env.

Note: at the moment its more or less for ELK development as the custom extensions
are pulled in from Github directly. The next step would be to define envvars that
allow the setup use local repositories of target CKAN extensions.

## Running

```bash
# just the CKAN stack
$ ./manage.sh ckan --up

# the ELK stack
$ ./manage.sh elk --up

# the CKAN & ELK stack
# ./manage.sh ckan elk --up
```

## EOC ELK

This is a standalone version of the ELK setup found within `ckan_setup/elk`. This is
meant to provide a quick and easy way to test stuff out and working changes are then
to be effected to the original setup.
