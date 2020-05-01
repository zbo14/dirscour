#!/bin/bash

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
    echo "[proc#$1] Exiting"
    exit
  elif ! [[ "$subdomain" =~ [0-9A-Za-z]+ ]]; then
    sleep 1."$RANDOM"
    continue
  fi

  dns="$(dig +short "$subdomain")"

  if [[ "$dns" =~ [0-9A-Za-z]+ ]]; then
    echo "[proc#$1] Scanning \"$subdomain\""

    python3 "$dirsearch" \
      -E \
      -u https://"$subdomain" \
      --plain-text-report="$reports/$subdomain".txt \
      > /dev/null
  fi
done
