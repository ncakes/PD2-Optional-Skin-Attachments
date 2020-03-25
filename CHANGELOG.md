# Changelog

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
