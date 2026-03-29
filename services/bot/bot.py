import aiohttp
import os

import discord
from discord import app_commands
from discord.ext import commands
import requests
import redis

REALTIME_URL = os.environ.get("REALTIME_URL", "http://localhost:4000")
REDIS_URL = os.environ.get("REDIS_URL", "redis://localhost:6379")
GUILD_ID = 1486836077875691590

# default response window is short so i defer it because the bot sometimes takes a little long.
# after 10 seconds there is most likely an error, so forcing a timeout is necessary.
RESPONSE_TIMEOUT = aiohttp.ClientTimeout(total=10)

r = redis.from_url(REDIS_URL)

intents = discord.Intents.default()
intents.messages = True
intents.guilds = True
intents.members = True

bot = commands.Bot(command_prefix="/", intents=intents)


# /active
@bot.tree.command(name="active", description="Show number of active users in this channel")
@app_commands.guilds(discord.Object(id=GUILD_ID)) # immediately registers test server
async def active(interaction: discord.Interaction):
    await interaction.response.defer()

    try:
        channel_id = str(interaction.channel_id)

        async with aiohttp.ClientSession(timeout=RESPONSE_TIMEOUT) as session:
            async with session.get(f"{REALTIME_URL}/active/{channel_id}") as resp:
                if resp.status == 200:
                    data = await resp.json()
                    count = data.get("active_users", 0)
                else:
                    count = 0
            
                msg = f"Active users in this channel: {count}"
    except Exception as e:
        msg = f"Error fetching active user data: {str(e)}"
    
    await interaction.followup.send(msg)


# /top
@bot.tree.command(name="top", description="Show top users by message count")
@app_commands.guilds(discord.Object(id=GUILD_ID))
async def top(interaction: discord.Interaction):
    await interaction.response.defer()

    try:
        async with aiohttp.ClientSession(timeout=RESPONSE_TIMEOUT) as session:
            async with session.get(f"{REALTIME_URL}/top") as resp:
                if resp.status == 200:
                    data = await resp.json()
                    top_users = data.get("top", [])
                else:
                    top_users = []
    
        if not top_users:
            msg = "No activity yet"
        else:
            # formats top users
            msg_lines = [f"{i + 1}. <@{u['user']}>: {u['messages']} messages" for i, u in enumerate(top_users)]
            msg = "\n".join(msg_lines)
    except Exception as e:
        msg = f"Error fetching top users: {str(e)}"

    await interaction.followup.send(msg)


# /rate
@bot.tree.command(name="rate", description="Show message rate for a given user")
@app_commands.guilds(discord.Object(id=GUILD_ID))
async def rate(interaction: discord.Interaction, user: discord.Member):
    await interaction.response.defer()

    try:
        user_id = str(user.id)
        async with aiohttp.ClientSession(timeout=RESPONSE_TIMEOUT) as session:
            async with session.get(f"{REALTIME_URL}/rate/{user_id}") as resp:
                if resp.status == 200:
                    data = await resp.json()
                    rate = data.get("rate", 0)
                else:
                    rate = 0
            
                msg = f"<@{user_id}> has a message rate of {rate:.2f} messages/min"
    except Exception as e:
        msg = f"Error fetching user message data: {str(e)}"
    
    await interaction.followup.send(msg)


# /spam
@bot.tree.command(name="spam", description="Show list of users detected as spamming")
@app_commands.guilds(discord.Object(id=GUILD_ID))
async def spam(interaction: discord.Interaction):
    await interaction.response.defer()

    try:
        async with aiohttp.ClientSession(timeout=RESPONSE_TIMEOUT) as session:
            async with session.get(f"{REALTIME_URL}/spam") as resp:
                if resp.status == 200:
                    data = await resp.json()
                    spammers = data.get("spammers", [])
                else:
                    spammers = []
    
        if not spammers:
            msg = "No spammers detected"
        else:
            msg_lines = [f"<@{u['user']}>: {u['messages']} messages in {u['window']}s" for u in spammers]
            msg = "\n".join(msg_lines)
    except Exception as e:
        msg = f"Error fetching spam data: {str(e)}"
    
    await interaction.followup.send(msg)


@bot.event
async def on_ready():
    print(f"Logged in as {bot.user}")

    try:
        synced = await bot.tree.sync(guild=discord.Object(id=GUILD_ID))
        print(f"Synced {len(synced)} command(s)")
    except Exception as e:
        print("Sync failed", e)


# forwards all messages to elixir ingestion
@bot.event
async def on_message(message):
    if message.author.bot:
        return

    payload = {
        "guild_id": str(message.guild.id),
        "channel_id": str(message.channel.id),
        "user_id": str(message.author.id),
        "type": "MESSAGE_CREATE",
        "content": message.content
    }

    try:
        requests.post(f"{REALTIME_URL}/ingest", json=payload, timeout=1)
    except Exception as e:
        print("Failed to send event:", e)
    
    await bot.process_commands(message)


bot.run(os.environ["DISCORD_TOKEN"])