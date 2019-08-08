# dtrctl

This is a tool that can pull orgs, teams, and team memberships from one DTR. And then push them to another DTR.

Over time I will add more functionality.

Please keep in mind that they script will create a `INFO` directory with the data. Please remove it when done.

## conf.env

Please copy `conf.env.sample` to `conf.env` and modify for you clusters.

## Usage

### GET

```bash
clemenko@clemenko dtrctl % ./dtrctl.sh get
-- get --
 getting an auth token  [ok]
 getting orgList  [ok]
 getting teams of orgs  [ok]
 getting users of teams  [ok]
```

### PUSH

```bash
clemenko@clemenko dtrctl % ./dtrctl.sh push
-- push --
 getting an auth token  [ok]
 creating orgs  [ok]
 creating teams and adding users  [ok]
```

## Configuration file example

```bash
## PARAMETERS to reach the SOURCE DTR - GET
export SRC_UCP_URL=
export SRC_DTR_URL=
export SRC_DTR_USER=
export SRC_DTR_PASSWORD=

## PARAMETERS to reach the DESTINATION DTR - PUSH
export DST_UCP_URL
export DST_DTR_URL=
export DST_DTR_USER=
export DST_DTR_PASSWORD=
```
