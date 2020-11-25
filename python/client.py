#!/usr/bin/env python3

import logging
logging.basicConfig(level=logging.INFO)

import asyncio
import websockets

import sys

import json

GAME_PORT=6970

# Maximum time given to the game to acknowledge the
# commands
TIMEOUT=2 #s

if len(sys.argv) < 3:
    print("Usage: %s <robot name> <cmd> [<param1> <param2> ...]" % sys.argv[0])
    sys.exit(1)


msgs_to_game = asyncio.Queue()

cmds = {1: [sys.argv[1], sys.argv[2], [x for x in sys.argv[3:]]]}


for cmd in cmds.items():
    msgs_to_game.put_nowait(cmd)

responses_from_game = asyncio.Queue()
msgs_from_game = asyncio.Queue()

async def send_cmd(websocket, path):
    while True:
        msg = await msgs_to_game.get()
        cmd_id = msg[0]
        logging.info("Sending to server %s" % str(cmd))
        await websocket.send(json.dumps(cmd))
        logging.info("Waiting for response...")
        response = await responses_from_game.get()

        if response[0] == cmd_id:
            logging.info(f"Server responded: %s" % response[1])
        else:
            logging.info("[EE] wrong command id! A command was lost somewhere!")

        #break

async def recv_msgs(websocket, path):
    async for msg in websocket:
        #logging.info(msg)
        if msg != "ack".encode():
            msg = json.loads(msg)

            cmd_id = msg[0]
            if cmd_id > 0: # this the response to a previous cmd
                responses_from_game.put_nowait(msg)
            else: # cmd_id <= 0 -> msg initiated by the game
                logging.info(f"Server says: {msg}")
                msgs_from_game.put_nowait(msg)

async def handler(websocket, path):
    logging.info("Game connected")

    consumer_task = asyncio.ensure_future(recv_msgs(websocket, path))
    producer_task = asyncio.ensure_future(send_cmd(websocket, path))

    done, pending = await asyncio.wait(
            [consumer_task, producer_task],
            return_when=asyncio.FIRST_COMPLETED,
    )

    for task in pending:
        task.cancel()

    logging.info("My job is finished, I can exit!")
    asyncio.get_event_loop().stop()

def handle_exception(loop, context):
    msg = context.get("exception", context["message"])
    logging.error(f"Caught exception: {msg}")
    logging.info("Connection closed by the game (game stopped?). Exiting.")
    loop.stop()

asyncio.get_event_loop().set_exception_handler(handle_exception)

asyncio.get_event_loop().run_until_complete(
                        websockets.serve(handler, "localhost", GAME_PORT)
                        )

logging.info("Started game server on localhost:%s"% GAME_PORT)
asyncio.get_event_loop().run_forever()
