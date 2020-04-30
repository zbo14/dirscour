#!/bin/bash

cd "$(dirname "$0")"/tmp

while true; do
  ../acquire-lock.js "$1"
  echo "[proc#$1] Acquired lock"
  subdomain="$(head -1 subdomains)"
  newsubdomains="$(tail -n +2 subdomains)"
  echo "$newsubdomains" > subdomains
  echo "[proc#$1] Released lock"
  rm -f lock

  if [ "$subdomain" == "done" ]; then
    echo "[proc#$1] Exiting"
    exit
  elif ! [[ "$subdomain" =~ [0-9A-Za-z]+ ]]; then
    echo "[proc#$1] Waiting"
    sleep 3
    continue
  fi

  echo "[proc#$1] Read subdomain \"$subdomain\""

  dns="$(dig +short "$subdomain")"

  if [[ "$dns" =~ [0-9A-Za-z]+ ]]; then
    echo "[proc#$1] Scanning web paths for \"$subdomain\""

    python3 ~/Projects/dirsearch/dirsearch.py \
      -E \
      -u https://"$subdomain" \
      --plain-text-report=../reports/"$subdomain".txt \
      > /dev/null

    echo "[proc#$1] Done scanning web paths for \"$subdomain\""
  fi
done
