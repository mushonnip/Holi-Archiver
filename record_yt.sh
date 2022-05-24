#!/bin/bash
# YouTube Live Stream Recorder

while getopts q:t:c flag; do
  case $flag in
    q) QUALITY=${OPTARG};;
    t) TASK=${OPTARG};;
    c) COOKIES=${OPTARG};;
    ?) echo "Usage: $0 [-q quality] [-t task] [-c cookies]" exit 1;;
  esac
done

if [[ ! -n "$1" ]]; then
  echo "Usage: $0 youtube_channel_id [-q quality] [-t task] [-c cookies]"
  exit 1
fi

# Change to your own API key
# https://holodex.stoplight.io/docs/holodex/ZG9jOjQ2Nzk1-getting-started#obtaining-api-key
HOLODEX_APIKEY="da5a0e83-be4a-4d06-8e9f-9e0b1b8119a7"

# Default values
CH_ID=$1
if [[ -z "$QUALITY" ]]; then
  QUALITY="best"
fi
if [[ -z "$TASK" ]]; then
  TASK="once"
fi
if [[ -n "$COOKIES" ]]; then
  COOKIES="-c $COOKIES"
fi

# Check if given id is not a custom channel id
if [[ $CH_ID != UC* ]]; then
  CH_URL="https://www.youtube.com/c/$CH_ID"
else
  CH_URL="https://www.youtube.com/channel/$CH_ID"
fi

while true; do
  # Use ytarchive to record the stream
  ./bin/ytarchive --monitor-channel --write-description --write-thumbnail --merge $COOKIES -o '%(channel)s/%(upload_date)s_%(title)s' $CH_URL/live $QUALITY

  # Exit if we just need to record current stream
  echo "Live stream recording stopped."
  [[ "$TASK" == "once" ]] && exit 1
done