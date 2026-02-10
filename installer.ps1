Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ── Theme ────────────────────────────────────────────────────────────
$bgColor       = [System.Drawing.Color]::FromArgb(30, 30, 30)
$panelColor    = [System.Drawing.Color]::FromArgb(40, 40, 40)
$accentColor   = [System.Drawing.Color]::FromArgb(220, 80, 40)
$btnColor      = [System.Drawing.Color]::FromArgb(60, 60, 60)
$btnHover      = [System.Drawing.Color]::FromArgb(80, 80, 80)
$textColor     = [System.Drawing.Color]::White
$dimText       = [System.Drawing.Color]::FromArgb(170, 170, 170)
$successColor  = [System.Drawing.Color]::FromArgb(80, 200, 80)
$errorColor    = [System.Drawing.Color]::FromArgb(255, 90, 90)

$fontTitle     = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$fontHeading   = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$fontBody      = New-Object System.Drawing.Font("Segoe UI", 11)
$fontSmall     = New-Object System.Drawing.Font("Segoe UI", 9)
$fontStep      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

# ── Main Window ──────────────────────────────────────────────────────
$form = New-Object System.Windows.Forms.Form
$form.Text = "Fire Alert Bot - Installer"
$form.Size = New-Object System.Drawing.Size(700, 680)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = $bgColor
$form.ForeColor = $textColor
$form.Font = $fontBody

# ── Step indicator at top ────────────────────────────────────────────
$stepBar = New-Object System.Windows.Forms.Panel
$stepBar.Dock = "Top"
$stepBar.Height = 50
$stepBar.BackColor = $panelColor
$form.Controls.Add($stepBar)

$stepLabel = New-Object System.Windows.Forms.Label
$stepLabel.AutoSize = $false
$stepLabel.Size = New-Object System.Drawing.Size(660, 40)
$stepLabel.Location = New-Object System.Drawing.Point(20, 8)
$stepLabel.Font = $fontStep
$stepLabel.ForeColor = $dimText
$stepBar.Controls.Add($stepLabel)

# ── Content area (scrollable) ────────────────────────────────────────
$content = New-Object System.Windows.Forms.Panel
$content.Location = New-Object System.Drawing.Point(0, 50)
$content.Size = New-Object System.Drawing.Size(700, 540)
$content.BackColor = $bgColor
$content.AutoScroll = $true
$form.Controls.Add($content)

# ── Bottom button bar ────────────────────────────────────────────────
$btnBar = New-Object System.Windows.Forms.Panel
$btnBar.Dock = "Bottom"
$btnBar.Height = 55
$btnBar.BackColor = $panelColor
$form.Controls.Add($btnBar)

function New-StyledButton($text, $x) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $text
    $btn.Size = New-Object System.Drawing.Size(120, 36)
    $btn.Location = New-Object System.Drawing.Point($x, 10)
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 1
    $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
    $btn.BackColor = $btnColor
    $btn.ForeColor = $textColor
    $btn.Font = $fontBody
    $btn.Cursor = "Hand"
    $btn.Add_MouseEnter({ $this.BackColor = $btnHover })
    $btn.Add_MouseLeave({ $this.BackColor = $btnColor })
    return $btn
}

$btnBack = New-StyledButton "Back" 440
$btnNext = New-StyledButton "Next" 560
$btnNext.BackColor = $accentColor
$btnNext.FlatAppearance.BorderColor = $accentColor
$btnNext.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(240, 100, 60) })
$btnNext.Add_MouseLeave({ $this.BackColor = $accentColor })

$btnBar.Controls.Add($btnBack)
$btnBar.Controls.Add($btnNext)

# ── State ────────────────────────────────────────────────────────────
$script:currentPage = 0
$script:totalPages = 9
$script:botToken = ""
$script:inviteUrl = ""
$script:pythonCmd = ""

$stepNames = @(
    "Welcome",
    "Python",
    "Dependencies",
    "Create App",
    "Bot Token",
    "Paste Token",
    "Permissions",
    "Invite Bot",
    "Finish"
)

# ── Helper: make a label ─────────────────────────────────────────────
function New-Label($text, $x, $y, $w, $h, $font, $color) {
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $text
    $lbl.Location = New-Object System.Drawing.Point($x, $y)
    $lbl.AutoSize = $false
    $lbl.Size = New-Object System.Drawing.Size($w, $h)
    if ($font) { $lbl.Font = $font }
    if ($color) { $lbl.ForeColor = $color } else { $lbl.ForeColor = $textColor }
    return $lbl
}

