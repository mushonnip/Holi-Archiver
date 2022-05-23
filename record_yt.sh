#!/bin/bash
# YouTube Live Stream Recorder

# $1 = YouTube Channel ID
# $2 = Stream quality
# $3 = Loop or Once

if [[ ! -n "$1" ]]; then
  echo "usage: $0 youtube_channel_id [format] [loop|once] [interval]"
  exit 1
fi

# Change to your own API key
# https://holodex.stoplight.io/docs/holodex/ZG9jOjQ2Nzk1-getting-started#obtaining-api-key
HOLODEX_APIKEY="da5a0e83-be4a-4d06-8e9f-9e0b1b8119a7"

CH_ID=$1

# Check if given id is not a custom channel id
if [[ $CH_ID != UC* ]]; then
  CH_ID=$(wget -qO- https://www.youtube.com/c/$CH_ID | grep -oP '<meta itemprop="channelId" content="\K.*?(?=")')
fi

# Record the highest quality available by default
FORMAT="${2:-best}"
INTERVAL="${4:-10}"

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
  ./bin/ytarchive --wait --merge -o '%(channel)s/%(upload_date)s_%(title)s' https://www.youtube.com/watch\?v\=$ID best

  # Exit if we just need to record current stream
  echo "Live stream recording stopped."
  [[ "$3" == "once" ]] && break
done