#!/usr/bin/env python

# WS client example

import asyncio
import websockets

import sys

import json

if len(sys.argv) < 3:
    print("Usage: bridge.py <cmd> <robot name> [<param1> <param2> ...]")
    sys.exit(1)

async def send_cmd():
    uri = "ws://localhost:6970"

    async with websockets.connect(uri) as websocket:

        cmd_str = json.dumps([sys.argv[1], sys.argv[2], [x for x in sys.argv[3:]]])
        print(f"Sending cmd: {cmd_str}")
        await websocket.send(cmd_str)

        ack = await websocket.recv()
        ack = json.loads(ack)
        print(f"Server says: {ack}")

asyncio.get_event_loop().run_until_complete(send_cmd())
