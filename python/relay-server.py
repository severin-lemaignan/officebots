#!/usr/bin/env python3


import asyncio
import websockets

import sys

import json

GAME_PORT=6971
API_PORT=6970

# Maximum time given to the game to acknowledge the
# commands
TIMEOUT=2 #s

if len(sys.argv) != 1:
    print("Usage: %s" % sys.argv[0])
    sys.exit(1)

cmd_to_send_game = asyncio.Queue()
cmd_to_send_bridge = asyncio.Queue()

async def python_bridge_server(websocket, path):
    cmd = await websocket.recv()
    print(cmd)
    cmd_to_send_bridge.put_nowait(cmd)

    # wait for the response from the game
    # TODO: can get stuck here, waiting for the server to answer
    # would be better to have an independant task 
    # waiting for server's response, and sending them asap
    try:
        response = await asyncio.wait_for(cmd_to_send_game.get(), timeout=TIMEOUT)

        print("Sending back %s " % response)
        await websocket.send(response)

    except asyncio.TimeoutError:
        print("[EE] Server is not responding!")
        await websocket.send(json.dumps(["EE", "game timeout"]))



async def robot_server(websocket, path):
    print("Got a connection")
    while True:
        response = await websocket.recv()
        print(response)
        if response != "ping".encode():
            cmd_to_send_bridge.put_nowait(response)

        if not cmd_to_send_game.empty():
            cmd = cmd_to_send_game.get_nowait()
            print("Sending to server %s" % cmd)

            await websocket.send(cmd)


game_server = websockets.serve(robot_server, "localhost", GAME_PORT)
bridge_server = websockets.serve(python_bridge_server, "localhost", API_PORT)

asyncio.get_event_loop().run_until_complete(game_server)
asyncio.get_event_loop().run_until_complete(bridge_server)

print("Websocket relay server")
print("Started game server on localhost:%s"% GAME_PORT)
print("Started API server on localhost:%s"% API_PORT)
asyncio.get_event_loop().run_forever()
