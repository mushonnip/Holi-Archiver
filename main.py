import websocket
import json
import threading
import time
import os
from dotenv import load_dotenv
import subprocess

load_dotenv()

def send_json_request(ws, request):
    ws.send(json.dumps(request))

def receive_json_response(ws):
    response = ws.recv()
    if response:
        return json.loads(response)

def heartbeat(interval, ws):
    print("heartbeat begin")
    while(True):
        time.sleep(interval)
        heartbeatJSON={
            "op": 1,
            "d": "null"
        }
        send_json_request(ws, heartbeatJSON)
        print("heartbeat sent")

ws=websocket.WebSocket()
ws.connect("wss://gateway.discord.gg/?v=6&encoding=json")
event=receive_json_response(ws)

heartbeat_interval = event["d"]["heartbeat_interval"] / 1000
threading._start_new_thread(heartbeat, (heartbeat_interval, ws))

token=os.getenv("DISCORD_TOKEN")
payload={
    'op': 2,
    "d": {
        "token": token,
        "properties": {
            "$os": "linux",
            "$browser": "Firefox",
            "$device": "PC"
        },
    }
}
send_json_request(ws, payload)

while(True):
    event=receive_json_response(ws)
    try:
        command = "echo '" + event["d"]["content"] + "'; ./bin/ytarchive --write-description --write-thumbnail --merge -o '%(channel)s/%(upload_date)s_%(title)s' "+ event["d"]["content"]+" best"
        subprocess.run(command, shell=True)
        op_code = event('op')
        if op_code == 11:
            print("heartbeat received")
    except:
        pass