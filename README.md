# Catapult

**Catapult** is a cross-platform launcher and content manager for [Cataclysm: Dark Days Ahead](https://github.com/CleverRaven/Cataclysm-DDA) and [Cataclysm: Bright Nights](https://github.com/cataclysmbnteam/Cataclysm-BN). It is in part inspired by earlier versions of [Rémy Roy's launcher](https://github.com/remyroy/CDDA-Game-Launcher).

[**Download latest release**](https://github.com/qrrk/Catapult/releases/latest)  |  [**See all releases**](https://github.com/qrrk/Catapult/releases)



![Catapult UI](catapult_ui.gif)

## Features

- Automatic game download and installation (stable or experimental releases).
- Updating the game while preserving user data (saved games, settings, mods, etc).
- Mod management: [Kenan Modpack](https://github.com/Kenan2000/CDDA-Kenan-Modpack) download and complete or selective installation.
- Automatic download and installation of soundpacks.
- Customization of game fonts.
- Saved game backups.
- Multilingual interface.
- Fully portable and can be carried on a removable drive.
- Good support for HiDPI displays: UI is automatically scaled with screen DPI, with ability to adjust the scale manually.

## Installation

None required. The launcher is a single, self-contained executable. Just [download](https://github.com/qrrk/Catapult/releases/latest) it to a separate folder and run.

- Be sure you have write permission in that folder.
- On Linux, [make the file executable](https://askubuntu.com/a/485001) before running it.

## System requirements

- 64-bit operating system.
- Windows 7+ or Linux/X11.
- OpenGL 2.1 support.

## Future plans

These are tentative. They may or may not come to fruition.

- ~~Translations~~. *Done! (Translation infrasctructure is implemented; currently English, Russian and Simplified Chinese are available; other contributions welcome!)*
- ~~Setting in-game font from the launcher.~~ *Done!*
- ~~Backups for user data.~~ *Savegame backups added!*
- Multiple launcher UI themes.
- Download and installation of tilesets?
  (Only if there are at least a couple of finished tilesets out there that don't already come with both games.)
- Some kind of built-in knowledge base similar to Chezzo's [Item Browser](http://www.cdda-trunk.chezzo.com/).
- *Maybe* an OSX version some day.

## Why I am making yet another launcher

I had had ideas about making my own launcher for a couple years, but it didn't go beyond small demos until August 2021. The main reasons for me to start active work on it were that:

- there was no launcher for Linux with a GUI;
- there was no launcher for C:BN with advanced features, such as mod and soundpack management.

I thought, wouldn't it be nice if a unified launcher existed that was cross-platform and supported both forks of the game. I decided: well, if the thing I want isn't there on the internets, I guess I'll just *make* it!

My selection of tools wasn't great, since I wanted the app to be cross-platform and ship as one self-contained executable, like remyroy's launcher used to. I initially started making it with Python/Gtk/PyInstaller, but the latter didn't want to cooperate, especially on Windows. I started looking into other options, but nothing quite fit the requirements.

I was almost desperate enough to use Electron, but then I remembered about my old buddy [Godot](https://godotengine.org/), with which I had some limited experience. I knew that it had a good UI system, and some non-game desktop apps had already been made with it. After some prototyping it seemed like it was going to work. Of course, Godot apps aren't as lightweight as fully native binaries, but they are nowhere near Electron in terms of size and resource usage. I think you'll agree that it would have been awkward if a game launcher was heavier than the game itself!

Once I confirmed that Godot was a good fit, I moved the project to it and started fleshing it out. I worked in secret, since I have a nasty habit of burning out and losing interest half-way though projects, so I didn't want to announce anything until some kind of MVP was achieved. Therefore, the first public release of the launcher is already in a fairly finished state.

I am an amateur, and developing something for the public and with a clear practical purpose is new to me, so feedback and criticism are welcome (constructive or not, I can take it).
