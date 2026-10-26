# Publishing checklist

1. Retake `docs/after.png` with the icon-stretch fix in, then run `python build.py`.
2. **DeadlyStream** (primary): Downloads → Knights of the Old Republic → Mods (https://deadlystream.com/files/category/6-mods/).
   Upload `dist/K1-HiRes-Feat-Trees-1.0.0.zip` and both screenshots, then paste the page text below.
   DeadlyStream files get a forum topic automatically. Link it from the comments on the KotOR High
   Resolution Menus file page, because that page is where the affected players are.
3. **Nexus Mods** (mirror): Knights of the Old Republic → Add mod → category *User Interface*. Same zip,
   screenshots and text. Set requirements to UniWS, KotOR High Resolution Menus and (for Steam) the KOTOR
   Editable Executable.
4. **GitHub** (source): make this repo public, attach the zip to a `v1.0.0` release, and link the repo from
   both mod pages.
5. **Word of mouth**: post on r/kotor with the before/after pair, mention it in the KOTOR modding Discord's
   mod-release channel, and ask the kotor.neocities.org build guide maintainers to consider it for the K1 Full
   build alongside High Resolution Menus.

## Page text

**K1 High-Res Feat & Power Trees**

Makes the feat and Force power selection icons readable at high resolutions.

KotOR High Resolution Menus rescales the menus for your resolution, but the feat and Force power trees
(character creation and level-up) keep the 640x480 sizes hardcoded in the game's executable: 40 px rows,
32 px icons and arrows. At 1440p and 4K the icons are tiny specks in a list built for icons several times
larger. This patch scales the rows, icons and arrows by the same factor High Resolution Menus uses for
everything else (menu height / 480), so the trees keep their original proportions.

- 1080p: 90 px rows · 1440p: 120 px · 4K: 180 px
- Reads your resolution from High Resolution Menus' changes to the exe. No questions asked.
- Changes 8 values in swkotor.exe and nothing in Override. It checks every byte it touches first and
  refuses unknown executables. It makes a backup, and Uninstall.bat restores the originals.
- Tested alongside K1 Area Map Fixes and the 4 GB patch.

**Requirements**, in this order: KOTOR Editable Executable (Steam only), UniWS, KotOR High Resolution
Menus, then this.

**Install:** double-click Install.bat. Run it again if you later change resolution.

Source and byte-level documentation: (GitHub link)
