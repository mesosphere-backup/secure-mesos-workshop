#!/bin/bash
set -e

# This script starts a simple mesos cluster (1 master, 1 agent and 1 zookeeper)
# using docker images.

# Destroy any old clusters first.
./destroy_clusters.sh

# Start ZooKeeper via Exhibitor.
docker run -d --net=host netflixoss/exhibitor:1.5.2

# Start Mesos master.
docker run -d --net=host \
  -e MESOS_PORT=5050 \
  -e MESOS_ZK=zk://127.0.0.1:2181/mesos \
  -e MESOS_QUORUM=1 \
  -e MESOS_REGISTRY=in_memory \
  -e MESOS_LOG_DIR=/var/log/mesos \
  -e MESOS_WORK_DIR=/var/tmp/mesos \
  -v "$(pwd)/log/mesos:/var/log/mesos" \
  -v "$(pwd)/tmp/mesos:/var/tmp/mesos" \
  mesosphere/mesos-master:1.4.0-rc5

# Start Mesos agent.
docker run -d --net=host --privileged \
  -e MESOS_PORT=5051 \
  -e MESOS_MASTER=zk://127.0.0.1:2181/mesos \
  -e MESOS_SWITCH_USER=0 \
  -e MESOS_LOG_DIR=/var/log/mesos \
  -e MESOS_WORK_DIR=/var/tmp/mesos \
  -e MESOS_SYSTEMD_ENABLE_SUPPORT=0 \
  -v "$(pwd)/log/mesos:/var/log/mesos" \
  -v "$(pwd)/tmp/mesos:/var/tmp/mesos" \
  mesosphere/mesos-slave:1.4.0-rc5
