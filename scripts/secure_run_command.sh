#!/bin/bash

set -e

docker run --net=host \
  -e LIBPROCESS_SSL_ENABLED=1 \
  -e LIBPROCESS_SSL_CERT_FILE=/etc/ssl/cert.pem \
  -e LIBPROCESS_SSL_KEY_FILE=/etc/ssl/key.pem \
  -v "$(pwd)/ssl:/etc/ssl" \
  mesosphere/mesos:1.4.0-rc5 \
  mesos-execute \
    --master=zk://127.0.0.1:2181/mesos \
    --name=foo \
    --env="{
            \"LIBPROCESS_SSL_ENABLED\":\"1\",
            \"LIBPROCESS_SSL_SUPPORT_DOWNGRADE\":\"0\",
            \"LIBPROCESS_SSL_CERT_FILE\":\"/etc/ssl/cert.pem\",
            \"LIBPROCESS_SSL_KEY_FILE\":\"/etc/ssl/key.pem\"
           }" \
    --command=env
