"""
Simple launcher that loads your .env file, then starts the bot.
Run this file:   python run.py
"""
import os
import sys

# Make sure we're working from the script's own folder
script_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(script_dir)

from dotenv import load_dotenv

# Load the .env file from the script's folder explicitly
load_dotenv(os.path.join(script_dir, ".env"))

# Now start the bot
from bot import start
start()
