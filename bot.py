import discord
from discord.ext import commands, tasks
from discord import app_commands
import aiohttp
import json
import os
from datetime import datetime, timezone

# ── Settings ─────────────────────────────────────────────────────────
# The NWS fire-related alert types we monitor
FIRE_EVENTS = [
    "Red Flag Warning",
    "Fire Weather Watch",
    "Fire Warning",
    "Extreme Fire Danger",
]

# How often to check for new alerts (in minutes)
CHECK_INTERVAL_MINUTES = 2

# NWS API endpoint — no API key needed
NWS_API_URL = "https://api.weather.gov/alerts/active"

# Files the bot uses to remember things between restarts
CONFIG_FILE = "config.json"
SEEN_FILE = "seen_alerts.json"


# ── Helper functions ─────────────────────────────────────────────────
def load_json(path, default):
    """Read a JSON file, or return a default value if it doesn't exist."""
    if os.path.exists(path):
        with open(path, "r") as f:
            return json.load(f)
    return default


def save_json(path, data):
    """Write data to a JSON file."""
    with open(path, "w") as f:
        json.dump(data, f, indent=2)


def build_alert_embed(alert_props):
    """Turn a single NWS alert into a nice-looking Discord embed."""
    event = alert_props.get("event", "Unknown Event")
    headline = alert_props.get("headline", "No headline")
    area = alert_props.get("areaDesc", "Unknown area")
    severity = alert_props.get("severity", "Unknown")
    urgency = alert_props.get("urgency", "Unknown")
    description = alert_props.get("description", "No description provided.")
    instruction = alert_props.get("instruction", "")
    sender = alert_props.get("senderName", "NWS")
    onset = alert_props.get("onset", "")
    expires = alert_props.get("expires", "")

    # Pick a color based on the type of alert
    color_map = {
        "Red Flag Warning": discord.Color.red(),
        "Extreme Fire Danger": discord.Color.dark_red(),
        "Fire Warning": discord.Color.orange(),
        "Fire Weather Watch": discord.Color.gold(),
    }
    color = color_map.get(event, discord.Color.orange())

    # Discord embeds have a 4096-char description limit
    if len(description) > 1500:
        description = description[:1500] + "…"

    embed = discord.Embed(
        title=f"🔥 {event}",
        description=headline,
        color=color,
        timestamp=datetime.now(timezone.utc),
    )
    embed.add_field(name="Area", value=area[:1024], inline=False)
    embed.add_field(name="Severity", value=severity, inline=True)
    embed.add_field(name="Urgency", value=urgency, inline=True)

    if onset:
        embed.add_field(name="Starts", value=onset, inline=True)
    if expires:
        embed.add_field(name="Expires", value=expires, inline=True)

    embed.add_field(name="Details", value=description[:1024], inline=False)

    if instruction:
        if len(instruction) > 1024:
            instruction = instruction[:1021] + "…"
        embed.add_field(name="Instructions", value=instruction, inline=False)

    embed.set_footer(text=f"Source: {sender}")
    return embed


# ── Bot setup ────────────────────────────────────────────────────────
intents = discord.Intents.default()
intents.message_content = True
bot = commands.Bot(command_prefix="!", intents=intents)

# Load persistent data
config = load_json(CONFIG_FILE, {})        # {"channel_id": 123456}
seen_alerts = load_json(SEEN_FILE, [])     # ["alert-id-1", "alert-id-2", ...]


async def fetch_fire_alerts(session):
    """Ask the NWS API for all active fire-related alerts."""
    all_alerts = []
    for event_type in FIRE_EVENTS:
        params = {"event": event_type, "status": "actual"}
        headers = {
            "User-Agent": "(discord-fire-bot, contact@example.com)",
            "Accept": "application/geo+json",
        }
        try:
            async with session.get(
                NWS_API_URL, params=params, headers=headers
            ) as resp:
                if resp.status == 200:
                    data = await resp.json()
                    all_alerts.extend(data.get("features", []))
        except Exception as e:
            print(f"[ERROR] Failed to fetch {event_type}: {e}")
    return all_alerts


