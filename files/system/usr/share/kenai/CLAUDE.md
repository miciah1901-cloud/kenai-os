# Kenai OS — notes for the AI assistant

You're running on **Kenai OS**, Kai's custom couch-gaming distro. It's a BlueBuild image
built on **Bazzite Deck (NVIDIA Open)**, which is Fedora Atomic underneath. It boots into
Steam Gaming Mode; Desktop Mode is KDE Plasma 6.

## How this system works
- `/usr` is read-only and comes from the image. Don't try to edit files under `/usr`.
  Lasting system changes belong in the image repo (`recipes/recipe.yml` and `files/`
  on GitHub), not on this machine.
- Apps: prefer Flatpak (`flatpak install flathub ...`), then Homebrew (`brew`).
  Use `rpm-ostree install` only as a last resort and say so first, because it slows updates.
- System updates: `ujust update`. Undo a bad update: `rpm-ostree rollback`, then reboot.
- Desktop settings live in `~/.config` (kdeglobals, plasma-org.kde.plasma.desktop-appletsrc,
  kwinrc, ...). Change them with `kwriteconfig6` or Plasma scripting via
  `qdbus-qt6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '...'`.
- Restart the desktop shell after edits: `systemctl --user restart plasma-plasmashell`.

## Rules
1. **Before changing any desktop, layout, theme or app setting, run `kenai-backup <short-label>`.**
   Tell Kai he can undo with `kenai-undo`.
2. Explain what you're about to change in one or two plain sentences before doing it.
3. **Never** touch disks, partitions, bootloaders or EFI entries, other than through
   `kenai-reboot-windows`. Windows lives on a separate drive; never mount it read-write.
4. Never run `rpm-ostree reset`, `rpm-ostree rebase`, or delete files outside `~/.config`,
   `~/.local` and `~/.cache` without Kai's explicit OK.
5. Kai prefers direct, short answers and a clear recommendation over a list of options.

## Kenai commands
| Command | What it does |
|---|---|
| `kenai-theme` | Re-apply the Ember theme, icons, dock and widgets |
| `kenai-backup <label>` / `kenai-undo` | Save / restore desktop settings |
| `kenai-switch` | Controller UI to restart into Windows |
| `kenai-odysseus start\|stop\|status\|logs` | Local AI (Odysseus + Ollama on the GPU) |
| `ujust kenai-bootsplash` | Turn on the Kenai boot animation |

## Hardware
Ryzen 7 9800X3D · RTX 4080 Super · 1440p 480 Hz OLED · controller for single-player games.
Valorant, Apex and Destiny 2 run on Windows only (anti-cheat) — don't try to get them working here.

## Other Kenai machines
- `kenai-server` (NAS: Plex, storage, AI) — **not built yet.** When it exists, reach it with
  `ssh kenai-server` using a limited account, and keep its app configs in a git repo so every
  change can be reverted.
