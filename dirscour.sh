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
  echo "  -w  wordlist for web path discovery (default: <dirsearch>/db/dicc.txt)"
  exit
}

dirscour="$(realpath "$(dirname "$0")")"
cd "$dirscour"

while getopts ":cd:ho:p:w:" opt; do
  case ${opt} in
    h)
      usage
      ;;

    c)
      containerize=1
      ;;

    d)
      dirsearch="$(realpath "$OPTARG")"

      if [ ! -d "$dirsearch" ]; then
        echo "Couldn't find dirsearch directory \"$dirsearch\""
        exit 1
      elif [ ! -f "$dirsearch"/dirsearch.py ]; then
        echo "No dirsearch.py file in directory"
        exit 1
      fi
      ;;

    o)
      output="$(realpath "$OPTARG")"

      if [ ! -d "$output" ]; then
        echo "Couldn't find output directory \"$output\""
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

    w)
      wordlist="$(realpath "$OPTARG")"

      if [ ! -f "$wordlist" ]; then
        echo "Couldn't find wordlist \"$wordlist\""
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
elif [ -z "$output" ]; then
  echo "No output directory specified"
  exit 1
fi

nprocs=${nprocs:-20}
reports="$output"/reports

mkdir -p "$reports"

if [ ! -z "$containerize" ]; then
  [ "[]" == "$(docker inspect --type=image dirscour 2> /dev/null)" ] &&
    docker build --no-cache -t dirscour .

  if [ -z "$filename" ]; then
    if [ -z "$wordlist" ]; then
      docker run \
        -e nprocs="$nprocs" \
        -e target="$1" \
        -e wordlist=/dirscour/dirsearch/db/dicc.txt \
        --rm \
        -v "$output":/dirscour/output \
        dirscour
    else
      docker run \
        -e nprocs="$nprocs" \
        -e target="$1" \
        -e wordlist=/dirscour/wordlist \
        --rm \
        -v "$output":/dirscour/output \
        -v "$wordlist":/dirscour/wordlist:ro \
        dirscour
    fi
  elif  [ -z "$wordlist" ]; then
    docker run \
      -e nprocs="$nprocs" \
      -e target=@/dirscour/domains \
      -e wordlist=/dirscour/dirsearch/db/dicc.txt \
      --rm \
      -v "$filename":/dirscour/domains \
      -v "$output":/dirscour/output \
      dirscour
  else
    docker run \
      -e nprocs="$nprocs" \
      -e target=@/dirscour/domains \
      -e wordlist=/dirscour/wordlist \
      --rm \
      -v "$filename":/dirscour/domains \
      -v "$output":/dirscour/output \
      -v "$wordlist":/dirscour/wordlist:ro \
      dirscour
  fi

  exit "$?"
elif [ -z "$dirsearch" ]; then
  echo "No dirsearch directory specified"
  exit 1
fi

tmp="$(mktemp -d)"
lock="$tmp"/lock
subdomains="$tmp"/subdomains
wordlist=${wordlist:-"$dirsearch"/db/dicc.txt}

touch "$subdomains"

cat "$dirscour"/banner

echo "[main] Starting daemon processes"

for i in $(seq 1 "$nprocs"); do
  dirsearch="$dirsearch" \
  lock="$lock" \
  reports="$reports" \
  subdomains="$subdomains" \
  wordlist="$wordlist" \
  bash daemon.sh "$i" &
done

if [ -z "$filename" ]; then
  echo "[main] Starting subdomain discovery of \"$1\""
  amass enum -passive -d "$1" >> "$subdomains" 2> /dev/null
  echo "[main] Finished subdomain discovery"
else
  echo "[main] Scanning domains in file"
  cp "$filename" "$subdomains"
fi

for _ in $(seq 1 "$nprocs"); do
  echo "done" >> "$subdomains"
done

wait

echo "[main] Cleaning up"

rm -rf "$tmp"

echo "[main] Done!"