# ── Background task: check for new alerts ────────────────────────────
@tasks.loop(minutes=CHECK_INTERVAL_MINUTES)
async def check_alerts():
    """Runs every few minutes. Fetches alerts and posts any new ones."""
    global seen_alerts

    channel_id = config.get("channel_id")
    if not channel_id:
        return  # No channel set up yet — nothing to do

    channel = bot.get_channel(channel_id)
    if not channel:
        print("[WARNING] Could not find the alert channel. Was it deleted?")
        return

    async with aiohttp.ClientSession() as session:
        alerts = await fetch_fire_alerts(session)

    new_count = 0
    for feature in alerts:
        alert_id = feature.get("properties", {}).get("id", "")
        if alert_id and alert_id not in seen_alerts:
            seen_alerts.append(alert_id)
            embed = build_alert_embed(feature["properties"])
            try:
                await channel.send(embed=embed)
                new_count += 1
            except Exception as e:
                print(f"[ERROR] Could not send alert: {e}")

    # Keep the seen-alerts list from growing forever (cap at 5000)
    if len(seen_alerts) > 5000:
        seen_alerts = seen_alerts[-2500:]

    save_json(SEEN_FILE, seen_alerts)

    if new_count:
        print(f"[INFO] Posted {new_count} new fire alert(s).")


@check_alerts.before_loop
async def before_check():
    """Wait until the bot is fully connected before starting the loop."""
    await bot.wait_until_ready()


# ── Events ───────────────────────────────────────────────────────────
@bot.event
async def on_ready():
    """Runs once when the bot first connects to Discord."""
    print(f"Logged in as {bot.user} (ID: {bot.user.id})")
    print("------")

    # Register slash commands with Discord
    try:
        synced = await bot.tree.sync()
        print(f"Synced {len(synced)} slash command(s).")
    except Exception as e:
        print(f"[ERROR] Failed to sync commands: {e}")

    # Start the background alert checker
    if not check_alerts.is_running():
        check_alerts.start()


# ── Slash commands ───────────────────────────────────────────────────
@bot.tree.command(name="setchannel", description="Set this channel to receive fire alerts")
@app_commands.default_permissions(administrator=True)
async def setchannel(interaction: discord.Interaction):
    """Server admins use this to pick which channel gets alerts."""
    config["channel_id"] = interaction.channel_id
    save_json(CONFIG_FILE, config)
    await interaction.response.send_message(
        f"✅ Fire alerts will now be posted in <#{interaction.channel_id}>.\n"
        f"The bot checks for new alerts every {CHECK_INTERVAL_MINUTES} minutes."
    )


@bot.tree.command(name="alerts", description="Show all current active fire alerts")
async def alerts(interaction: discord.Interaction):
    """Manually check for current fire alerts right now."""
    await interaction.response.defer()  # Give us time — API calls can be slow

    async with aiohttp.ClientSession() as session:
        all_alerts = await fetch_fire_alerts(session)

    if not all_alerts:
        await interaction.followup.send(
            "✅ **No active fire alerts nationwide at this time.**"
        )
        return

    # Send up to 10 alerts so we don't flood the channel
    count = 0
    for feature in all_alerts[:10]:
        embed = build_alert_embed(feature["properties"])
        await interaction.followup.send(embed=embed)
        count += 1

    if len(all_alerts) > 10:
        await interaction.followup.send(
            f"*Showing 10 of {len(all_alerts)} active alerts. "
            f"More are being monitored automatically.*"
        )


@bot.tree.command(name="status", description="Check if the fire alert bot is running")
async def status(interaction: discord.Interaction):
    """Quick health check."""
    ch_id = config.get("channel_id")
    if ch_id:
        channel_info = f"Posting alerts to <#{ch_id}>"
    else:
        channel_info = "⚠️ No alert channel set! Use `/setchannel` first."

    await interaction.response.send_message(
        f"🟢 **Fire Alert Bot is running.**\n"
        f"• Checking every {CHECK_INTERVAL_MINUTES} minutes\n"
        f"• Monitoring: {', '.join(FIRE_EVENTS)}\n"
        f"• {channel_info}\n"
        f"• Alerts tracked so far: {len(seen_alerts)}"
    )


# ── Start the bot ────────────────────────────────────────────────────
def start():
    token = os.getenv("DISCORD_TOKEN")
    if not token:
        print("=" * 55)
        print("  ERROR: No Discord token found!")
        print("  Make sure your .env file exists and has your token.")
        print("  See SETUP.md for instructions.")
        print("=" * 55)
    else:
        bot.run(token)


if __name__ == "__main__":
    start()
