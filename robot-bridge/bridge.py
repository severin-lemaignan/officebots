#!/usr/bin/env python

# WS client example

import asyncio
import websockets

import json

#CMD = ["navigate-to", (3.7, 11.4,0)]
CMD = ["navigate-to", (4, 1.4,0)]

async def send_cmd(cmd):
    uri = "ws://localhost:6970"

    async with websockets.connect(uri) as websocket:

        cmd_str = json.dumps(cmd)
        print(f"Sending cmd: {cmd_str}")
        await websocket.send(cmd_str)

        ack = await websocket.recv()
        print(f"Server says: {ack}")

asyncio.get_event_loop().run_until_complete(send_cmd(CMD))
