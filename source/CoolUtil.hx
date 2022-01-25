package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import openfl.utils.Assets;
import Type.ValueType;
#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

class CoolUtil
{
	public static var defaultDifficulties:Array<String> = [
		'Easy',
		'Normal',
		'Hard'
	];
	public static var defaultDifficulty:String = 'Normal'; //The chart that has no suffix and starting difficulty on Freeplay/Story Mode

	public static var difficulties:Array<String> = [];

	public static function getDifficultyFilePath(num:Null<Int> = null)
	{
		if(num == null) num = PlayState.storyDifficulty;

		var fileSuffix:String = difficulties[num];
		if(fileSuffix != defaultDifficulty)
		{
			fileSuffix = '-' + fileSuffix;
		}
		else
		{
			fileSuffix = '';
		}
		return Paths.formatToSongPath(fileSuffix);
	}

	public static function difficultyString():String
	{
		return difficulties[PlayState.storyDifficulty].toUpperCase();
	}

	inline public static function boundTo(value:Float, min:Float, max:Float):Float {
		return Math.max(min, Math.min(max, value));
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = [];
		#if sys
		if(FileSystem.exists(path)) daList = File.getContent(path).trim().split('\n');
		#else
		if(Assets.exists(path)) daList = Assets.getText(path).trim().split('\n');
		#end

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}
	public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}
	public static function dominantColor(sprite:flixel.FlxSprite):Int{
		var countByColor:Map<Int, Int> = [];
		for(col in 0...sprite.frameWidth){
			for(row in 0...sprite.frameHeight){
			  var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
			  if(colorOfThisPixel != 0){
				  if(countByColor.exists(colorOfThisPixel)){
				    countByColor[colorOfThisPixel] =  countByColor[colorOfThisPixel] + 1;
				  }else if(countByColor[colorOfThisPixel] != 13520687 - (2*13520687)){
					countByColor[colorOfThisPixel] = 1;
				  }
			  }
			}
		 }
		var maxCount = 0;
		var maxKey:Int = 0;//after the loop this will store the max color
		countByColor[flixel.util.FlxColor.BLACK] = 0;
		for(key in countByColor.keys()){
			if(countByColor[key] >= maxCount){
				maxCount = countByColor[key];
				maxKey = key;
			}
		}
		return maxKey;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}

	//uhhhh does this even work at all? i'm starting to doubt
	public static function precacheSound(sound:String, ?library:String = null):Void {
		var EmbeddedSound = Paths.sound(sound, library);
		if (Assets.exists(EmbeddedSound, SOUND) || Assets.exists(EmbeddedSound, MUSIC))
			Assets.getSound(EmbeddedSound, true);
	}

	public static function browserLoad(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	public static function getDifficulties(?song:String = '', ?remove:Bool = false) {
		song = Paths.formatToSongPath(song);
		difficulties = defaultDifficulties.copy();
		var diffStr:String = WeekData.getCurrentWeek().difficulties;
		if((diffStr == null || diffStr.length == 0) && song.length > 0) {
			var num:Int = 0;
			for (i in WeekData.weeksLoaded.keys()) {
				var songs:Array<Dynamic> = WeekData.weeksLoaded.get(i).songs;
				for (daSong in songs) {
					var name:String = daSong[0];
					name.toLowerCase().trim();
					if (name == song) {
						PlayState.storyWeek = num;
						diffStr = WeekData.getCurrentWeek().difficulties;
						//trace('found difficulties');
						break;
					}
				}
				num++;
			}
		}
		if(diffStr == null || diffStr.length == 0) diffStr = 'Easy,Normal,Hard';
		diffStr = diffStr.trim(); //Fuck you HTML5

		if(diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.split(',');
			var i:Int = diffs.length - 1;
			while (i > 0)
			{
				if(diffs[i] != null)
				{
					diffs[i] = diffs[i].trim();
					if(diffs[i].length < 1) diffs.remove(diffs[i]);
				}
				else
				{
					diffs.remove(diffs[i]);
				}
				--i;
			}
			
			if (remove && song.length > 0) {
				for (i in 0...diffs.length) {
					var suffix = '-' + Paths.formatToSongPath(diffs[i]);
					if (Paths.formatToSongPath(diffs[i]) == defaultDifficulty.toLowerCase()) {
						suffix = '';
					}
					var poop:String = song + suffix;
					#if MODS_ALLOWED
					if (!FileSystem.exists(Paths.modsJson('$song/$poop')) && !FileSystem.exists(Paths.json('$song/$poop')))
					#else
					if (!Assets.exists(Paths.json('$song/$poop')))
					#end
					{
						diffs.remove(diffs[i]);
					}
				}
			}

			if(diffs.length > 0 && diffs[0].length > 0)
			{
				difficulties = diffs;
			}
		}
	}

	public static function getProperty(variable:String):Dynamic {
		var killMe:Array<String> = variable.split('.');
		if(killMe.length > 1) {
			var coverMeInPiss:Dynamic = Reflect.getProperty(FlxG.state, killMe[0]);

			for (i in 1...killMe.length-1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			return Reflect.getProperty(coverMeInPiss, killMe[killMe.length-1]);
		}
		return Reflect.getProperty(FlxG.state, variable);
	}

	public static function setProperty(variable:String, value:Dynamic) {
		var killMe:Array<String> = variable.split('.');
		if(killMe.length > 1) {
			var coverMeInPiss:Dynamic = Reflect.getProperty(FlxG.state, killMe[0]);

			for (i in 1...killMe.length-1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			return Reflect.setProperty(coverMeInPiss, killMe[killMe.length-1], value);
		}
		return Reflect.setProperty(FlxG.state, variable, value);
	}

	public static function getPropertyFromGroup(obj:String, index:Int, variable:Dynamic):Dynamic {
		if(Std.isOfType(Reflect.getProperty(FlxG.state, obj), FlxTypedGroup)) {
			return getGroupStuff(Reflect.getProperty(FlxG.state, obj).members[index], variable);
		}

		var leArray:Dynamic = Reflect.getProperty(FlxG.state, obj)[index];
		if(leArray != null) {
			if(Type.typeof(variable) == ValueType.TInt) {
				return leArray[variable];
			}
			return getGroupStuff(leArray, variable);
		}
		trace("Object #" + index + " from group: " + obj + " doesn't exist!");
		return null;
	}

	public static function setPropertyFromGroup(obj:String, index:Int, variable:Dynamic, value:Dynamic) {
		if(Std.isOfType(Reflect.getProperty(FlxG.state, obj), FlxTypedGroup)) {
			setGroupStuff(Reflect.getProperty(FlxG.state, obj).members[index], variable, value);
			return;
		}

		var leArray:Dynamic = Reflect.getProperty(FlxG.state, obj)[index];
		if(leArray != null) {
			if(Type.typeof(variable) == ValueType.TInt) {
				leArray[variable] = value;
				return;
			}
			setGroupStuff(leArray, variable, value);
		}
	}

	public static function getPropertyFromClass(classVar:String, variable:String):Dynamic {
		var killMe:Array<String> = variable.split('.');
		if(killMe.length > 1) {
			var coverMeInPiss:Dynamic = Reflect.getProperty(Type.resolveClass(classVar), killMe[0]);
			for (i in 1...killMe.length-1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			return Reflect.getProperty(coverMeInPiss, killMe[killMe.length-1]);
		}
		return Reflect.getProperty(Type.resolveClass(classVar), variable);
	}

	public static function setPropertyFromClass(classVar:String, variable:String, value:Dynamic) {
		var killMe:Array<String> = variable.split('.');
		if(killMe.length > 1) {
			var coverMeInPiss:Dynamic = Reflect.getProperty(Type.resolveClass(classVar), killMe[0]);
			for (i in 1...killMe.length-1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			return Reflect.setProperty(coverMeInPiss, killMe[killMe.length-1], value);
		}
		return Reflect.setProperty(Type.resolveClass(classVar), variable, value);
	}

	public static function getGroupStuff(leArray:Dynamic, variable:String):Dynamic {
		var killMe:Array<String> = variable.split('.');
		if(killMe.length > 1) {
			var coverMeInPiss:Dynamic = Reflect.getProperty(leArray, killMe[0]);
			for (i in 1...killMe.length-1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			return Reflect.getProperty(coverMeInPiss, killMe[killMe.length-1]);
		}
		return Reflect.getProperty(leArray, variable);
	}

	public static function setGroupStuff(leArray:Dynamic, variable:String, value:Dynamic) {
		var killMe:Array<String> = variable.split('.');
		if(killMe.length > 1) {
			var coverMeInPiss:Dynamic = Reflect.getProperty(leArray, killMe[0]);
			for (i in 1...killMe.length-1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			Reflect.setProperty(coverMeInPiss, killMe[killMe.length-1], value);
			return;
		}
		Reflect.setProperty(leArray, variable, value);
	}
}
