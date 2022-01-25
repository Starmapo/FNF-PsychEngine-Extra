# NOTE: THIS IS A WORK IN PROGRESS AND IS NOT MEANT TO BE USED YET!

# Friday Night Funkin' - Psych Engine Extra
Modified version of Psych Engine adding more stuff.

## Installation:
You must have [the most up-to-date version of Haxe](https://haxe.org/download/), seriously, stop using 4.1.5, it misses some stuff.

Follow a Friday Night Funkin' source code compilation tutorial, after this you will need to install LuaJIT.

To install LuaJIT do this: `haxelib git linc_luajit https://github.com/AndreiRudenko/linc_luajit` on a Command prompt/PowerShell

...Or if you don't want your mod to be able to run .lua scripts, delete the "LUA_ALLOWED" line on Project.xml

## Credits:
* Shadow Mario - Coding
* RiverOaken - Arts and Animations
* bbpanzu - Assistant Coding

* Starmapo - He copy and pasted some code????? idk

### Special Thanks
* KadeDev & GitHub Contributors - Made Kade Engine (and is smarter)
* Leather128 & GitHub Contributors - Made Leather Engine (and is smarter)
* srPerez - Made VS Shaggy & original 9 key notes

* shubs - New Input System
* SqirraRNG - Chart Editor's Sound Waveform base code
* iFlicky - Delay/Combo Menu Song Composer + Dialogue Sounds
* PolybiusProxy - .MP4 Loader Extension
* Keoiki - Note Splash Animations
* Smokey - Spritemap Texture Atlas support
* Cary - OG Resolution code
* Nebula_Zorua - VCR Shader code
_____________________________________

# New Features
* Custom key amounts (1 - 13)
* Custom time signatures (3/4, 4/8, etc.)
* Custom UI skins (notes, splashes, ratings, countdown, etc.)
* Gameplay Changers: Play opponent's chart, Song playback speed
* More Lua functions
* Separate files for player and opponent characters

# New Options
* Sort Freeplay songs alphabetically
* Change instrumentals and voices volume
* Show note splashes for the opponent

# Minor Touches
* Camera bump in Freeplay (from @Stilic)
* Difficulty dropdown in charting menu (from @CerBor)