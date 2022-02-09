# NOTE: THIS IS A WORK IN PROGRESS AND IS NOT MEANT TO BE USED YET!

# Friday Night Funkin' - Psych Engine Extra
Modified version of Psych Engine adding more stuff.

## Installation:
You must have [the most up-to-date version of Haxe](https://haxe.org/download/), seriously, stop using 4.1.5, it misses some stuff.

Follow a Friday Night Funkin' source code compilation tutorial, after this you will need to install LuaJIT.

To install LuaJIT do this: `haxelib git linc_luajit https://github.com/AndreiRudenko/linc_luajit` on a Command prompt/PowerShell

...Or if you don't want your mod to be able to run .lua scripts, delete the "LUA_ALLOWED" line on Project.xml

## Credits:
* Starmapo - Psych Engine Extra stuff

* Shadow Mario - Coding
* RiverOaken - Arts and Animations
* bbpanzu - Assistant Coding

### Special Thanks
* KadeDev & GitHub Contributors - Made Kade Engine (some code is from there)
* Leather128 & GitHub Contributors - Made Leather Engine (some code is from there)
* srPerez - Made VS Shaggy & original 9K notes

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
* Custom time signatures (3/4, 8/8, etc.)
* Custom UI skins (notes, splashes, ratings, countdown, etc.)
* Character groups (more than one player, opponent, and GF)
* Gameplay Changers: Play opponent's chart, Song playback speed
* Exit to options from in-game (you can exit right back to where you left!)
* More Lua functions

# New Options
* Note underlays
* Instant restart after dying
* Sort Freeplay songs alphabetically
* Change instrumentals and voices volume
* Show note splashes for the opponent

# Minor Touches
* Camera bump in Freeplay (from @Stilic)
* Difficulty dropdown in charting menu (from @CerBor)