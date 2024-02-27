import asyncio
import uvloop
import json
import time
import logging
import os
import random
from pathlib import Path
import sys

from pyrogram.raw import functions, types
from pyrogram import Client

CHECK_INTERVAL = 16
POSSIBLE = 0.95

api_id = os.getenv('API_ID')
api_hash = os.getenv('API_HASH')
state_directory = os.getenv('STATE_DIRECTORY')

if state_directory == None:
    state_directory = Path(sys.argv[0]).parent.__str__()

logging.basicConfig(format='%(asctime)s %(message)s', datefmt='%m/%d/%Y %I:%M:%S %p')

async def main():
    global app
    if api_hash == None or api_id == None:
        session_string = os.getenv('SESSION_STRING')
        if session_string == None:
            logging.error("plz set $API_ID, $API_HASH or $SESSION_STRING")
        app = Client("user", session_string=session_string)
    else:
        app = Client("user", api_id=api_id, api_hash=api_hash, workdir=state_directory)

    async with app:
        while True:
            time.sleep(CHECK_INTERVAL)
            status = json.loads((await app.get_me()).__str__())["status"]

            if status == "UserStatus.OFFLINE":
                logging.warning('Offline detected. Online ing')
                await app.invoke(functions.account.UpdateStatus(offline=False))
            else:
                if random.random() > POSSIBLE:
                    logging.info('Online. Randomly set offline')
                    await app.invoke(functions.account.UpdateStatus(offline=True))

uvloop.install()
asyncio.run(main())
