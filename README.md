# Friday Night Funkin' - Psych Engine
Engine originally used on [Mind Games Mod](https://gamebanana.com/mods/301107), intended to be a fix for the vanilla version's many issues while keeping the casual play aspect of it. Also aiming to be an easier alternative to newbie coders.

## Installation:
You must have [the most up-to-date version of Haxe](https://haxe.org/download/), seriously, stop using 4.1.5, it misses some stuff.

Follow a Friday Night Funkin' source code compilation tutorial, after this you will need to install LuaJIT.

To install LuaJIT do this: `haxelib install linc_luajit` on a Command prompt/PowerShell

...Or if you don't want your mod to be able to run .lua scripts, delete the "LUA_ALLOWED" line on Project.xml

## Credits:
* Shadow Mario - Coding
* RiverOaken - Arts and Animations
* bbpanzu - Assistant Coding

* Starmapo - He copy and pasted some code????? idk
* KadeDev & GitHub Contributors - Made Kade Engine (and is smarter)
* Leather128 & GitHub Contributors - Made Leather Engine (and is smarter)

### Special Thanks
* shubs - New Input System
* SqirraRNG - Chart Editor's Sound Waveform base code
* iFlicky - Delay/Combo Menu Song Composer + Dialogue Sounds
* PolybiusProxy - .MP4 Loader Extension
* Keoiki - Note Splash Animations
* Smokey - Spritemap Texture Atlas support
_____________________________________

# New Features
* Different key amounts (4 - 9)
* Different time signatures (3/4, 2/2, etc.)
* Play opponent's chart
* Song playback speed
* More Lua functions
* Separate files for player and opponent characters

# New Options
* Sort Freeplay songs alphabetically

# Minor Touches
* Camera bump in Freeplay (@Stilic)
* Difficulty dropdown in charting menu (@CerBor)