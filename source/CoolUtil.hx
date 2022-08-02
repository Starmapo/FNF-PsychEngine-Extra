package;

import flixel.math.FlxMath;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import lime.app.Application;
import lime.graphics.Image;

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

	inline public static function quantize(f:Float, snap:Float){
		// changed so this actually works lol
		var m:Float = Math.fround(f * snap);
		return (m / snap);
	}

	public static function getDifficultyFilePath(?num:Int = null)
	{
		if (num == null) num = PlayState.storyDifficulty;
		if (num >= difficulties.length) num = difficulties.length - 1;

		var fileSuffix:String = difficulties[num];
		if (fileSuffix == null) {
			fileSuffix = '';
		} else {
			if (fileSuffix != defaultDifficulty)
			{
				fileSuffix = '-$fileSuffix';
			}
			else
			{
				fileSuffix = '';
			}
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

	public static function coolTextFile(path:String)
	{
		var daList:Array<String> = [];
		if (Paths.exists(path, TEXT))
			daList = Paths.getContent(path).trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function coolArrayTextFile(path:String)
	{
		var daList:Array<String> = [];
		var daArray:Array<Array<String>> = [];
		if (Paths.exists(path, TEXT))
			daList = Paths.getContent(path).trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		for (i in daList) {
			daArray.push(i.split(' '));
		}

		return daArray;
	}
	
	public static function dominantColor(sprite:FlxSprite):Int {
		var countByColor:Map<Int, Int> = [];
		for (col in 0...sprite.frameWidth) {
			for (row in 0...sprite.frameHeight) {
			  var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
			  if (colorOfThisPixel != 0) {
				  if (countByColor.exists(colorOfThisPixel)) {
				    countByColor[colorOfThisPixel] =  countByColor[colorOfThisPixel] + 1;
				  } else if (countByColor[colorOfThisPixel] != 13520687 - (2*13520687)) {
					countByColor[colorOfThisPixel] = 1;
				  }
			  }
			}
		 }
		var maxCount = 0;
		var maxKey:Int = 0;//after the loop this will store the max color
		countByColor[FlxColor.BLACK] = 0;
		for (key in countByColor.keys()) {
			if (countByColor[key] >= maxCount) {
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
			dumbArray.push(i);
		return dumbArray;
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
		if (!PlayState.isStoryMode) {
			var meta = Song.getMetaFile(song);
			if (meta.freeplayDifficulties != null && meta.freeplayDifficulties.length > 0) diffStr = meta.freeplayDifficulties;
		}
		if (diffStr == null || diffStr.length == 0) diffStr = 'Easy,Normal,Hard';
		diffStr = diffStr.trim(); //Fuck you HTML5

		if (diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.split(',');
			var i = 0;
			var len = diffs.length;
			while (i < len)
			{
				if (diffs[i] != null)
				{
					diffs[i] = diffs[i].trim();
					if (diffs[i].length < 1 || diffs[i] == null) {
						diffs.remove(diffs[i]);
					} else {
						i++;
					}
				}
				else
				{
					diffs.remove(diffs[i]);
				}
				len = diffs.length;
			}
			
			if (remove && song.length > 0) {
				var i = 0;
				var len = diffs.length;
				while (i < len) {
					if (diffs[i] != null) {
						var suffix = '-${Paths.formatToSongPath(diffs[i])}';
						if (diffs[i] == defaultDifficulty) {
							suffix = '';
						}
						var poop:String = song + suffix;
						if (!Paths.existsPath('data/$song/$poop.json', TEXT)) {
							diffs.remove(diffs[i]);
						} else {
							i++;
						}
					} else {
						diffs.remove(diffs[i]);
					}
					len = diffs.length;
				}
			}

			if (diffs.length > 0 && diffs[0].length > 0)
			{
				difficulties = diffs;
			}
		}
	}

	public static function setWindowIcon(image:String = 'iconOG') {
		Image.loadFromFile(Paths.getPath('images/$image.png', IMAGE)).onComplete(function (img) {
			Application.current.window.setIcon(img);
		});
	}

	public static function playMenuMusic(volume:Float = 1) {
		FlxG.sound.playMusic(Paths.music('freakyMenu'), volume * ClientPrefs.menuMusicVolume);
	}

	public static function playScrollSound(volume:Float = 0.4) {
		FlxG.sound.play(Paths.sound('scrollMenu'), volume);
	}

	public static function playConfirmSound(volume:Float = 0.7) {
		FlxG.sound.play(Paths.sound('confirmMenu'), volume);
	}

	public static function playCancelSound(volume:Float = 0.7) {
		FlxG.sound.play(Paths.sound('cancelMenu'), volume);
	}

	public static function sortAlphabetically(a:String, b:String):Int {
		var val1 = a.toUpperCase();
		var val2 = b.toUpperCase();
		if (val1 < val2) {
		  return -1;
		} else if (val1 > val2) {
		  return 1;
		} else {
		  return 0;
		}
	}

	public static function inPlayState(skipPvP:Bool = false) {
		return PlayState.instance != null || (!skipPvP && pvp.PvPPlayState.instance != null);
	}

	public static function inPvPState(skipPvP:Bool = false) {
		return pvp.PvPPlayState.instance != null;
	}

	public static function getPlayState():Dynamic {
		return pvp.PvPPlayState.instance != null ? pvp.PvPPlayState.instance : PlayState.instance;
	}

	public static function alert(message:String, title:String = 'Error!') {
		#if desktop
		Application.current.window.alert(message, title);
		#end
	}

	public static function getCamFollowCharacter(char:Character):Dynamic {
		return {
			x: ((char.x * char.scrollFactor.x) - (char.width - (char.width / char.jsonScale)) / 2) + (char.width / 2),
			y: ((char.y * char.scrollFactor.y) - (char.height - (char.height / char.jsonScale)) / 2) + (char.height / 4)
		};
	}

	public static function scrollSpeedFromBPM(bpm:Float, denominator:Int = 4, noteSize:Float = 112) {
		var stepCrochet = (((60 / bpm) * 4000) / denominator) / 4;
		var noteY = 0.45 * stepCrochet;
		return FlxMath.roundDecimal(noteSize / noteY, 2);
	}
}