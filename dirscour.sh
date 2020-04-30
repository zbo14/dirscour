#!/bin/bash

if [ -z "$1" ]; then
  echo 'Usage: dirscour <domain> [nprocs]'
  exit 1
fi

cd "$(dirname "$0")"

cat banner.ascii

nprocs=${2:-20}

mkdir -p reports tmp

cd tmp
rm -f lock

for i in $(seq 1 "$nprocs"); do
  ../proc.sh "$i" &
done

amass enum -passive -d "$1" >> subdomains 2> /dev/null

for _ in $(seq 1 "$nprocs"); do
  echo "done" >> subdomains
done

wait

cd ..
rm -rf tmp
