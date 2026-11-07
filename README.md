# Optional Skin Attachments

## Overview

This mod allows you to choose which attachments to use when applying weapon skins and provides improved support for legendary skins. Main features:

- **Choose Skin Attachments:** Replaces the apply/remove skin confirmation dialog with a menu that allows you to choose which attachments to use. Attachments that are part of the skin will show up as "Available" to use while the skin is applied (as is the case in the base game).
- **Customize Legendary Skins:** Allow first-generation legendary skins to be fully customized. Legendary attachments will be shown in the weapon customization menu and can be used if the corresponding skin is equipped. OSA can integrate with [Add-On Legendary Attachments](https://github.com/ncakes/PD2-Add-On-Legendary-Attachments) to automatically switch between real and add-on attachments depending on availability.
- **Enhanced Preview Options:** Option to enable dialog menus for choosing wear and weapon modifications in previews.
- **Default Color Settings:** Choose a default paint scheme, color wear, and pattern scale for weapon colors.

## Additional Changes/Remarks

- Fixes a bug in the base game where skins were not being sorted correctly.
- Allows all legendary skins to be renamed.
- Various fixes to prevent visual issues/crashes when customizing legendary weapons.
- Displays a visual indicator when players use swapped skins.

## Known Issues

- U242 made the Don Pastrami Barrel block the Iron Sight. OSA removes the restriction. However, players without the mod will not see the Iron Sight on your gun and they will see you with -2 concealment.
- U242.1 made the Demon Barrel block suppressors. OSA removes this restriction. However, players without the mod will not see suppressors on your gun and they will see you with increased concealment. Your gunshots will sound loud to them but the silencer effect still works. You will not alert guards when shooting, even as a client.

If you use Add-On Legendary Attachments, the add-on versions of these attachments appear as default parts and do not have this issue for vanilla players.

## BeardLib Features

BeardLib is not required for OSA, but if BeardLib is installed, OSA will load some textures and models to improve the visual behavior of legendary attachments. This shows up in the BeardLib mods manager as "OSA Assets".

- Platypus Beak Suppressor: prevents the Beak Suppressor from glitching out when equipped on the Don Pastrami Barrel. (Originally from AOLA, thanks to Hoppip and Mercu for helping with the model).
- Kobus 90 default barrel: hides the default Kobus 90 barrel when using the Alamo Dallas Body Kit.
- Astatoz Barrel: fixes the attachment point for barrel extensions to make it centered. Courtesy of AkiraDragunDaishiyu.
- Big Kahuna Barrel: fixes the attachment point for barrel extensions so it's actually connected to the gun and not floating (also in third person). Courtesy of AkiraDragunDaishiyu.

In addition, icon textures will be loaded with BeardLib instead of using Lua fixes (they appear the same as without BeardLib).

## Compatibility

Optional Skin Attachments is compatible with [Hide Duplicate Skins](https://github.com/ncakes/PD2-Hide-Duplicate-Skins).

Optional Skin Attachments v4.0+ is compatible with [Super Duper Skin Swapper](https://github.com/ncakes/PD2-Super-Duper-Skin-Swapper) v3.0+.

## Installation

This mod requires [SuperBLT](https://superblt.znix.xyz).

Download `Optional-Skin-Attachments_<ver>.zip` from the [latest release page](https://github.com/ncakes/PD2-Optional-Skin-Attachments/releases/latest) and extract the entire contents to your `mods` folder.

```
C:\Program Files (x86)\Steam\steamapps\common\PAYDAY 2\mods
```
