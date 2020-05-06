#!/bin/bash

usage () {
  echo "USAGE: ./dirscour [OPTIONS] <domain/@file>"
  echo ""
  echo "OPTIONS:"
  echo "  -h  log usage information and exit"
  echo "  -c  run in Docker container"
  echo "  -d  path to dirsearch directory"
  echo "  -o  path to output directory"
  echo "  -p  number of daemon processes to spawn (default: 20)"
  exit
}

while getopts ":cd:ho:p:" opt; do
  case ${opt} in
    h)
      usage
      ;;

    c)
      containerize=1
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

      if [ ! -d "$output" ]; then
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
  echo "No target domains specified"
  exit 1
elif [[ "$1" == @* ]]; then
  filename="$(realpath "$(echo "$1" | cut -c 2-)")"

  if [ ! -f "$filename" ]; then
    echo "Couldn't find file \"$filename\""
    exit 1
  fi
fi

dirscour="$(realpath "$(dirname "$0")")"
nprocs=${nprocs:-20}
output=${output:-$dirscour}

cd "$dirscour"

if [ ! -z "$containerize" ]; then
  [ "[]" == "$(docker inspect --type=image dirscour 2> /dev/null)" ] &&
    docker build --no-cache -t dirscour .

  if [ -z "$filename" ]; then
    docker run \
    -e nprocs="$nprocs" \
    -e target="$1" \
    --rm \
    -v "$output":/dirscour/output \
    dirscour
  else
    docker run \
    -e nprocs="$nprocs" \
    -e target=@/dirscour/domains \
    --rm \
    -v "$filename":/dirscour/domains \
    -v "$output":/dirscour/output \
    dirscour
  fi

  exit "$?"
fi

dirsearch=${dirsearch:-$dirscour/dirsearch.py}
output=${output:-$dirscour}
reports="$output"/reports

mkdir -p "$reports"

tmp="$(mktemp -d)"
lock="$tmp"/lock
subdomains="$tmp"/subdomains

touch "$subdomains"

cat "$dirscour"/banner.ascii

echo "[main] Starting daemon processes"

for i in $(seq 1 "$nprocs"); do
  dirsearch="$dirsearch" \
  lock="$lock" \
  reports="$reports" \
  subdomains="$subdomains" \
  ./daemon.sh "$i" &
done

if [ -z "$filename" ]; then
  echo "[main] Starting subdomain discovery of \"$1\""
  amass enum -passive -d "$1" >> "$subdomains" 2> /dev/null
  echo "[main] Finished subdomain discovery"
else
  cat "$filename" > "$subdomains"
fi

for _ in $(seq 1 "$nprocs"); do
  echo "done" >> "$subdomains"
done

wait

echo "[main] Cleaning up"

rm -rf "$tmp"
