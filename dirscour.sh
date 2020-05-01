#!/bin/bash

usage () {
  echo "USAGE: ./dirscour [OPTIONS] domain"
  echo ""
  echo "OPTIONS:"
  echo "  -h  log usage information and exit"
  echo "  -d  path to dirsearch directory (default: .)"
  echo "  -o  path to output directory (default: .)"
  echo "  -p  number of daemon processes to spawn (default: 20)"
  exit
}

while getopts ":d:ho:p:t:" opt; do
  case ${opt} in
    h)
      usage
      ;;

    d)
      dirsearch="$OPTARG"/dirsearch.py

      if [ ! -f "$dirsearch" ]; then
        echo "Couldn't find file \"$dirsearch\""
        exit 1
      fi
      ;;

    o)
      output="$OPTARG"

      if [ ! -d "$dirsearch" ]; then
        echo "Couldn't find directory \"$output\""
        exit 1
      fi
      ;;

    p)
      nprocs="$OPTARG"

      if ! [[ "$nprocs" =~ ^[0-9]+$ ]]; then
        echo "Expected -p to be an integer"
        exit 1
      elif [ "$nprocs" -lt 1 ]; then
        echo "Expected -p to be greater than/equal to 1"
        exit 1
      fi

      ;;
  esac
done

shift $((OPTIND-1))

if [ -z "$1" ]; then
  echo "No target domain specified"
  exit 1
fi

exit

dirscour="$(dirname "$0")"
cd "$dirscour"

dirsearch=${dirsearch:-$dirscour/dirsearch.py}
nprocs=${nprocs:-20}
output=${output:-$dirscour}
reports="$output"/reports

mkdir -p "$reports"

tmp="$(mktemp -d)"
lock="$tmp"/lock
subdomains="$tmp"/subdomains

cat "$dirscour"/banner.ascii

echo "[main] Dirsearch -> $dirsearch"
echo "[main] Reports   -> $reports"
echo "[main] Tempdir   -> $tmp"

for i in $(seq 1 "$nprocs"); do
  dirsearch="$dirsearch" \
  lock="$lock" \
  reports="$reports" \
  subdomains="$subdomains" \
  ./daemon.sh "$i" &
done

amass enum -passive -d "$1" >> "$subdomains" 2> /dev/null

for _ in $(seq 1 "$nprocs"); do
  echo "done" >> "$subdomains"
done

wait

echo "[main] Cleaning up"

rm -rf "$tmp"
