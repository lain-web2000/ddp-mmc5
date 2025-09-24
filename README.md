# Doki Doki Panic (FDS to NES conversion)
A port of Yume Kōjō: Doki Doki Panic to the NES using the [MMC5](https://www.nesdev.org/wiki/MMC5) mapper chip's ability to map PRG-RAM from $6000-$DFFF, like the Famicom Disk System.


## Compatibility

| Emulator/Flash Cart  | Supported? |
| ------------- | ------------- |
| Mesen2 | Yes |
| Nestopia UE | Yes |
| BizHawk | Yes |
| FCEUX | Yes |
| MiSTer | Yes |
| Analogue NT Mini | Untested |
| EverDrive N8  | Yes *  |
| EverDrive N8 Pro  | Untested |
| PowerPak  | Untested |
| KrzysioCart | No |

*You will manually need to create a 32K SRAM file named after the file you copied with a .NES extension in the **EDFC\SAVE** directory and use the **SRAM to File** option to save progress. Additionally, savestates will crash the game and require the ROM to be reloaded.

## Download & Patch Instructions
[BPS Patch](https://github.com/lain-web2000/ddp-mmc5/blob/main/Yume%20Koujou%20Doki%20Doki%20Panic%20(FDS%20Conversion%20-%20MMC5%20v1.0.2).bps)

Patch this onto the following ROM:

**Yume Koujou Doki Doki Panic (Japan) (DV 2).fds**\
MD5: **dde8a651a7a57d58f1a0e6ad576f99c5**\
SHA1: **138c6821ce826efd26c04c015ca6a1463ce21d87**

Please remove any fwNES headers and if required, change the file extension from .fds to .nes\
Use a BPS patcher such as [RomPatcher JS](https://www.marcrobledo.com/RomPatcher.js/) or [Floating IPS](https://www.romhacking.net/utilities/1040/) to apply the patch.

The source code compiles with CA65.

## Credits

- Simplistic6502 - For creating the custom file loading and replacement BIOS routines for his [SMB2J MMC5](https://github.com/simplistic6502/smb2j-mmc5) project.

- Whirlwind Manu - (This is a pirate company I know) For the push start and file loading patch code lifted from their original conversion.
