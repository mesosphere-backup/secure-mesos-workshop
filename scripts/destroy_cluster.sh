#!/bin/bash

set -xe

docker stop $(docker ps -aq)

rm -rf log tmp ssl
