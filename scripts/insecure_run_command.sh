#!/bin/bash

set -e

docker run --net=host \
  -e LIBPROCESS_IP=127.0.0.1 \
  mesosphere/mesos:1.4.0-rc5 \
  mesos-execute \
    --master=zk://127.0.0.1:2181/mesos \
    --name=foo \
    --command=env
