#!/bin/bash
# YouTube Live Stream Recorder

while getopts q:t:i:c flag; do
  case $flag in
    q) QUALITY=${OPTARG};;
    t) TASK=${OPTARG};;
    i) INTERVAL=${OPTARG};;
    c) COOKIES=${OPTARG};;
    ?) echo "Usage: $0 [-q quality] [-t task] [-i interval] [-c cookies]" exit 1;;
  esac
done

if [[ ! -n "$1" ]]; then
  echo "Usage: $0 youtube_channel_id [-q quality] [-t task] [-i interval] [-c cookies]"
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
if [[ -z "$INTERVAL" ]]; then
  INTERVAL=30
fi
if [[ -n "$COOKIES" ]]; then
  COOKIES="-c $COOKIES"
fi

# Check if given id is not a custom channel id
if [[ $CH_ID != UC* ]]; then
  CH_ID=$(wget -qO- https://www.youtube.com/c/$CH_ID | grep -oP '<meta itemprop="channelId" content="\K.*?(?=")')
fi

while true; do
  # Monitor live streams of specific channel
  while true; do
    
    LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]")
    echo "$LOG_PREFIX Checking \"$CH_ID\" using Holodex API..."

    # Check if live stream available with wget    
    METADATA="$(wget --header="X-APIKEY: ${HOLODEX_APIKEY}" --header="Content-Type: application/json" -qO - https://holodex.net/api/v2/users/live\?channels=${CH_ID} | jq -r '.[] | select(.channel.id=="'${CH_ID}'") | select(.status == "live")')"
    [[ "$METADATA" != "" ]] && break

    echo "$LOG_PREFIX The stream is not available now."
    echo "$LOG_PREFIX Retry after $INTERVAL seconds..."
    sleep $INTERVAL
  done

  # Extract video id of live stream
  ID=$(echo "$METADATA" | jq -r '.id')

  # Use ytarchive to record the stream
  ./bin/ytarchive --wait --merge --write-description --write-thumbnail $COOKIES -o '%(channel)s/%(upload_date)s_%(title)s' https://www.youtube.com/watch\?v\=$ID $QUALITY

  # Exit if we just need to record current stream
  echo "Live stream recording stopped."
  [[ "$TASK" == "once" ]] && break
done