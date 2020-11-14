#!/usr/bin/env python3

import sys
import base64
import asyncio
import websockets
import pathlib
import json

if len(sys.argv) < 3:
    print("Usage: send_image.py <robot name> <path to jpg>")
    sys.exit(1)

img_path = pathlib.Path(sys.argv[2])

if not img_path.exists():
    print("No image " + sys.argv[2])
    sys.exit(1)

with open(img_path, 'rb') as img:
    raw = img.read()

b64 = base64.b64encode(raw).decode("ascii")

async def send_cmd():
    uri = "ws://localhost:6970"

    async with websockets.connect(uri) as websocket:

        cmd_str = json.dumps(["server", "load-jpg", [img_path.name, b64]])
        print(f"Sending image to the server...")
        await websocket.send(cmd_str)

        ack = await websocket.recv()
        ack = json.loads(ack)

        if ack[0] != 'OK':
            print("Image uploading failed! " + ack[1])
            sys.exit(1)

        print("Image successfully loaded. Setting it on robot " + sys.argv[1])
        cmd_str = json.dumps([sys.argv[1], "set-screen", [img_path.name]])
        await websocket.send(cmd_str)

        ack = await websocket.recv()
        ack = json.loads(ack)

        if ack[0] != 'OK':
            print("Error while setting the image: " + ack[1])
            sys.exit(1)

asyncio.get_event_loop().run_until_complete(send_cmd())
