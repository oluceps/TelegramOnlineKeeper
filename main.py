import asyncio
import uvloop
import json
import time
import logging
import os
import random

from pyrogram.raw import functions, types
from pyrogram import Client

CHECK_INTERVAL = 16
POSSIBLE = 0.95

api_id = os.getenv('API_ID')
api_hash = os.getenv('API_hash')

logging.basicConfig(format='%(asctime)s %(message)s', datefmt='%m/%d/%Y %I:%M:%S %p')

async def main():
    app = Client("user", api_id=api_id, api_hash=api_hash)
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
