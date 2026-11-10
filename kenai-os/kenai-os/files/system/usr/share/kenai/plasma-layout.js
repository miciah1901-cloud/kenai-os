// Kenai OS desktop layout (Plasma 6 scripting API).
// Floating centered dock + clock / system monitor / Kenai Switch on the desktop.
var apps = [
  "kenai-gamemode.desktop",
  "org.mozilla.firefox.desktop",
  "org.kde.dolphin.desktop",
  "com.discordapp.Discord.desktop",
  "com.heroicgameslauncher.hgl.desktop",
  "org.kde.discover.desktop",
  "org.kde.konsole.desktop",
  "kenai-switch.desktop",
  "kenai-ai.desktop",
  "systemsettings.desktop"
];

panels().forEach(function (p) { p.remove(); });

var dock = new Panel;
dock.location = "bottom";
dock.height = Math.round(gridUnit * 3.6);
dock.alignment = "center";
try { dock.lengthMode = "fit"; } catch (e) {}
try { dock.floating = true; } catch (e) {}

var menu = dock.addWidget("org.kde.plasma.kickoff");
menu.currentConfigGroup = ["General"];
menu.writeConfig("icon", "kenai-logo");

var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", apps.map(function (a) { return "applications:" + a; }).join(","));

dock.addWidget("org.kde.plasma.marginsseparator");
dock.addWidget("org.kde.plasma.systemtray");
dock.addWidget("org.kde.plasma.digitalclock");

desktops().forEach(function (d) {
  if (d.screen !== 0) return;
  d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
  d.writeConfig("Image", "file:///usr/share/wallpapers/KenaiEmber/contents/images/3840x2160.png");
  try { d.addWidget("org.kde.plasma.digitalclock", 48, 48, 460, 200); } catch (e) {}
  try { d.addWidget("org.kde.plasma.systemmonitor.cpu", 48, 280, 340, 220); } catch (e) {}
  try {
    var sw = d.addWidget("org.kde.plasma.icon", 48, 530, 120, 120);
    sw.currentConfigGroup = ["General"];
    sw.writeConfig("url", "file:///usr/share/applications/kenai-switch.desktop");
  } catch (e) {}
});
