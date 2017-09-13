#!/bin/bash

set -e

docker stop $(docker ps -aq)

sudo rm -rf log tmp ssl
