#!/bin/bash
# YouTube Live Stream Recorder

# $1 = YouTube Channel ID
# $2 = Stream quality
# $3 = Loop or Once

if [[ ! -n "$1" ]]; then
  echo "usage: $0 youtube_channel_id|live_url [format] [loop|once] [interval]"
  exit 1
fi

# Change to your own API key
# https://holodex.net/
HOLODEX_APIKEY="da5a0e83-be4a-4d06-8e9f-9e0b1b8119a7"

CH_ID=$1
LIVE_URL="https://www.youtube.com/channel/$CH_ID/live"

# Record the highest quality available by default
FORMAT="${2:-best}"
INTERVAL="${4:-10}"

while true; do
  # Monitor live streams of specific channel
  while true; do
    
    LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]")
    echo "$LOG_PREFIX Checking \"$LIVE_URL\" using Holodex API..."

    # Check if live stream available with wget
    LIVE_CHECKER=$(curl -s --request GET --url https://holodex.net/api/v2/users/live\?channels=$CH_ID \
     --header "X-APIKEY: ${HOLODEX_APIKEY}" \
     --header "Content-Type: application/json")
    
    [[ "$LIVE_CHECKER" != "[]" ]] && break

    echo "$LOG_PREFIX The stream is not available now."
    echo "$LOG_PREFIX Retry after $INTERVAL seconds..."
    sleep $INTERVAL
  done

  # Extract video id of live stream
  ID=$(echo "$LIVE_CHECKER" | jq -r '.[0].id')

  # Record using MPEG-2 TS format to avoid broken file caused by interruption
  FNAME="youtube_${ID}_$(date +"%Y%m%d_%H%M%S").ts"
  # Also save the metadate to file
  echo "$METADATA" > "$FNAME.info.txt"

  # Print logs
  echo "$LOG_PREFIX Start recording, metadata saved to \"$FNAME.info.txt\"."
  echo "$LOG_PREFIX Use command \"tail -f $FNAME.log\" to track recording progress."

  # Use streamlink to record for HLS seeking support
  streamlink --hls-live-restart --loglevel trace -o "$FNAME" \
    "https://www.youtube.com/watch?v=${ID}" "$FORMAT" > "$FNAME.log" 2>&1

  # Exit if we just need to record current stream
  LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]")
  echo "$LOG_PREFIX Live stream recording stopped."
  [[ "$3" == "once" ]] && break
done