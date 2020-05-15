#!/bin/bash

cd "$(dirname "$0")"

docker build --no-cache -t dirscour .

sudo cp dirscour /usr/local/bin
