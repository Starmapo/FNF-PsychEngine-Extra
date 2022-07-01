# NOTE: THIS ENGINE IS STILL BEING WORKED ON! Report any bugs in the issues page!

![Psych Engine Extra](https://user-images.githubusercontent.com/85134252/153526241-9f265b56-ffd1-4452-bb61-c7500471a910.png)

# Friday Night Funkin' - Psych Engine Extra
Modified version of Psych Engine adding more stuff, most notably higher key amounts, time signatures, and Hscript support.

## Credits:
* Starmapo - Programmer and Artist

## Special Thanks:
* KadeDev & GitHub Contributors - Made Kade Engine (some code and ideas are from there)
* Leather128 & GitHub Contributors - Made Leather Engine (some code and ideas are from there)
* srPerez - Made VS Shaggy & the original 6K+ notes

## Psych Engine Credits:
* Shadow Mario - Programmer
* RiverOaken - Artist
* Yoshubs - Assistant Programmer

### Psych Engine Special Thanks:
* bbpanzu - Ex-Programmer
* SqirraRNG - Crash Handler and Base code for Chart Editor's Waveform
* KadeDev - Fixed some cool stuff on Chart Editor and other PRs
* iFlicky - Composer of Psync and Tea Time, also made the Dialogue Sounds
* PolybiusProxy - Video Loader Library (hxCodec)
* Keoiki - Note Splash Animations
* Smokey - Sprite Atlas Support
* Nebula the Zorua - LUA JIT Fork and some Lua reworks
_____________________________________

# New Features
* Custom key amounts (currently 1K to 13K)
* Custom time signatures (1-100/1-64)
* Hscript compatibility
* Custom UI skins (custom rating sprites, countdown sprites, etc.)
* Character groups (more than one Boyfriend, opponent, or Girlfriend)
* Separate voices for the player and the opponent (by adding a 'VoicesOpponent' or 'VoicesDad' file)
* Gameplay Changers: Play as the opponent, change song (not chart, SONG) speed, demo mode (showcase gameplay)
* Go to options menu from the pause menu (and go right back to game after you're done!)

# New Options
* Note underlays
* Instant restart after dying
* Show number of ratings (sicks, goods, etc.)
* "Crappy" quality option (no stage)
* Toggle autopause when not focused on the game
* "Shit" counting as a miss
* Smooth health bar
* Save Data menu where you can clear your save data

# Minor Touches
* Camera bump in Freeplay (from @Stilic)
* Difficulty dropdown in charting menu (from @CerBor)
_____________________________________

## Build Instructions:
### Installing the Required Programs
First, you need to install the **latest** Haxe and HaxeFlixel. I'm too lazy to write and keep updated with that setup (which is pretty simple). 
1. [Install Haxe](https://haxe.org/download/)
2. [Install HaxeFlixel](https://haxeflixel.com/documentation/install-haxeflixel/) after downloading Haxe (make sure to do `haxelib run lime setup flixel` to install the necessary libraries, basically just follow the whole guide)

You should make sure to keep Haxe & Flixel updated. If there is a compilation error, it might be due to having an outdated version.

You'll also need to install a couple things that involve Gits. To do this, you need to do a few things first.
1. Download [git-scm](https://git-scm.com/downloads). Works for Windows, Mac, and Linux, just select your build.
2. Follow instructions to install the application properly.
3. Run `haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc` to install Discord RPC.
4. Run `haxelib git linc_luajit https://github.com/nebulazorua/linc_luajit` to install LuaJIT. If you get an error about StatePointer when using Lua, run `haxelib remove linc_luajit` into Command Prompt/PowerShell, then re-install linc_luajit. (If you don't want your mod to be able to run .lua scripts, delete the "LUA_ALLOWED" line on Project.xml)
5. Run `haxelib git hscript https://github.com/HaxeFoundation/hscript` to install hscript. After that, run `haxelib git hscript-ex https://github.com/ianharrigan/hscript-ex` to install hscript-ex. (If you don't want your mod to be able to run .hscript scripts, delete the "HSCRIPT_ALLOWED" line on Project.xml)
6. Run `haxelib install hxCodec` to install hxCodec for video support. (If you don't want your mod to have video support, delete the "VIDEOS_ALLOWED" line on Project.xml)

You should have everything ready for compiling the game! Follow the guide below to continue!

### Compiling game
NOTE: If you see any messages relating to deprecated packages, ignore them. They're just warnings that don't affect compiling

#### HTML5
Compiling to browser is very simple. You just need to run `lime test html5 -debug` (remove "-debug" for official releases) in the root of the project to build and run the HTML5 version. (command prompt navigation guide can be found [here](https://ninjamuffin99.newgrounds.com/news/post/1090480))

Do note that modpacks and Lua scripts are unavailable in HTML5.

#### Desktop
To run it from your desktop (Windows, Mac, Linux) it can be a bit more involved.

(NOTE: Mac and Linux have not been tested yet and they are not guaranteed to function)

For Windows, you need to install [Visual Studio Community](https://visualstudio.microsoft.com/downloads/). While installing VSC, don't click on any of the options to install workloads. Instead, go to the individual components tab and choose the following:
* MSVC v142 - VS 2019 C++ x64/x86 build tools (Latest)
* Windows 10 SDK (10.0.17763.0)

This will take a while and requires about 4GB of space. Once that is done you can open up a command line in the project's directory and run `lime test windows -debug` (remove "-debug" for official releases). Once that command finishes (it takes forever even on a higher end PC), it will automatically run the game. The .exe file will be under export\release\windows\bin.

For Mac, you need to install [Xcode](https://apps.apple.com/us/app/xcode/id497799835). After that, run `lime test mac -debug` (remove "-debug" for official releases) in the project's directory. The .exe file will be in export/release/mac/bin.

For Linux, you only need to open a terminal in the project directory and run `lime test linux -debug` (remove "-debug" for official releases). The executable file will be in export/release/linux/bin.

To build for 32-bit, add `-32 -D 32bits` to the `lime test` command:

`lime test windows -32 -D 32bits`

#### Android
(NOTE: Android support is currently experimental and has not been tested on an actual device yet)

All credit to the [Funkin-android repository](https://github.com/luckydog7/Funkin-android) for the entire tutorial.

1. Download [Android Studio](https://developer.android.com/studio), the [Java Development Kit](https://www.oracle.com/java/technologies/javase/javase-jdk8-downloads.html), and the [Android NDK (r15c)](https://github.com/android/ndk/wiki/Unsupported-Downloads#r15c). Install Android Studio and the JDK, and unzip the Android NDK somewhere in your computer.

2. In Android Studio, go to Settings -> Appearance & Behavior -> System Settings -> Android SDK. Install Android 4.4 (KitKat), Android SDK Build-Tools, and Android SDK Platform-Tools.

3. In the Command Prompt (or the Terminal), run `lime setup android`. Insert the corresponding file paths. Your Android SDK should be located in `C:\Users\*username*\AppData\Local\Android\Sdk`, and your Java JDK in `C:\Program Files\Java\jdk1.8.0_331`.

4. Run `lime build android -debug` (remove "-debug" for official releases) to build the APK. The APK will be located inside your source code directory in `export\(debug or release)\android\bin\app\build\outputs\apk`. If you have a device emulator running in Android Studio, you can instead do `lime test android` to open it in the emulator.