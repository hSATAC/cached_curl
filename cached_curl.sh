#!/usr/bin/env bash
set -euo pipefail

command -v curl >/dev/null 2>&1 || { echo >&2 "Require 'curl'"; exit 1; }
command -v md5sum >/dev/null 2>&1 || command -v md5 >/dev/null 2>&1 || { echo >&2 "Require 'md5' or 'md5sum'"; exit 1; }

function print_usage() {
  >&2 echo "Usage: `basename $0` [FILENAME] [URL]"
  >&2 echo "    -D          : Print the debug message"
}

while getopts "D" OPT; do
  case $OPT in
    D)
      DEBUG=true
      ;;
    ?)
      print_usage
      exit 1;
      ;;
  esac
done

DEBUG=${DEBUG:-false}
if $DEBUG ; then
  set -x
fi

shift $((OPTIND-1))
if [ $# -ne 2 ]; then
  print_usage
  exit 1
fi

target=$1
url=$2

# detect md5 command
command -v md5sum >/dev/null 2>&1 && MD5_CMD=md5sum
MD5_CMD=${MD5_CMD:-md5}

# create temp folder
tmpdir="$(dirname $(mktemp -u))/cached_curl"
mkdir -p $tmpdir

# md5sum will print trailing - symbol, we have to get rid of it.
md5=$(echo -n $url | $MD5_CMD | cut -d ' ' -f 1)

FILE=$tmpdir/$md5

if [ ! -f "$FILE" ]; then
  # if this script get interrupted while downloading
  # there may be corrupted cache file remaining, we'd better rm it.
  trap "rm $FILE >/dev/null 2>&1" INT

  # get the file if cache not exists
  curl -sLo $FILE $url
else
  echo "Cache found: $FILE"
fi

# copy cached file to target
cp $FILE $target
