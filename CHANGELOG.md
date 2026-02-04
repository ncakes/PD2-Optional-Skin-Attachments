# Changelog

## v4.0.1

*2026-02-04 - Update 242.2*

- Fixed an issue where default color pattern scale was being applied to weapon skins (thanks AkiraDragunDaishiyu).

## v4.0

*2026-02-02 - Update 242.2*

- Major overhaul for compatibility with Super Duper Skin Swapper.
- Streamlined options and reduced the number of dialog menus. Only one confirmation dialog is shown when applying a skin and the "Keep Attachments" option is highlighted by default.
- Added an option to disable warning dialog when attachments could not be kept.
- Legendary weapons:
	- Legendary attachments are now shown on Akimbo Kobus 90 and Akimbo Judge.
	- First generation legendary weapon support is now a single toggle in the options menu. Automatically enabled when using Super Duper Skin Swapper.
	- Second generation legendary weapons can always be renamed.
	- Prompt to unlock legendary skins for customization has been removed.
- Custom weapon skins:
	- Attachments on BeardLib custom weapon skins disabled by default. If a custom weapon skin grants you access to a DLC attachment you don't own, it will lead to a cheater tag. (Only an issue for custom weapon skins, real weapon skins override DLC checks.)
	- Tempfix for custom BeardLib skins that use the old weapon icon path.
- Fixed a bug in the base game where skins were not sorted in the correct order.
- Tempfix for a bug in the base game where some skin-included attachments are added to your inventory.
	- Since U242, some skin-included attachments for single/akimbo weapons are stored in a separate list (`special_blueprint`) due to compatibility issues between the single and akimbo version (e.g. sights are not available on akimbos). Not all checks in the base game have been updated to use the extra list.
	- OSA overwrites `BlackMarketManager:_set_weapon_cosmetics` so this bug will not occur when switching skins.
	- Tempfix for `BlackMarketManager:modify_weapon` to prevent this bug from occurring when changing attachments.
- Removed features:
	- U242 Vlad's Rodina texture fix removed (fixed in base game now).
	- Continental Coin autobuy threshold removed.
	- Default Immortal Python weapon color option removed.
	- Option to remove legendary attachment stats removed.
	- Localizations for Suppressed Judge Anarcho Barrel and Suppressed Raven Admiral Barrel removed.

## v3.2

*2026-01-20 - Update 242*

- Fixes for U242 courtesy of [6IX].
	- Crashfix related to Midas Touch Barrel.
	- Fix missing textures when using Vlad's Rodina skin with AK default magazine and Speed Pull Magazine.

## v3.1

*2021-05-26 - Update 207.1*

- Tempfix for an issue where the Immortal Python default weapon color option wasn't being set.

## v3.0.2

*2021-04-15 - Update 205*

- Fixed an issue in the base game that could cause a crash when the Judge Anarcho is equipped with a barrel extension (thanks Fly Action).

## v3.0.1

*2021-04-14 - Update 205*

- Hotfix for a crash when customizing weapon color (thanks Freyah).

## v3.0

*2021-04-13 - Update 205*

- Complete overhaul of the code to improve stability and performance.
- Added the option to choose wear when previewing weapons. Enabled by default.
- Save Mods On Missing Skins option is now always enabled and has been removed from the options menu.
- Leaving the options menu now automatically triggers a Steam inventory update, so your legendary attachment visibility setting is updated immediately.

## v2.0.1

*2021-04-11 - Update 205*

- Remove stats option has been modified to remove all weapon stats except for concealment in order to prevent detection risk sync issues.
- Midas Touch Barrel will now use the default position for the front sight post when equipping the Marksman Sight (to prevent the front sight post from floating in the air).

## v2.0

*2021-04-08 - Update 205*

