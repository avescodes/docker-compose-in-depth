#! /usr/bin/env bash
# Set up a Docker Swarm cluster of 3 nodes on Digital Ocean.
#
# Inspired by: https://docs.docker.com/swarm/provision-with-machine/

set -e

USAGE=$(cat <<USAGE
Usage: $0 <options>

Provision a 3-node Docker Swarm cluster with VirtualBox or Digital Ocean ($$)

Options:

  -h  | --help                Display this message
  -d  | --digital-ocean-token Use Digital Ocean; API token (or use DIGITALOCEAN_ACCESS_TOKEN)
  -c  | --cleanup             Do not provision any machines (flag).
                              Cleans up any that have been provisioned

Additional options:

 - DRIVER_OPTS - Used to specify additional arguments to docker-machine create
USAGE
)

while [ $# -gt 0 ]; do
  case "$1" in
    -h | --help)
      echo "$USAGE"; exit 2; shift;;
    -d | --digital-ocean-token)
      DIGITALOCEAN_ACCESS_TOKEN=$2; shift 2;;
    -c | --cleanup)
      CLEANUP=1; shift 1;;
    -*) echo "Invalid argument $1"; exit 1;;
    *) break;;
  esac
done

if [ -n "$CLEANUP" ]; then
  set +e
  docker-machine rm -f swarm-manager node-01 node-02 consul
  exit 0
fi

if [ -n "$DIGITALOCEAN_ACCESS_TOKEN" ]; then
  echo "Provisioning Swarm on Digital Ocean"
  export DIGITALOCEAN_ACCESS_TOKEN=$DIGITALOCEAN_ACCESS_TOKEN
  export MACHINE_DRIVER=digitalocean
else
  echo "Provisioning Swarm with VirtualBox"
  export MACHINE_DRIVER=virtualbox
fi

create_and_launch_consul () {
  docker-machine create consul

  eval $(docker-machine env consul)

  docker run --detach \
    --name consul \
    --publish "8500:8500" \
    --hostname "consul" \
    progrium/consul -server -bootstrap

  # Wait for port 8500 to be open
  docker run --link consul --rm martin/wait
}

create_machine () {
  docker-machine create \
    --swarm \
    --swarm-discovery "consul://$(docker-machine ip consul):8500"  \
    --engine-opt "cluster-store=consul://$(docker-machine ip consul):8500" \
    --engine-opt "cluster-advertise=eth1:2376" \
    $@
}

set -x

create_and_launch_consul

create_machine --swarm-master swarm-manager
create_machine "node-01"
create_machine "node-02"

docker-machine env --swarm swarm-manager
