package;

import haxe.Json;
import lime.utils.Assets;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

typedef SkinFile = {
	var mania:Array<ManiaArray>; //data for key amounts
    var scale:Float; //overall scale (all other scales are added ontop of this one)
    var noteScale:Float; //note scale (added ontop the mania one)
    var sustainYScale:Float; //sustain note y scale
    var countdownScale:Float; //countdown sprites scale
    var ratingScale:Float; //rating and 'combo' sprites scale
    var comboNumScale:Float; //combo numbers scale
    var sustainXOffset:Float; //sustain note x offset (happens before note is scaled)
    var tailYOffset:Float; //sustain tail note y offset for downscroll
    var centerOrigin:Bool; //whether to center the strums in the confirm animation
    var antialiasing:Bool; //whether to have antialiasing enabled
}

typedef ManiaArray = {
    var keys:Int; //key amount to be attached to
    var noteSize:Float; //note scale
    var noteSpacing:Float; //spacing between each note
    var xOffset:Float; //extra offset for the strums
    var colors:Array<String>; //name order for the colors
    var directions:Array<String>; //name order for the strum directions
    var singAnimations:Array<String>; //name order for the sing animations
}

class UIData {
    public static function getUIFile(skin:String):SkinFile {
        if (skin == null || skin.length < 1) skin = 'default';
        var rawJson:String = null;
        var path:String = Paths.getPath('images/uiskins/' + skin + '.json', TEXT);
    
        #if MODS_ALLOWED
        var modPath:String = Paths.modFolders('images/uiskins/' + skin + '.json');
        if(FileSystem.exists(modPath)) {
            rawJson = File.getContent(modPath);
        } else if(FileSystem.exists(path)) {
            rawJson = File.getContent(path);
        }
        #else
        if(Assets.exists(path)) {
            rawJson = Assets.getText(path);
        }
        #end
        else
        {
            return null;
        }
        return cast Json.parse(rawJson);
    }
}