- Fixed a crash that could occur if custom weapon skins were uninstalled without first removing them from weapons.
- Added option to set Immortal Python as default weapon color. Disabled by default.
- Added option to choose default default paint scheme for weapon colors.
- Added option to choose default wear for weapon colors.
- Added option to choose default pattern scale for weapon colors.
- Added a visual indicator when players use swapped skins (e.g. through SDSS). If a player in your lobby has equipped a swapped skin, it will be displayed as a default weapon icon over the rarity background of the skin.
- Internal changes:
	- Reworked hiding of legendary skins on akimbo weapon variants.
	- Removed a useless quickplay check.
	- Reworked handling of weapons skins with only default attachments.

## v1.9

*2020-03-30 - Update 199 Mark II Hotfix 2*

- Added the ability to customize the laser color on legendary attachments. Vlad's Rodina Laser and Santa's Slayers Laser could already use custom colors and have not been changed. List of affected attachments:
	- Admiral Barrel
	- Anarcho Barrel
	- Apex Barrel
	- Astatoz Foregrip
	- Demon Barrel
	- Mars Ultor Barrel
	- Plush Phoenix Barrel
- Fixed a bug where previewing a weapon color would completely remove the weapon texture (thanks ☢ Big Sky. (MDQ)).
- Minor/internal changes:
	- Reworked localization integration with Suppressed Raven Admiral Barrel mod.
	- Reworked BlackMarketManager:player_owns_silenced_weapon() check when SRAB is in use.
	- Fixed a bug in autobuy function.

## v1.8

*2020-03-26 - Update 199 Mark II Hotfix 2*

- Reworked method for removing unusable legendary attachments from Akimbo Kobus 90 and Akimbo Judge to prevent sync issues.

## v1.7.1

*2020-03-20 - Update 199 Mark II Hotfix 2*

- Fixed a bug where the default grip would not be removed on the Locomotive 12G and Reinfeld 880 when other grips were equipped (thanks de vuelta en el negocio).
- Fixed a bug where the default barrel extension would not be removed on the Bootleg when other barrel extensions were equipped.

## v1.7

*2020-03-20 - Update 199 Mark II Hotfix 2*

- Improved legendary attachment handling for various weapons:
	- Astatoz: Astatoz Foregrip's type has been changed to "foregrip" so that it will replace the default AMR-16 foregrip when applied to prevent clipping.
	- Big Kahuna: Big Kahuna Stock now removes the default grip to prevent clipping.
	- Demon: Demon Stock now removes the default grip to prevent clipping.
	- Mars Ultor: Mars Ultor Barrel now removes the default barrel extension to prevent clipping.
	- Vlad's Rodina: the default grip will no longer disappear when the Vlad's Rodina Stock is applied. Other grips can still be applied as normal to replace the default grip.
- Fixed the name of the Santa's Slayers Laser.

## v1.6

*2020-03-10 - Update 199 Mark II Hotfix 2*

- Choosing stat boosts disabled due to sync issue.

## v1.5

*2020-02-29 - Update 199 Mark II*

- Added support for new custom colors.
- Fixed an issue on the Raven Admiral skin where applying the Short Barrel then switching to the Admiral Barrel would cause the foregrip to disappear.
- Compatibility fixes for Suppressed Raven Admiral Barrel mod (to be released).

## v1.4

*2020-01-02 - Update 199*

- Fixed a bug in the base game where weapons could not be renamed even after the legendary skin was removed.
- Fixed a bug where autobuy would purchase stat boosts.
- Reworked code for deducting continental coins when autobuying mods.
- Reworked code for checking skins that don't contain mods.

## v1.3

*2019-12-04 - Update 198.2*

- Reworked BlackMarketGui:populate_mods function, most compatibility issues should now be resolved.
- BLT priority reverted to 0.

## v1.2

*2019-08-08 - Update 197.2*

- Choose Attachments in Previews: Added option for choosing attachments when previewing weapon skins. Enabled by default.
- Renamed "Unlock Legendary Skins" option to "Customize Legendary Skins" to prevent ambiguity.
- The ability to preview mods on legendary skins is now always enabled.

## v1.1

*2019-08-07 - Update 197.2*

- Changed BLT priority to 11 to make compatible with Blackmarket Persistent Names and WolfHUD.

## v1.0

*2019-08-04 - Update 197.2*

- Initial release.
