# NOTE: THIS ENGINE IS BEING WORKED ON AND IS NOT FULLY READY!
## It's still usable, just remember it's in prerelease state

![Psych Engine Extra](https://user-images.githubusercontent.com/85134252/153526241-9f265b56-ffd1-4452-bb61-c7500471a910.png)

# Friday Night Funkin' - Psych Engine Extra
Modified version of Psych Engine adding more stuff. (see below)

## Credits:
* Starmapo - Psych Engine Extra Coding and Arts

* Shadow Mario - Coding
* RiverOaken - Arts and Animations
* shubs - Assistant Coder
* bbpanzu - Former Coder

### Special Thanks
* KadeDev & GitHub Contributors - Made Kade Engine (some code is from there)
* Leather128 & GitHub Contributors - Made Leather Engine (some code is from there)
* srPerez - Made VS Shaggy & original 9K notes

* SqirraRNG - Chart Editor's Sound Waveform base code
* iFlicky - Delay/Combo Menu Song Composer + Dialogue Sounds
* PolybiusProxy - .MP4 Loader Extension
* Keoiki - Note Splash Animations
* Smokey - Spritemap Texture Atlas support
* Cary - OG Resolution code
* Nebula_Zorua - VCR Shader code
_____________________________________

# New Features
* Custom key amounts (1K - 13K)
* Custom time signatures (3/4, 6/8, etc.)
* Custom UI skins (notes, splashes, ratings, countdown, etc.)
* Character groups (more than one player, opponent, and GF)
* Separate voices for the player and opponent (by adding a 'VoicesDad' file)
* Gameplay Changers: Play opponent's chart, Song playback speed
* Go to options from in-game (no progress lost!)
* More Lua functions

# New Options
* Note underlays
* Instant restart after dying
* Sort Freeplay songs alphabetically
* Change instrumentals and voices volume
* Show note splashes for the opponent
* Toggle autopause when not focused on the game

# Minor Touches
* Camera bump in Freeplay (from @Stilic)
* Difficulty dropdown in charting menu (from @CerBor)
_____________________________________

## Build Instructions:
### Installing the Required Programs
First, you need to install Haxe and HaxeFlixel. I'm too lazy to write and keep updated with that setup (which is pretty simple). 
1. [Install Haxe](https://haxe.org/download/)
2. [Install HaxeFlixel](https://haxeflixel.com/documentation/install-haxeflixel/) after downloading Haxe (make sure to do `haxelib run lime setup flixel` to install the necessary libraries, basically just follow the whole guide)

You'll also need to install a couple things that involve Gits. To do this, you need to do a few things first.
1. Download [git-scm](https://git-scm.com/downloads). Works for Windows, Mac, and Linux, just select your build.
2. Follow instructions to install the application properly.
3. Run `haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc` to install Discord RPC.
4. Run `haxelib git linc_luajit https://github.com/AndreiRudenko/linc_luajit` to install LuaJIT. (Or if you don't want your mod to be able to run .lua scripts, delete the "LUA_ALLOWED" line on Project.xml)

You should have everything ready for compiling the game! Follow the guide below to continue!

### Compiling game
NOTE: If you see any messages relating to deprecated packages, ignore them. They're just warnings that don't affect compiling

#### HTML5
Compiling to browser is very simple. You just need to run `lime test html5 -debug` (remove "-debug" for official releases) in the root of the project to build and run the HTML5 version. (command prompt navigation guide can be found [here](https://ninjamuffin99.newgrounds.com/news/post/1090480))

Do note that mod compatibility and Lua scripts are disabled in HTML5.

#### Desktop
To run it from your desktop (Windows, Mac, Linux) it can be a bit more involved.

For Windows, you need to install [Visual Studio Community](https://visualstudio.microsoft.com/downloads/). While installing VSC, don't click on any of the options to install workloads. Instead, go to the individual components tab and choose the following:
* MSVC v142 - VS 2019 C++ x64/x86 build tools (Latest)
* Windows 10 SDK (10.0.17763.0)

This will take a while and requires about 4GB of space. Once that is done you can open up a command line in the project's directory and run `lime test windows -debug` (remove "-debug" for official releases). Once that command finishes (it takes forever even on a higher end PC), you can run FNF from the .exe file under export\release\windows\bin

For Mac, you need to install [Xcode](https://apps.apple.com/us/app/xcode/id497799835). After that, run `lime test mac -debug` (remove "-debug" for official releases) in the project's directory and then run the executable file in export/release/mac/bin.

For Linux, you only need to open a terminal in the project directory and run `lime test linux -debug` (remove "-debug" for official releases) and then run the executable file in export/release/linux/bin.

To build for 32-bit, just add `-32` to the `lime test` command.

`lime test windows -32`