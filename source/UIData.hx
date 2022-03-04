package;

import haxe.Json;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import lime.utils.Assets;

using StringTools;

typedef SkinFile = {
    var name:String; //just an internal name to make things easier
	var mania:Array<ManiaArray>; //data for key amounts
    var scale:Float; //overall scale (added ontop of all other scales)
    var noteScale:Float; //additional note scale
    var sustainYScale:Float; //additional sustain note height scale
    var countdownScale:Float; //countdown sprites scale
    var ratingScale:Float; //rating and 'combo' sprites scale
    var comboNumScale:Float; //combo numbers scale
    var sustainXOffset:Float; //sustain note x offset
    var downscrollTailYOffset:Null<Float>; //sustain end y offset (for downscroll only)
    var noAntialiasing:Bool; //whether to always have antialiasing disabled
    var isPixel:Null<Bool>; //if this skin is based off the week 6 one
    var introSoundsSuffix:String; //suffix for the countdown sounds
}

typedef OldSkin = {
    var tailYOffset:Null<Float>; //was renamed to be more clear as there's no ui editor yet
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
        var daFile:SkinFile = null;
        var rawJson:String = null;
        var path:String = Paths.getPreloadPath('images/uiskins/$skin.json');
    
        #if MODS_ALLOWED
        var modPath:String = Paths.modFolders('images/uiskins/$skin.json');
        if (FileSystem.exists(modPath)) {
            rawJson = File.getContent(modPath);
        } else if (FileSystem.exists(path)) {
            rawJson = File.getContent(path);
        }
        #else
        if (Assets.exists(path)) {
            rawJson = Assets.getText(path);
        }
        #end
        else
        {
            return null;
        }
        daFile = cast Json.parse(rawJson);
        daFile.name = skin;
        
        var testyFile:OldSkin = cast Json.parse(rawJson);
        if (daFile.downscrollTailYOffset == null && testyFile.tailYOffset != null) {
            daFile.downscrollTailYOffset = testyFile.tailYOffset;
        }
        if (daFile.isPixel == null) {
            daFile.isPixel = false;
        }
        
        return daFile;
    }

    public static function checkImageFile(file:String, uiSkin:SkinFile):String {
        var path:String = 'uiskins/${uiSkin.name}/$file';
		#if MODS_ALLOWED
		if (!Assets.exists(Paths.getPath('images/$path.png', IMAGE)) && !FileSystem.exists(Paths.modFolders('images/$path.png'))) {
		#else
		if (!Assets.exists(Paths.getPath('images/$path.png', IMAGE))) {
		#end
            path = file; //check for it outside of 'uiskins'
            #if MODS_ALLOWED
            if (!Assets.exists(Paths.getPath('images/$path.png', IMAGE)) && !FileSystem.exists(Paths.modFolders('images/$path.png'))) {
            #else
            if (!Assets.exists(Paths.getPath('images/$path.png', IMAGE))) {
            #end
                if (uiSkin.isPixel && Paths.fileExists('images/uiskins/pixel/$file.png', IMAGE)) {
			        path = 'uiskins/pixel/$file';
                } else {
                    path = 'uiskins/default/$file';
                }
            }
		}
        return path;
    }

    public static function checkSkinFile(file:String, uiSkin:SkinFile):SkinFile {
        var path:String = 'uiskins/${uiSkin.name}/$file';
		#if MODS_ALLOWED
		if (!Assets.exists(Paths.getPath('images/$path.png', IMAGE)) && !FileSystem.exists(Paths.modFolders('images/$path.png'))) {
		#else
		if (!Assets.exists(Paths.getPath('images/$path.png', IMAGE))) {
		#end
            path = file; //check for it outside of 'uiskins'
            #if MODS_ALLOWED
            if (!Assets.exists(Paths.getPath('images/$path.png', IMAGE)) && !FileSystem.exists(Paths.modFolders('images/$path.png'))) {
            #else
            if (!Assets.exists(Paths.getPath('images/$path.png', IMAGE))) {
            #end
                if (uiSkin.isPixel && Paths.fileExists('images/uiskins/pixel/$file.png', IMAGE)) {
                    return getUIFile('pixel');
                } else {
                    return getUIFile('');
                }
            }
		}
        return uiSkin;
    }
}