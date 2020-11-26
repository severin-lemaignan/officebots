#!/usr/bin/env python3

import logging
logger = logging.getLogger(__name__)
print(__name__)
import asyncio
import websockets


import json



class OfficeBots:

    GAME_PORT=6970

    MAX_BUFFERED_MESSAGES = 1000

    # Maximum time given to the game to acknowledge the
    # commands
    TIMEOUT=2 #s

    OK = "OK"
    ERROR = "EE"

    TIMEOUT_ERROR = [ERROR, "timeout"]
    CMD_ID_ERROR = [ERROR, "server response lost! (likely network issue)"]

    def __init__(self):
        self.cmd_id = 1

        self.msgs_to_game = asyncio.Queue()

        self.responses_from_game = asyncio.Queue()
        self.msgs_from_game = asyncio.Queue(maxsize = self.MAX_BUFFERED_MESSAGES)

        self.last_response = asyncio.Queue(maxsize=1)

    def stop(self):
        asyncio.get_event_loop().stop()

    def run(self, controller):
        asyncio.get_event_loop().set_exception_handler(self._handle_exception)

        asyncio.get_event_loop().run_until_complete(
                        websockets.serve(self._handler, "localhost", self.GAME_PORT)
                        )

        logger.info("Started OfficeBots Python API, listening for the game to connect on localhost:%s"% self.GAME_PORT)

        try:
            asyncio.get_event_loop().run_until_complete(controller())
        except RuntimeError: # Event loop stopped before Future completed
            logging.error("Controller interrupted due to game disconnection")

        asyncio.get_event_loop().run_forever()

    async def execute(self, cmd):

        self.last_reponse = None
        self.msgs_to_game.put_nowait((self.cmd_id, cmd))
        self.cmd_id += 1

        logger.debug("Waiting for response...")
        return await self.last_response.get()


    async def _send_cmd(self, websocket, path):
        while True:
            msg = await self.msgs_to_game.get()
            cmd_id, cmd = msg
            logger.debug("Sending to server %s" % str(cmd))
            await websocket.send(json.dumps(msg))
            try:
                response_id, response = await asyncio.wait_for(self.responses_from_game.get(), timeout=self.TIMEOUT)
            except TimeoutError:
                logger.error(f"Game timeout while waiting for response to cmd <%s>!" % cmd)
                self.last_response.put_nowait(self.TIMEOUT_ERROR)


            if response_id == cmd_id:
                logger.debug(f"Game responded: %s" % response)
                self.last_response.put_nowait(response)
            else:
                logger.error("Wrong command id! The game response to <%s> was lost somewhere!" % cmd)
                self.last_response.put_nowait(self.CMD_ID_ERROR)



        #break

    async def _recv_msgs(self, websocket, path):
        async for msg in websocket:
            #logger.info(msg)
            if msg != "ack".encode():
                msg = json.loads(msg)

                cmd_id = msg[0]
                if cmd_id > 0: # this the response to a previous cmd
                    self.responses_from_game.put_nowait(msg)
                else: # cmd_id <= 0 -> msg initiated by the game
                    logger.info(f"Recevied game-initiated msg: {msg}")

                    if self.msgs_from_game.full():
                        self.msgs_from_game.get_nowait()
                    self.msgs_from_game.put_nowait(msg)

    async def _handler(self, websocket, path):
        logger.info("Game connected")

        consumer_task = asyncio.ensure_future(self._recv_msgs(websocket, path))
        producer_task = asyncio.ensure_future(self._send_cmd(websocket, path))

        done, pending = await asyncio.wait(
                [consumer_task, producer_task],
                return_when=asyncio.FIRST_COMPLETED,
        )

        for task in pending:
            task.cancel()

    def _handle_exception(self, loop, context):
        msg = context.get("exception", context["message"])
        logger.error(f"Caught exception: {msg}")
        logger.info("Connection closed by the game (game stopped?). Exiting.")
        loop.stop()

