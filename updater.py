"""
Auto-updater — runs on every bot startup.
Checks GitHub for a newer version and downloads updated files if found.
No git required on the user's machine.
"""
import os
import io
import zipfile
import urllib.request
import urllib.error
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# Files that belong to the USER and should never be overwritten
USER_FILES = {
    ".env",
    "config.json",
    "seen_alerts.json",
}


def read_config():
    """Read the GitHub repo info from update_config.txt."""
    config = {}
    config_path = os.path.join(SCRIPT_DIR, "update_config.txt")
    if not os.path.exists(config_path):
        return config
    with open(config_path, "r") as f:
        for line in f:
            line = line.strip()
            if "=" in line and not line.startswith("#"):
                key, value = line.split("=", 1)
                config[key.strip()] = value.strip()
    return config


def get_local_version():
    """Read the local version number."""
    version_path = os.path.join(SCRIPT_DIR, "version.txt")
    if not os.path.exists(version_path):
        return 0
    with open(version_path, "r") as f:
        try:
            return int(f.read().strip())
        except ValueError:
            return 0


def get_remote_version(repo, branch):
    """Fetch the version number from GitHub."""
    url = f"https://raw.githubusercontent.com/{repo}/{branch}/version.txt"
    try:
        req = urllib.request.Request(url)
        req.add_header("User-Agent", "rfw-bot-updater")
        with urllib.request.urlopen(req, timeout=10) as resp:
            return int(resp.read().decode().strip())
    except (urllib.error.URLError, ValueError, OSError) as e:
        print(f"  [UPDATE] Could not check for updates: {e}")
        return None


def download_and_extract(repo, branch):
    """Download the repo zip from GitHub and extract updated files."""
    url = f"https://github.com/{repo}/archive/refs/heads/{branch}.zip"
    print(f"  [UPDATE] Downloading update from GitHub...")

    try:
        req = urllib.request.Request(url)
        req.add_header("User-Agent", "rfw-bot-updater")
        with urllib.request.urlopen(req, timeout=60) as resp:
            zip_data = resp.read()
    except (urllib.error.URLError, OSError) as e:
        print(f"  [UPDATE] Download failed: {e}")
        return False

    try:
        with zipfile.ZipFile(io.BytesIO(zip_data)) as zf:
            # The zip contains a top-level folder like "rfw-bot-main/"
            # We need to find it and strip it from paths
            top_dirs = set()
            for name in zf.namelist():
                parts = name.split("/")
                if parts[0]:
                    top_dirs.add(parts[0])

            if len(top_dirs) != 1:
                print(f"  [UPDATE] Unexpected zip structure, skipping.")
                return False

            prefix = top_dirs.pop() + "/"
            updated = 0

            for info in zf.infolist():
                if info.is_dir():
                    continue

                # Strip the top-level folder from the path
                rel_path = info.filename[len(prefix):]
                if not rel_path:
                    continue

                # Skip user-specific files
                if rel_path in USER_FILES:
                    continue

                dest = os.path.join(SCRIPT_DIR, rel_path)

                # Create subdirectories if needed
                dest_dir = os.path.dirname(dest)
                if dest_dir and not os.path.exists(dest_dir):
                    os.makedirs(dest_dir, exist_ok=True)

                # Write the file
                with open(dest, "wb") as f:
                    f.write(zf.read(info.filename))
                updated += 1

            print(f"  [UPDATE] Updated {updated} file(s).")
            return True

    except (zipfile.BadZipFile, OSError) as e:
        print(f"  [UPDATE] Failed to extract update: {e}")
        return False


def check_for_updates():
    """Main entry point — check and apply updates."""
    config = read_config()
    repo = config.get("GITHUB_REPO", "")
    branch = config.get("BRANCH", "main")

    if not repo:
        # No repo configured, skip updates silently
        return False

    local_ver = get_local_version()
    print(f"  [UPDATE] Current version: {local_ver}")
    print(f"  [UPDATE] Checking {repo} for updates...")

    remote_ver = get_remote_version(repo, branch)
    if remote_ver is None:
        print(f"  [UPDATE] Skipping update check (no internet?).")
        return False

    if remote_ver <= local_ver:
        print(f"  [UPDATE] Already up to date.")
        return False

    print(f"  [UPDATE] New version available: {remote_ver}")
    success = download_and_extract(repo, branch)

    if success:
        print(f"  [UPDATE] Update complete! Restarting bot...")
        return True
    return False


if __name__ == "__main__":
    updated = check_for_updates()
    # Exit with code 1 if updated (signals start_bot.bat to restart)
    sys.exit(1 if updated else 0)