# ── Page rendering ───────────────────────────────────────────────────
function Show-Page {
    $content.Controls.Clear()

    # Update step bar
    $dots = ""
    for ($i = 0; $i -lt $script:totalPages; $i++) {
        if ($i -eq $script:currentPage) {
            $dots += "[$($stepNames[$i])]  "
        } else {
            $dots += "$($stepNames[$i])  "
        }
    }
    $stepLabel.Text = $dots

    # Button visibility
    $btnBack.Visible = ($script:currentPage -gt 0)
    $btnNext.Text = if ($script:currentPage -eq ($script:totalPages - 1)) { "Start Bot" } else { "Next" }

    switch ($script:currentPage) {
        0 { Page-Welcome }
        1 { Page-Python }
        2 { Page-Dependencies }
        3 { Page-CreateApp }
        4 { Page-BotToken }
        5 { Page-PasteToken }
        6 { Page-Permissions }
        7 { Page-InviteBot }
        8 { Page-Finish }
    }
}

# ── PAGE 0: Welcome ─────────────────────────────────────────────────
function Page-Welcome {
    $content.Controls.Add((New-Label "Fire Alert Discord Bot" 40 30 600 40 $fontTitle $accentColor))
    $content.Controls.Add((New-Label @"
This installer will set up a Discord bot that automatically
posts NWS/NOAA fire warnings to your server.

It monitors:
   - Red Flag Warnings
   - Fire Weather Watches
   - Fire Warnings
   - Extreme Fire Danger alerts

The setup takes about 10 minutes. This installer will walk
you through every step.

Click Next to begin.
"@ 40 85 600 320 $fontBody $textColor))
}

# ── PAGE 1: Python ───────────────────────────────────────────────────
function Page-Python {
    $content.Controls.Add((New-Label "Checking for Python..." 40 30 600 35 $fontHeading $textColor))

    $statusLabel = New-Label "" 40 80 600 300 $fontBody $textColor
    $content.Controls.Add($statusLabel)

    # Check if Python is available
    $script:pythonCmd = ""
    try {
        $ver = & python --version 2>&1
        if ($ver -match "Python 3") {
            $script:pythonCmd = "python"
            $statusLabel.ForeColor = $successColor
            $statusLabel.Text = "Python is installed: $ver`n`nClick Next to continue."
            return
        }
    } catch {}

    try {
        $ver = & py --version 2>&1
        if ($ver -match "Python 3") {
            $script:pythonCmd = "py"
            $statusLabel.ForeColor = $successColor
            $statusLabel.Text = "Python is installed: $ver`n`nClick Next to continue."
            return
        }
    } catch {}

    $statusLabel.ForeColor = $errorColor
    $statusLabel.Text = @"
Python is not installed yet.

Click the button below to open the download page,
then follow these steps:

  1. Click the big yellow "Download Python" button
  2. Run the file that downloads
  3. CHECK THE BOX that says "Add Python to PATH"
     (at the bottom of the installer window)
  4. Click "Install Now"
  5. When it finishes, come back here and click Next
"@

    $dlBtn = New-StyledButton "Open Download Page" 40
    $dlBtn.Size = New-Object System.Drawing.Size(200, 36)
    $dlBtn.Location = New-Object System.Drawing.Point(40, 400)
    $dlBtn.Add_Click({ Start-Process "https://www.python.org/downloads/" })
    $content.Controls.Add($dlBtn)
}

# ── PAGE 2: Dependencies ────────────────────────────────────────────
function Page-Dependencies {
    $content.Controls.Add((New-Label "Installing bot software..." 40 30 600 35 $fontHeading $textColor))

    $statusLabel = New-Label "Please wait..." 40 80 600 300 $fontBody $dimText
    $content.Controls.Add($statusLabel)

    $form.Refresh()

    $cmd = if ($script:pythonCmd) { $script:pythonCmd } else { "python" }
    try {
        $result = & $cmd -m pip install -r "$scriptDir\requirements.txt" 2>&1 | Out-String
        $statusLabel.ForeColor = $successColor
        $statusLabel.Text = "All dependencies installed successfully.`n`nClick Next to continue."
    } catch {
        $statusLabel.ForeColor = $errorColor
        $statusLabel.Text = "Something went wrong installing dependencies.`n`n$($_.Exception.Message)`n`nMake sure Python is installed (go Back to check), then try again."
    }
}

# ── PAGE 3: Create App ──────────────────────────────────────────────
function Page-CreateApp {
    $content.Controls.Add((New-Label "Create a Discord Application" 40 30 600 35 $fontHeading $textColor))
    $content.Controls.Add((New-Label @"
Click the button below to open the Discord Developer Portal.
Then follow these steps:

  1. Log in with your Discord account if asked

  2. Click "New Application" (blue button, top-right area)

  3. A popup asks for a name - type:  Fire Alerts

  4. Check the box to agree to the Terms of Service

  5. Click "Create"

You'll land on a "General Information" page.
You can ignore everything on it.

When you're done, click Next.
"@ 40 80 600 300 $fontBody $textColor))

    $openBtn = New-StyledButton "Open Developer Portal" 40
    $openBtn.Size = New-Object System.Drawing.Size(220, 36)
    $openBtn.Location = New-Object System.Drawing.Point(40, 420)
    $openBtn.Add_Click({ Start-Process "https://discord.com/developers/applications" })
    $content.Controls.Add($openBtn)
}

# ── PAGE 4: Bot Token instructions ───────────────────────────────────
function Page-BotToken {
    $content.Controls.Add((New-Label "Get Your Bot Token" 40 30 600 35 $fontHeading $textColor))
    $content.Controls.Add((New-Label @"
In the Discord Developer Portal (still open in your browser):

  1. Look at the left sidebar and click "Bot"

  2. You'll see a "Token" section with a "Reset Token" button
     Click "Reset Token"

  3. A popup asks "Are you sure?" - click "Yes, do it!"
     (If you use 2FA, you'll need to enter your code)

  4. A long string of letters and numbers appears
     This is your bot's secret password - never share it!

  5. Click "Copy" right next to the token string

On the next page you'll paste it here.
"@ 40 80 600 320 $fontBody $textColor))
}

# ── PAGE 5: Paste Token ─────────────────────────────────────────────
function Page-PasteToken {
    $content.Controls.Add((New-Label "Paste Your Bot Token" 40 30 600 35 $fontHeading $textColor))
    $content.Controls.Add((New-Label "Paste the token you copied from Discord into the box below.`nYou can use Ctrl+V to paste." 40 80 600 50 $fontBody $dimText))

    $script:tokenBox = New-Object System.Windows.Forms.TextBox
    $script:tokenBox.Location = New-Object System.Drawing.Point(40, 150)
    $script:tokenBox.Size = New-Object System.Drawing.Size(600, 30)
    $script:tokenBox.Font = New-Object System.Drawing.Font("Consolas", 11)
    $script:tokenBox.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
    $script:tokenBox.ForeColor = $textColor
    $script:tokenBox.BorderStyle = "FixedSingle"
    if ($script:botToken) { $script:tokenBox.Text = $script:botToken }
    $content.Controls.Add($script:tokenBox)

    $script:tokenStatus = New-Label "" 40 195 600 30 $fontSmall $dimText
    $content.Controls.Add($script:tokenStatus)

    $content.Controls.Add((New-Label @"
What does a token look like?
It's a long string like:  MTIzNDU2Nzg5.Gabcde.xyz123abc456

If you lost it, go Back, then in the Discord Developer Portal
click Bot in the sidebar and click "Reset Token" again.
"@ 40 240 600 160 $fontBody $dimText))
}

# ── PAGE 6: Permissions ─────────────────────────────────────────────
function Page-Permissions {
    $content.Controls.Add((New-Label "Turn On Required Permissions" 40 30 600 35 $fontHeading $textColor))
    $content.Controls.Add((New-Label @"
Still in the Discord Developer Portal, on the "Bot" page:

  1. Scroll down below the Token section

  2. You'll see "Privileged Gateway Intents"
     There are 3 toggle switches

  3. Find "MESSAGE CONTENT INTENT" and click it ON
     (the toggle turns blue/green when it's on)

  4. A bar appears at the bottom that says
     "Careful - you have unsaved changes!"
     Click "Save Changes"

When you've done that, click Next.
"@ 40 80 600 320 $fontBody $textColor))
}

# ── PAGE 7: Invite Bot ──────────────────────────────────────────────
function Page-InviteBot {
    $content.Controls.Add((New-Label "Invite the Bot to Your Server" 40 20 600 35 $fontHeading $textColor))
    $content.Controls.Add((New-Label @"
In the Developer Portal:

  1. Left sidebar - click "OAuth2"

  2. Scroll to "OAuth2 URL Generator"

  3. Under SCOPES, check these two boxes:
        bot
        applications.commands

  4. A "Bot Permissions" grid appears below.
     Check these boxes:
        Send Messages
        Embed Links
        Read Message History

  5. Scroll to the bottom and click "Copy"
     next to the Generated URL

  6. Paste the URL into the box below and click Next
     (or paste it in your browser yourself)
"@ 40 55 600 460 $fontBody $textColor))

    $script:inviteBox = New-Object System.Windows.Forms.TextBox
    $script:inviteBox.Location = New-Object System.Drawing.Point(40, 520)
    $script:inviteBox.Size = New-Object System.Drawing.Size(600, 30)
    $script:inviteBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $script:inviteBox.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
    $script:inviteBox.ForeColor = $textColor
    $script:inviteBox.BorderStyle = "FixedSingle"
    if ($script:inviteUrl) { $script:inviteBox.Text = $script:inviteUrl }
    $content.Controls.Add($script:inviteBox)

    $content.Controls.Add((New-Label "After pasting, click Next to open it in your browser. Select your server and click Authorize." 40 560 600 50 $fontSmall $dimText))
}

# ── PAGE 8: Finish ───────────────────────────────────────────────────
function Page-Finish {
    $content.Controls.Add((New-Label "You're All Set!" 40 30 600 40 $fontTitle $successColor))
    $content.Controls.Add((New-Label @"
Everything is installed and configured.

When you click "Start Bot" below, the bot will launch.
Once it says "Logged in as..." in the console window,
go to Discord and type:

    /setchannel

in the channel where you want fire alerts posted.

The bot will also auto-start every time you turn on
your computer. It runs minimized - you won't notice it.
"@ 40 85 600 220 $fontBody $textColor))

    $content.Controls.Add((New-Label @"
To stop the bot:  find it in your taskbar, click it, press Ctrl+C
To undo auto-start:  press Win+R, type shell:startup, delete the shortcut
"@ 40 320 600 80 $fontSmall $dimText))

    $btnNext.Text = "Start Bot"
}

# ── Navigation logic ─────────────────────────────────────────────────
$btnNext.Add_Click({
    # Page-specific validation before moving forward
    switch ($script:currentPage) {
        1 {
            # Re-check Python
            $found = $false
            try {
                $v = & python --version 2>&1
                if ($v -match "Python 3") { $script:pythonCmd = "python"; $found = $true }
            } catch {}
            if (-not $found) {
                try {
                    $v = & py --version 2>&1
                    if ($v -match "Python 3") { $script:pythonCmd = "py"; $found = $true }
                } catch {}
            }
            if (-not $found) {
                [System.Windows.Forms.MessageBox]::Show(
                    "Python is not detected yet.`n`nIf you just installed it, close this installer and double-click install.bat again.",
                    "Python Not Found",
                    "OK", "Warning"
                )
                return
            }
        }
        5 {
            # Validate token
            $tok = $script:tokenBox.Text.Trim()
            if ($tok.Length -lt 30) {
                [System.Windows.Forms.MessageBox]::Show(
                    "That doesn't look like a valid token.`nMake sure you copied the whole thing from Discord.",
                    "Invalid Token", "OK", "Warning"
                )
                return
            }
            $script:botToken = $tok
            # Save token to .env (use ASCII to avoid UTF8 BOM that breaks dotenv)
            $envPath = [System.IO.Path]::Combine($scriptDir, ".env")
            [System.IO.File]::WriteAllText($envPath, "DISCORD_TOKEN=$tok`n")
        }
        7 {
            # Handle invite URL
            $url = $script:inviteBox.Text.Trim()
            if ($url -match "^https://discord") {
                $script:inviteUrl = $url
                Start-Process $url
            }
            # Set up auto-start
            $startup = [System.IO.Path]::Combine($env:APPDATA, "Microsoft\Windows\Start Menu\Programs\Startup")
            $shortcutPath = [System.IO.Path]::Combine($startup, "FireAlertBot.lnk")
            $ws = New-Object -ComObject WScript.Shell
            $sc = $ws.CreateShortcut($shortcutPath)
            $sc.TargetPath = [System.IO.Path]::Combine($scriptDir, "start_bot.bat")
            $sc.WorkingDirectory = $scriptDir
            $sc.WindowStyle = 7  # Minimized
            $sc.Description = "Fire Alert Discord Bot"
            $sc.Save()
        }
        8 {
            # Final page - start the bot via start_bot.bat
            $batPath = [System.IO.Path]::Combine($scriptDir, "start_bot.bat")
            Start-Process $batPath -WorkingDirectory $scriptDir
            $form.Close()
            return
        }
    }

    # Go to next page
    if ($script:currentPage -lt ($script:totalPages - 1)) {
        $script:currentPage++
        Show-Page
    }
})

$btnBack.Add_Click({
    if ($script:currentPage -gt 0) {
        # Save token text if leaving the token page
        if ($script:currentPage -eq 5 -and $script:tokenBox) {
            $script:botToken = $script:tokenBox.Text.Trim()
        }
        if ($script:currentPage -eq 7 -and $script:inviteBox) {
            $script:inviteUrl = $script:inviteBox.Text.Trim()
        }
        $script:currentPage--
        Show-Page
    }
})

# ── Launch ───────────────────────────────────────────────────────────
Show-Page
$form.ShowDialog() | Out-Null
