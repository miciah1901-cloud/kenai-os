# Kenai OS

Kai's couch-gaming OS. Built on **Bazzite Deck (NVIDIA Open)**, Bazzite's supported NVIDIA flavor for RTX 16-series and newer: boots into Steam Gaming Mode, KDE desktop one menu away, Ember theme, and two Kenai apps:

- **Kenai Switch** — restart into the other OS with one button, from either side.
- **Kenai AI** — Claude, Gemini and Odysseus in one place to troubleshoot and change your setup.

![Desktop](docs/r2_1-desktop.png)

**Your drive plan:** Windows stays on its 1 TB drive, untouched. Kenai OS goes on about **1 TB carved from the 3 TB NVMe**. The rest of that drive stays as Windows game storage. The Passport is your backup.

---

## Part 1 — Make the image (any computer, ~10 min + build time)

1. Go to **https://workshop.blue-build.org** → **Log in with GitHub** → **New custom image repository** → name it `kenai-os` → let it set up signing automatically.
2. In the new repo, upload from this package:
   - `recipes/recipe.yml` (replace the one that's there)
   - the whole `files/` folder
   - `README.md`, `docs/` and `windows/` (optional, keeps everything together)
3. Open **Actions** and wait for the build to go green (15–30 min). Your image is `ghcr.io/<your-github-username>/kenai-os`.

Every change you commit rebuilds it automatically.

## Part 2 — Get Windows ready (on the gaming PC)

1. **Back up** anything on the 3 TB drive you can't redownload (clips, recordings, saves) to the Passport.
2. **Turn off Fast Startup:** Control Panel → Power Options → *Choose what the power buttons do* → uncheck *Turn on fast startup*.
3. **BitLocker / Device encryption — check both drives, including C:.** Search *Manage BitLocker* (or Settings → Privacy & security → Device encryption).
   - If it's on for **any** drive, first make sure you can open your recovery key **from your phone**: account.microsoft.com → Devices → *View BitLocker keys*. Changing boot settings or booting a USB can make Windows ask for it.
   - Turn it **off** for the 3 TB drive (Linux can't resize or share an encrypted drive).
   - For C: (the 1 TB Windows drive), pause it for the next few restarts. Open Terminal (Admin) and run: `manage-bde -protectors -disable C: -RebootCount 3`
4. **Leave Secure Boot ON** — Valorant needs it, and Kenai OS supports it.
5. **Shrink the 3 TB drive:** right-click Start → *Disk Management* → right-click the 3 TB drive's partition → *Shrink Volume* → enter **1000000** MB → *Shrink*. Leave the new space **Unallocated**. Don't format it.
   - If Windows won't shrink that much, the drive is too full: move or uninstall some games first.
6. **Write down the sizes** Disk Management shows for each disk (1 TB Windows, 3 TB, Passport). You'll use them to pick the right disk in the installer.

## Part 3 — Install Kenai OS

1. On another computer, download the **Bazzite** ISO from **bazzite.gg**: pick *Desktop → NVIDIA (RTX 16 series or newer) → Steam Gaming Mode*. Flash it to a USB stick with **Fedora Media Writer** or **Rufus**.
2. **Unplug the Passport.** One less disk to confuse.
3. Boot the USB from your motherboard's one-time boot menu (usually **F8** on ASUS, **F11** on MSI and ASRock, **F12** on Gigabyte).
4. In the installer, at **Installation Destination**:
   - Tick **only the 3 TB drive**. Untick the 1 TB Windows drive.
   - Choose the option that installs into **free space** (shown as *Automatic* or *Use free space*, depending on the installer version). **Never pick an option that says erase, reclaim or replace.**
   - **Stop and double-check the disk size** before you press *Begin Installation*. Picking the wrong disk is the one real way to lose data here.
5. Reboot. On the blue **MOK management** screen, choose *Enroll MOK* and enter the password from Bazzite's Secure Boot docs (if you miss it, run `ujust enroll-secure-boot-key` later).
6. Finish the Steam setup in Game Mode. Then switch to Desktop Mode (Steam button → Power → *Switch to Desktop*) and open **Konsole**.
7. Switch to your image:
   ```
   rpm-ostree rebase ostree-unverified-registry:ghcr.io/<your-github-username>/kenai-os:latest
   systemctl reboot
   ```
8. After that reboot, switch to the signed version so updates verify:
   ```
   rpm-ostree rebase ostree-image-signed:docker://ghcr.io/<your-github-username>/kenai-os:latest
   systemctl reboot
   ```
9. Go to Desktop Mode once. The Ember theme, icons, dock and widgets apply themselves on that first login. If anything didn't take, run `kenai-theme`.

**Boot order:** in your BIOS, put whichever OS you want by default first. Kenai Switch only changes the **next** boot, so the default never moves.

## Part 4 — Kenai Switch

**On Kenai OS:** it's in the dock and on the desktop. To get it in Game Mode, run `ujust kenai-steam-art` in Desktop Mode and follow the two steps it prints (add it to Steam, set the artwork).

**On Windows:**
1. Copy the `windows/KenaiSwitch` folder to a simple path like `C:\KenaiSwitch` (no apostrophes in the path). If it came from a zip: right-click the zip → *Properties* → tick **Unblock** before extracting.
2. Double-click **Install.cmd** and approve the admin prompt once. It finds Kenai OS in the boot list and sets everything up.
3. Add it to Steam Big Picture: *Games → Add a Non-Steam Game → Browse* → the Start menu shortcut path the installer prints. Set the artwork from `C:\Program Files\KenaiSwitch\assets`.
4. **Test it once from the keyboard:** open Kenai Switch from the Start menu, press Enter, and confirm the PC restarts into Kenai OS.

Remove it any time with **Uninstall.cmd**.

## Part 5 — Kenai AI

1. Open **Kenai AI** from the dock (or **Super + Space** after you've logged out and back in once). The first time, it runs setup:
   - **Claude Code** — sign in by typing `claude` (needs a Claude Pro/Max plan or an API key).
   - **Gemini CLI** — sign in by typing `gemini` → *Login with Google* (free tier).
   - **Odysseus** — optional, downloads several GB. Runs on your GPU, private, free. Odysseus is a young project, so if its install hits a snag, ask Claude in the next tab to fix it.
2. After setup, Kenai AI opens with three tabs: Claude, Gemini, Odysseus.

**What keeps the AI from wrecking things:**
- Both assistants get a notes file (`~/.claude/CLAUDE.md`) telling them how Kenai OS works, to run `kenai-backup` before every change, and never to touch disks, partitions or Windows.
- Claude Code asks before running commands unless you tell it otherwise.
- `kenai-undo` restores the last backup. `kenai-undo --list` shows them all.
- The core OS is read-only. A bad system update rolls back with `rpm-ostree rollback`, or by picking the previous entry in the boot menu.

## Commands

| Command | Does |
|---|---|
| `kenai-theme` | Re-apply the Ember theme, icons, dock and widgets |
| `kenai-undo` / `kenai-undo --list` | Undo the last desktop change / list backups |
| `kenai-switch` | Restart into Windows |
| `kenai-ai` / `kenai-ai-setup` | Open Kenai AI / run its setup again |
| `kenai-odysseus install\|start\|stop\|status\|logs\|update` | Local AI |
| `ujust kenai-bootsplash` / `ujust kenai-bootsplash-off` | Kenai boot animation on/off (on adds ~1 min to updates) |
| `ujust kenai-steam-art` | Steam artwork for the Game Mode tile |
| `ujust update` | Update everything now |
| `rpm-ostree rollback` | Undo the last system update |

## What's different from the mockups

- **Game Mode** keeps Steam's own layout. Kenai Switch shows up as a library tile with Kenai artwork. Recoloring Steam itself needs Decky Loader with the CSS Loader plugin (Bazzite has a setup command for Decky; see its docs), which you can add later.
- **Kenai AI** opens as a Kenai-themed terminal window with tabs, not the slide-out glass panel. Odysseus opens in your browser. The glass panel is a v2 job.
- **Dock:** one floating dock holds the menu, apps, tray and clock. The mockup split them into three pieces.
- **App icons:** Firefox, Discord and Heroic keep their own logos. Everything else uses the Kenai set on top of Papirus.
- **Boot menu:** there's no themed boot picker. Kenai Switch and your BIOS boot order replace it.

## Adding the Steam Machine (AMD) later

Copy `recipes/recipe.yml` to `recipes/recipe-amd.yml`. In the copy, set `name: kenai-os-amd` and `base-image: ghcr.io/ublue-os/bazzite-deck`. Add `recipe-amd.yml` to the `recipe:` list in `.github/workflows/build.yml`. Theme, Kenai Switch and Kenai AI are shared.
