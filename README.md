# Optional Skin Attachments

## Overview

This mod allows you to choose which attachments to use when applying weapon skins and provides improved support for legendary skins. Key features and options:

- **Choose Skin Attachments:** Replaces the apply/remove skin confirmation dialog with a menu that allows you to choose which attachments to use. Attachments that are part of the skin will show up as "Available" to use while the skin is applied (as is the case in the base game).
- **Autobuy Missing Mods:** Automatically buy missing weapon attachments using Continental coins when you choose to keep your current attachments.
- **Autobuy Threshold:** Do not let Continental coins drop below this threshold when autobuying (range 0 to 200).
- **Prefer Shotgun Pack Buckshot:** Give the Gage Shotgun Pack 000 Buckshot priority when applying skins. When skins are applied or removed, the free 000 Buckshot will be replaced by the Gage Shotgun Pack 000 Buckshot if you own the Gage Shotgun Pack DLC.
- **Save Mods On Missing Skins:** Try to keep attachments when skins are removed from Steam inventory.
- **Choose Attachments in Previews:** Enable dialog menu for choosing attachments when previewing weapon skins.
- **Rename Legendary Skins:** Allow legendary skins to be renamed.
- **Customize Legendary Skins:** Allow legendary skins to be unlocked so that they can be customized.
- **Remove Legendary Mod Stats:** Remove stats from legendary weapon attachments.
- **Show Legendary Mods:** Show legendary weapon attachments in weapon customization menu so that they can be selected. Can be set to only show mods from owned legendary skins.

## Additional Changes/Remarks

- Unlike other mods, Optional Skin Attachments does not delete the list of attachments that are associated with a skin. This means that attachments that are part of the skin will show up as "Available" to use while the skin is applied, even if you don't own the DLC for the attachment (as is the case in the base game).
- The list of attachments associated with a skin is used by the game to verify whether a player is allowed to use DLC/legendary attachments. Deleting this list can cause false-positive cheater flags if the checks are not modified. This problem does not occur with Optional Skin Attachments.
- When a skin that contains the Gage Shotgun Pack 000 Buckshot is removed and you opt to keep your attachments, it will be replaced by the free 000 Buckshot if you do not own the Gage Shotgun Pack DLC.
- This mod fixes skins that don't actually have attachments included, so you will not be prompted to "Use Skin Attachments" if the skin does not actually contain attachments.
- This mod adds the ability to preview weapon modifications on locked legendary skins.
- This mod fixes a bug in the base game where weapons could not be renamed even after the legendary skin was removed.

## Known Issues

- Legendary mods on Akimbo Kobus 90 / Akimbo Judge are not validated. May implement in the future.

## Installation

This mod requires [SuperBLT](https://superblt.znix.xyz).

Download `Optional-Skin-Attachments_<ver>.zip` from the [latest release page](https://github.com/ncakes/PD2-Optional-Skin-Attachments/releases/latest) and extract the entire contents to your `mods` folder.

```
C:\Program Files (x86)\Steam\steamapps\common\PAYDAY 2\mods
```
