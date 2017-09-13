#!/bin/bash

set -e

docker stop $(docker ps -aq)

rm -rf log tmp ssl
