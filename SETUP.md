# Fire Alert Discord Bot — Setup Guide

This bot automatically posts NWS/NOAA fire warnings to your Discord server.
It monitors **Red Flag Warnings**, **Fire Weather Watches**, **Fire Warnings**,
and **Extreme Fire Danger** alerts.

---

## Quick Start (One-Click Installer)

**Double-click `install.bat`** and follow the on-screen instructions.
It walks you through everything. That's it.

The rest of this document is only here as a backup reference if something
goes wrong or you want to understand what the installer did.

---

---

## Manual Setup (Only If the Installer Didn't Work)

### Step 1: Install Python

1. Go to **https://www.python.org/downloads/**
2. Click the big yellow **Download Python** button
3. Run the installer
4. **CHECK THE BOX** at the bottom that says **"Add Python to PATH"**
5. Click **Install Now**

Verify: open Command Prompt (Windows key > type `cmd` > Enter) and type:
```
python --version
```
You should see `Python 3.x.x`.

---

### Step 2: Install Dependencies

Open Command Prompt and type:
```
cd C:\Users\drew\rfw-bot
pip install -r requirements.txt
```

---

### Step 3: Create a Discord Bot Account

This is the most involved step. Here's every click, in detail.

#### 3a. Go to the Discord Developer Portal

1. Open your browser
2. Go to **https://discord.com/developers/applications**
3. Log in with your Discord account if asked

You'll see a page titled **"Applications"**. It may be empty or have
items if you've made bots before.

#### 3b. Create a New Application

1. Click the **"New Application"** button (blue/purple, top right area)
2. A popup appears asking for a name
3. Type: **Fire Alerts** (or whatever you want to call it)
4. Check the checkbox to agree to the Terms of Service
5. Click **"Create"**

You'll be taken to the **"General Information"** page for your new app.
You can ignore everything on this page.

#### 3c. Get Your Bot Token

The "token" is a long secret password that lets the bot log in to Discord.
**Never share it with anyone.**

1. On the **left sidebar**, click **"Bot"**

2. You'll see a page with your bot's username and an avatar.
   Look for the **"Token"** section.

3. Click the **"Reset Token"** button

4. A popup asks "Are you sure?" — click **"Yes, do it!"**
   (If you have 2FA on your Discord account, enter your code)

5. A long string of letters, numbers, and dots appears.
   It looks something like: `MTIzNDU2Nzg5.Gabcde.xyz123abc456...`

6. Click **"Copy"** right next to it

7. Now save it to a file:
   - Go to the `C:\Users\drew\rfw-bot` folder
   - Find `env.example`, make a copy, rename the copy to `.env`
   - Open `.env` in Notepad
   - Replace `paste-your-bot-token-here` with what you copied
   - Save and close

   Your `.env` file should look like:
   ```
   DISCORD_TOKEN=MTIzNDU2Nzg5.Gabcde.xyz123abc456...
   ```

#### 3d. Turn On Message Content Intent

Still on the **"Bot"** page in the Developer Portal:

1. **Scroll down** — below the token section, you'll see a section called
   **"Privileged Gateway Intents"**

2. There are 3 toggles. Find **"Message Content Intent"**

3. Click the toggle to turn it **ON** (it turns green/blue)

4. A green bar appears at the bottom of the page that says
   **"Careful - you have unsaved changes!"**
   Click **"Save Changes"**

#### 3e. Create the Invite Link

1. On the **left sidebar**, click **"OAuth2"**

2. Scroll down until you see **"OAuth2 URL Generator"**

3. You'll see a grid of checkboxes under **"Scopes"**.
   Check these two:
   - **bot**
   - **applications.commands**

4. After checking "bot", a second grid appears below called
   **"Bot Permissions"**. Check these:
   - **Send Messages**
   - **Embed Links**
   - **Read Message History**

5. Scroll all the way to the bottom. You'll see **"Generated URL"**
   with a long URL. Click **"Copy"**

#### 3f. Invite the Bot to Your Server

1. Paste the URL you just copied into your browser's address bar
2. Press Enter
3. A Discord page appears asking which server to add the bot to
4. **Select your server** from the dropdown
5. Click **"Authorize"**
6. Complete the CAPTCHA if one appears
7. You should see "Authorized" — you can close this tab

The bot now appears in your server's member list (it will show
as offline until you start it).

---

### Step 4: Test the Bot

Open Command Prompt and type:
```
cd C:\Users\drew\rfw-bot
python run.py
```

You should see:
```
Logged in as Fire Alerts#1234 (ID: 123456789)
------
Synced 3 slash command(s).
```

If so, it works! Go to your Discord server and type `/setchannel`
in the channel where you want fire alerts.

Press **Ctrl + C** in the Command Prompt to stop the bot.

---

### Step 5: Set Up Auto-Start

Double-click **`setup_autostart.bat`** in the rfw-bot folder.

This makes the bot start automatically (minimized in your taskbar)
every time you log into Windows.

To undo: press **Win+R**, type `shell:startup`, delete the
**FireAlertBot** shortcut.

---

## Using the Bot

| Command       | What It Does                                |
|---------------|---------------------------------------------|
| `/setchannel` | Sets the current channel to receive alerts  |
| `/alerts`     | Shows all active fire alerts right now       |
| `/status`     | Shows bot status and settings                |

---

## When My Laptop is Off

The bot runs whenever your laptop is on. When you open it back up,
it catches up on any alerts it missed. The NWS also sends alerts
through phones, TV, and radio, so you won't miss anything critical.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `python is not recognized` | Reinstall Python and check **"Add to PATH"** |
| `No module named 'discord'` | Run `pip install -r requirements.txt` in the rfw-bot folder |
| Bot shows offline | Make sure the bot is running (check taskbar) and `.env` has your token |
| No alerts posted | Use `/setchannel` first. There may be no active alerts (good news!) |
| `No Discord token found` | Make sure `.env` exists (not `.env.txt`) with your token inside |
