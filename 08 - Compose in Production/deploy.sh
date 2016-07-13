#! /usr/bin/env bash
# Simple script to illustrate deploying changes to production

USAGE=$(cat <<USAGE
Usage: $0 <options> <image set>

Execute docker-compose command against a remote host.

Options:

  -h  | --help                Display this message
  -s  | --swarm               Name of swarm master machine (default: swarm-manager)
USAGE
)

while [ $# -gt 0 ]; do
  case "$1" in
    -h | --help)
      echo "$USAGE"; exit 2; shift;;
    -s | --swarm)
      SWARM_MASTER=$2; shift 2;;
    -*) echo "Invalid argument $1"; exit 1;;
    *) break;;
  esac
done

SWARM_MASTER=${SWARM_MASTER:-swarm-manager}

eval $(docker-machine env --swarm $SWARM_MASTER)

docker-compose \
  --file docker-compose.yml \
  --file docker-compose.production.yml \
  $@
