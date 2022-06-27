package;

import openfl.utils.Assets;
import haxe.Json;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import flixel.FlxSprite;

using StringTools;

typedef IconFile = {
	var ?noAntialiasing:Bool;
	var ?fps:Int; //Will only affect icons from Sparrow Atlas
	var ?hasWinIcon:Bool; //Will only affect icons from an icon grid, Sparrow Atlas icons have this automatically detected
}

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isOldIcon:Bool = false;
	private var isPlayer:Bool = false;
	private var char:String = '';
	var originalChar:String = 'bf-old';
	public var iconJson:IconFile;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		isOldIcon = (char == 'bf-old');
		this.isPlayer = isPlayer;
		changeIcon(char);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}

	public function swapOldIcon() {
		if (!isOldIcon) changeIcon('bf-old');
		else changeIcon(originalChar);
	}

	private var iconOffsets:Array<Float> = [0, 0];
	public function changeIcon(char:String) {
		if (this.char != char) {
			iconJson = getFile(char);
			var name:String = 'icons/$char';
			if (!Paths.fileExists('images/$name.png', IMAGE)) {
				name = 'icons/icon-$char'; //Older versions of psych engine's support
			}
			if (!Paths.fileExists('images/$name.png', IMAGE)) {
				name = 'icons/icon-face'; //Prevents crash from missing icon
			}
			if (Paths.fileExists('images/$name.xml', TEXT)) {
				frames = Paths.getSparrowAtlas(name);
				animation.addByPrefix('normal', 'normal', iconJson.fps, iconJson.fps > 0, isPlayer);
				animation.addByPrefix('losing', 'losing', iconJson.fps, iconJson.fps > 0, isPlayer);
				animation.addByPrefix('winning', 'winning', iconJson.fps, iconJson.fps > 0, isPlayer);
				if (animation.getByName('winning') == null) { //No winning icon
					animation.addByPrefix('winning', 'normal', iconJson.fps, iconJson.fps > 0, isPlayer);
				}
				animation.play('normal');
			} else {
				var file = Paths.image(name);
				loadGraphic(file); //Load stupidly first for getting the file size
				loadGraphic(file, true, Math.floor(width / (iconJson.hasWinIcon ? 3 : 2)), Math.floor(height)); //Then load it fr

				animation.add('normal', [0], 0, false, isPlayer);
				animation.add('losing', [1], 0, false, isPlayer);
				animation.add('winning', [iconJson.hasWinIcon ? 2 : 0], 0, false, isPlayer);
				animation.play('normal');
			}
			iconOffsets[0] = (width - 150) / 2;
			iconOffsets[1] = (width - 150) / 2;
			updateHitbox();
			this.char = char;
			if (char != 'bf-old') originalChar = char;

			antialiasing = ClientPrefs.globalAntialiasing && !iconJson.noAntialiasing;

			isOldIcon = (char == 'bf-old');
		}
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}

	public function getCharacter():String {
		return char;
	}

	public static function getFile(name:String):IconFile {
		var characterPath:String = 'images/icons/$name.json';
		#if MODS_ALLOWED
		var path:String = Paths.modFolders(characterPath);
		if (!FileSystem.exists(path)) {
			path = Paths.getPreloadPath(characterPath);
		}

		if (!FileSystem.exists(path))
		#else
		var path:String = Paths.getPreloadPath(characterPath);
		if (!Assets.exists(path))
		#end
		{
			path = Paths.getPreloadPath('images/icons/bf.json'); //If a character couldn't be found, change them to BF just to prevent a crash
		}

		#if MODS_ALLOWED
		var rawJson = File.getContent(path);
		#else
		var rawJson = Assets.getText(path);
		#end

		if (rawJson == null) {
			return null;
		}

		var json:IconFile = cast Json.parse(rawJson);
		if (json.noAntialiasing == null) json.noAntialiasing = false;
		if (json.fps == null) json.fps = 24;
		if (json.hasWinIcon == null) json.hasWinIcon = false;
		return json;
	}
}
