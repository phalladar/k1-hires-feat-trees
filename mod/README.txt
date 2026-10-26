K1 High-Res Feat & Power Trees 1.0.0
====================================

Star Wars: Knights of the Old Republic (2003), PC.

WHAT IT FIXES
-------------
With KotOR High Resolution Menus installed, the feat and Force power selection screens (character
creation and level-up) still draw their icons at the size the game hardcodes for 640x480. At 1440p
the icons are about 40 pixels tall in a list built for icons three times that size; at 4K they are
smaller still.

This mod scales the feat and Force power tree icons, and the arrows between them, by the same factor
High Resolution Menus uses for everything else (your menu height / 480). The trees keep their
original proportions:

    menu height    icons     arrows
    1080           90 px     72 px
    1440           120 px    96 px
    2160           180 px    128 px

WHY HIGH RESOLUTION MENUS CAN'T FIX THIS
----------------------------------------
These sizes are not in any .gui file. The engine ignores the list's PROTOITEM and builds every
tree row with a fixed 40 px height in code, so only an executable patch can change them.

REQUIREMENTS (install in this order)
------------------------------------
  1. KOTOR Editable Executable    Steam only - the Steam exe is packed and cannot be patched.
                                  GOG players skip this step.
  2. UniWS                        widescreen resolutions
  3. KotOR High Resolution Menus  menus rebuilt for your resolution
  4. This mod

It changes 15 bytes in swkotor.exe and nothing in Override, and doesn't change the exe's size. It's
tested together with K1 Area Map Fixes and the 4 GB / LAA patch, in either order. It doesn't
overlap K1 Ultrawide Letterbox Fix's published offsets, but that combination is untested.

INSTALL
-------
Double-click Install.bat. It finds your game (Steam, GOG or this folder's parent), reads your menu
size from High Resolution Menus' changes to swkotor.exe, makes a backup
(swkotor.exe.before-feat-trees.bak) and patches.

If it can't find your game, it asks for the folder. To set the size yourself:
    powershell -ExecutionPolicy Bypass -File K1FeatTrees.ps1 -Height 1440

If you later change resolution with High Resolution Menus, run Install.bat again.

UNINSTALL
---------
Double-click Uninstall.bat. It writes the original values back to the exe, so it doesn't undo
mods you installed afterwards.

COMPATIBILITY NOTES
-------------------
- The patcher checks the instruction bytes around each change and refuses any exe it doesn't
  recognise, without changing it.
- Not tested with KOTOR Patch Manager or the 4-CD retail exe.
- KOTOR 2 / TSL is a different engine build and is not supported.

Byte-level details are in TECHNICAL.txt.

PERMISSIONS
-----------
MIT licensed (see LICENSE). Include it in builds, mod lists and compilations, with or without
asking.
