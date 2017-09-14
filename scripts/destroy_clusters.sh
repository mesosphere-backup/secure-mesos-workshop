#!/bin/bash

set -e

docker stop $(docker ps -aq)

if [ `uname` = "Linux" ]; then
  sudo rm -rf log tmp ssl
else
  rm -rf log tmp ssl
fi
