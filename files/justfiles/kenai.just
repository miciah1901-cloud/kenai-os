# Kenai OS commands. Run with: ujust <name>

# Apply (or re-apply) the Kenai Ember theme, icons, dock and widgets
kenai-theme:
    /usr/bin/kenai-theme

# Undo the last desktop change (theme, layout or anything the AI changed)
kenai-undo:
    /usr/bin/kenai-undo

# Restart into Windows (controller screen)
kenai-switch:
    /usr/bin/kenai-switch

# Set up Kenai AI: Claude Code, Gemini CLI and (optionally) Odysseus
kenai-ai-setup:
    /usr/bin/kenai-ai-setup

# Install the local Odysseus AI (models run on your GPU)
kenai-odysseus:
    /usr/bin/kenai-odysseus install

# Turn on the Kenai boot splash (adds ~1 min to future updates)
kenai-bootsplash:
    #!/usr/bin/bash
    sudo plymouth-set-default-theme kenai && rpm-ostree initramfs --enable && \
    echo "Done. You'll see the Kenai splash after the next reboot."

# Turn the Kenai boot splash back off
kenai-bootsplash-off:
    #!/usr/bin/bash
    sudo plymouth-set-default-theme --reset && rpm-ostree initramfs --disable && \
    echo "Done. Back to the default splash after the next reboot."

# Open the Steam artwork for the Kenai shortcuts in Game Mode
kenai-steam-art:
    #!/usr/bin/bash
    echo "In Desktop Mode: Steam > Games > Add a Non-Steam Game > tick Kenai Switch."
    echo "Then right-click it > Manage > Set custom artwork, using the files in this folder."
    xdg-open /usr/share/kenai/steam-art >/dev/null 2>&1 &
