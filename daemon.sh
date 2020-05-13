#!/bin/bash

id="$1"

if [ "$1" -lt 10 ]; then
  id=0"$id"
fi

while true; do
  while true; do
    mkdir "$lock" 2> /dev/null && break
    sleep 1."$RANDOM"
  done

  subdomain="$(head -1 "$subdomains")"
  newsubdomains="$(tail -n +2 "$subdomains")"
  echo "$newsubdomains" > "$subdomains"

  rm -rf "$lock"

  if [ "$subdomain" == "done" ]; then
    exit
  elif ! [[ "$subdomain" =~ [0-9A-Za-z]+ ]]; then
    sleep 1."$RANDOM"
    continue
  fi

  dns="$(dig +short "$subdomain")"

  if [[ "$dns" =~ [0-9A-Za-z]+ ]]; then
    echo "[p#$id] Scanning \"$subdomain\""

    python3 "$dirsearch"/dirsearch.py \
      -E \
      -u https://"$subdomain" \
      --plain-text-report="$reports/$subdomain".txt \
      -w "$wordlist" \
      > /dev/null

    echo "[p#$id] Finished \"$subdomain\""
  fi
done
