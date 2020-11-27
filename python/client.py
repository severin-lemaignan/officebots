#!/usr/bin/env python3

import logging
logging.basicConfig(level=logging.INFO)

import sys

from officebots import Robot

logging.getLogger('officebots').setLevel(logging.DEBUG)

if len(sys.argv) < 3:
    print("Usage: %s <robot name> <cmd> [<param1> <param2> ...]" % sys.argv[0])
    sys.exit(1)



cmd = [sys.argv[1], sys.argv[2], [x for x in sys.argv[3:]]]


class MyRobot(Robot):


    async def run(self):

        #while True:

        response = await self.execute(cmd)

        print(response)

        self.stop()

MyRobot().start()
