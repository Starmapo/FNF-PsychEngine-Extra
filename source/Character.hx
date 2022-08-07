package;

import flixel.util.FlxSort;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.input.keyboard.FlxKey;
import flixel.tweens.FlxTween;
import haxe.Json;

using StringTools;

typedef CharacterFile = {
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;

	var ?repeatHoldAnimation:Bool;
}

typedef AnimArray = {
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Float>;
}

typedef CharacterGroupFile = {
	var characters:Array<GroupCharacter>;
	var position:Array<Float>;
	var healthicon:String;
	var camera_position:Array<Float>;
	var healthbar_colors:Array<Int>;
}

typedef GroupCharacter = {
	var name:String;
	var position:Array<Float>;
}

class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Float>> = new Map();
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var colorTween:FlxTween;
	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Array<Dynamic>> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; //Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; //Character use "danceLeft" and "danceRight" instead of "idle"
	public var danceEveryNumBeats:Float = 2;
	public var keysPressed:Array<FlxKey> = [];
	public var repeatHoldAnimation:Bool = true;

	public var skipDance:Bool = false;
	public var skipSing:Bool = false;

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var playerPosition:Array<Float> = [0, 0];
	public var enemyPosition:Array<Float> = [0, 0];
	public var positionArray(get, never):Array<Float>;
	public var playerCameraPosition:Array<Float> = [0, 0];
	public var enemyCameraPosition:Array<Float> = [0, 0];
	public var cameraPosition(get, never):Array<Float>;

	public var hasMissAnimations:Bool = false;

	//Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public var flipped:Bool = false;
	public var defaultX:Float = 0;
	public var defaultY:Float = 0;

	public var addX:Float = 0;
	public var addY:Float = 0;
	public var addedToGroup:Bool = false;
	public var associatedSprites:Array<FlxSprite> = [];

	public function get_positionArray() {
		return flipped ? playerPosition : enemyPosition;
	}
	public function get_cameraPosition() {
		return flipped ? playerCameraPosition : enemyCameraPosition;
	}

	public static var DEFAULT_CHARACTER:String = 'bf'; //In case a character is missing, it will use BF on its place
	public function new(x:Float, y:Float, ?character:String = 'bf', ?flipped:Bool = false, ?debugMode:Bool = false)
	{
		super(x, y);

		curCharacter = character;
		antialiasing = ClientPrefs.globalAntialiasing;
		this.debugMode = debugMode;
		this.flipped = flipped;

		switch (curCharacter)
		{
			//case 'your character name in case you want to hardcode them instead':

			default:
				var json:CharacterFile = getFile(curCharacter);
				var dummyJson:Dynamic = getFile(curCharacter);
				var jsonPlayer = (json.flip_x == true);
				if (json.repeatHoldAnimation == null) json.repeatHoldAnimation = true;
				if (json.position == null && dummyJson.player_position != null) {
					if (jsonPlayer)
						json.position = dummyJson.player_position.copy();
					else
						json.position = dummyJson.enemy_position.copy();
				}
				if (json.camera_position == null && dummyJson.player_cameraPosition != null) {
					if (jsonPlayer)
						json.camera_position = dummyJson.player_cameraPosition.copy();
					else
						json.camera_position = dummyJson.enemy_cameraPosition.copy();
				}
				var animations:Array<Dynamic> = json.animations;
				for (anim in animations) {
					if (anim.offsets == null && anim.playerOffsets != null) {
						if (jsonPlayer)
							anim.offsets = anim.playerOffsets.copy();
						else
							anim.offsets = anim.enemyOffsets.copy();
					}
				}

				if (Paths.existsPath('images/${json.image}.txt', TEXT))
					frames = Paths.getPackerAtlas(json.image);
				else if (Paths.existsPath('images/${json.image}.json', TEXT))
					frames = Paths.getTexturePackerAtlas(json.image);
				else if (Paths.existsPath('images/${json.image}/Animation.json', TEXT))
					frames = AtlasFrameMaker.construct(json.image);	
				else
					frames = Paths.getSparrowAtlas(json.image);
				
				imageFile = json.image;

				jsonScale = json.scale;

				playerPosition = json.position.copy();
				enemyPosition = json.position.copy();
				playerCameraPosition = json.camera_position.copy();
				enemyCameraPosition = json.camera_position.copy();

				healthIcon = json.healthicon;
				singDuration = json.sing_duration;
				flipX = json.flip_x == true;
				noAntialiasing = json.no_antialiasing == true;
				repeatHoldAnimation = json.repeatHoldAnimation == true;

				if (json.healthbar_colors != null && json.healthbar_colors.length > 2)
					healthColorArray = json.healthbar_colors;

				antialiasing = ClientPrefs.globalAntialiasing && !noAntialiasing;

				animationsArray = json.animations;
				if (animationsArray != null && animationsArray.length > 0) {
					for (anim in animationsArray) {
						var animAnim:String = '${anim.anim}';
						var animName:String = '${anim.name}';
						var animFps:Int = anim.fps;
						var animLoop:Bool = anim.loop == true;
						var animIndices:Array<Int> = anim.indices;
						addAnimation(animAnim, animName, animFps, animLoop, animIndices);
						addOffset(animAnim, anim.offsets[0], anim.offsets[1]);
					}
				} else
					quickAnimAdd('idle', 'BF idle dance');
		}
		originalFlipX = flipX;

		if (flipped != originalFlipX && !debugMode) {
			for (leftAnim in animationsArray) {
				if (leftAnim.anim.startsWith('singLEFT')) {
					var rightName = 'singRIGHT' + leftAnim.anim.substr(8);
					if (animation.exists(rightName)) {
						var newRight = getAnimArray(rightName);
						var newLeft:AnimArray = {
							anim: leftAnim.anim,
							name: newRight.name,
							fps: newRight.fps,
							loop: newRight.loop == true,
							indices: newRight.indices.copy(),
							offsets: newRight.offsets.copy()
						};

						newRight.name = leftAnim.name;
						newRight.fps = leftAnim.fps;
						newRight.loop = leftAnim.loop == true;
						newRight.indices = leftAnim.indices.copy();
						newRight.offsets = leftAnim.offsets.copy();
						addAnimation(newRight.anim, newRight.name, newRight.fps, newRight.loop, newRight.indices);
						addOffset(newRight.anim, newRight.offsets[0], newRight.offsets[1]);

						leftAnim.name = newLeft.name;
						leftAnim.fps = newLeft.fps;
						leftAnim.loop = newLeft.loop;
						leftAnim.indices = newLeft.indices;
						leftAnim.offsets = newLeft.offsets.copy();
						addAnimation(leftAnim.anim, leftAnim.name, leftAnim.fps, leftAnim.loop, leftAnim.indices);
						addOffset(leftAnim.anim, leftAnim.offsets[0], leftAnim.offsets[1]);
					}
				}
			}
		}

		hasMissAnimations = (animation.exists('singLEFTmiss') || animation.exists('singDOWNmiss') || animation.exists('singUPmiss') || animation.exists('singRIGHTmiss'));
		recalculateDanceIdle();
		dance();
		scale.set(jsonScale, jsonScale);
		updateHitbox();
		setOffsets();

		if (flipped)
			flipX = !flipX;

		switch(curCharacter) {
			case 'pico-speaker':
				skipDance = true;
				loadMappedAnims();
				playAnim("shoot1");
				updateHitbox();
				setOffsets();
		}

		if (!debugMode && flipped != originalFlipX) {
			var lastAnim = '';
			if (animation.name != null)
				lastAnim = animation.name;

			if (originalFlipX) { //player character
				var daDifference = (411 - width);
				enemyPosition[0] = daDifference - enemyPosition[0];
				enemyCameraPosition[0] = -(enemyCameraPosition[0]);
				for (anim in animationsArray) {
					playAnim(anim.anim, true);
					daDifference = -(width - (frameWidth * scale.x));
					addOffset(anim.anim, (daDifference - anim.offsets[0]), anim.offsets[1]);
				}
			} else { //opponent character
				var daDifference = (429 - width);
				playerPosition[0] = daDifference - playerPosition[0];
				playerCameraPosition[0] = -(playerCameraPosition[0]);
				for (anim in animationsArray) {
					playAnim(anim.anim, true);
					daDifference = -(width - (frameWidth * scale.x));
					addOffset(anim.anim, (daDifference - anim.offsets[0]), anim.offsets[1]);
				}
			}

			if (lastAnim.length > 0)
				playAnim(lastAnim, true);
		}
	}

	function getAnimArray(anim:String) {
		for (i in animationsArray) {
			if (i.anim == anim)
				return i;
		}
		return null;
	}

	function addAnimation(anim:String, name:String, fps:Int, loop:Bool, ?indices:Array<Int>) {
		if (indices != null && indices.length > 0)
			animation.addByIndices(anim, name, indices, "", fps, loop);
		else
			animation.addByPrefix(anim, name, fps, loop);
	}

	override function update(elapsed:Float) {
		if (!debugMode && animation.curAnim != null) {
			if (heyTimer > 0) {
				heyTimer -= elapsed;
				if (heyTimer <= 0) {
					if (specialAnim && animation.curAnim.name == 'hey' || animation.curAnim.name == 'cheer') {
						specialAnim = false;
						dance();
					}
					heyTimer = 0;
				}
			} else if (specialAnim && animation.curAnim.finished) {
				specialAnim = false;
				dance();
			}

			switch(curCharacter) {
				case 'pico-speaker':
					if(animationNotes.length > 0 && Conductor.songPosition >= animationNotes[0][0]) {
						var noteData:Int = 1;
						if(animationNotes[0][1] > 2) noteData = 3;

						noteData += FlxG.random.int(0, 1);
						playAnim('shoot' + noteData, true);
						animationNotes.shift();
					}
					if (animation.curAnim.finished) playAnim(animation.curAnim.name, false, false, animation.curAnim.frames.length - 3);
			}

			if (isPlayer) {
				if (animation.curAnim.name.startsWith('sing'))
					holdTimer += elapsed;
				else
					holdTimer = 0;

				if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished) {
					dance();
					animation.finish();
				}
			} else {
				if (animation.curAnim.name.startsWith('sing'))
					holdTimer += elapsed;

				if (holdTimer >= Conductor.normalizedStepCrochet * 0.0011 * singDuration) {
					dance();
					holdTimer = 0;
				}
			}

			if (animation.curAnim.finished && animation.exists('${animation.curAnim.name}-loop'))
				playAnim('${animation.curAnim.name}-loop');
		}
		super.update(elapsed);
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance(force:Bool = false)
	{
		if (!skipDance && !specialAnim)
		{
			if (danceIdle)
			{
				danced = !danced;

				if (danced && animation.exists('danceRight$idleSuffix'))
					playAnim('danceRight$idleSuffix', force);
				else if (!danced && animation.exists('danceLeft$idleSuffix'))
					playAnim('danceLeft$idleSuffix', force);
			}
			else if (animation.exists('idle$idleSuffix')) {
					playAnim('idle$idleSuffix', (force && !animation.getByName('idle$idleSuffix').looped));
			}
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;
		animation.play(AnimName, Force, Reversed, Frame);

		setOffsets();

		if (curCharacter.startsWith('gf'))
		{
			if (AnimName == 'singLEFT')
			{
				danced = true;
			}
			else if (AnimName == 'singRIGHT')
			{
				danced = false;
			}

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
			{
				danced = !danced;
			}
		}
	}

	public function setOffsets(?name:String) {
		if (name == null)
			name = animation.name;
		
		offset.set(-0.5 * (width - (width / scale.x)), -0.5 * (height - (height / scale.y)));
		if (animOffsets.exists(name))
		{
			var daOffset = animOffsets.get(name);
			offset.x += daOffset[0];
			offset.y += daOffset[1];
		}
	}

	function loadMappedAnims():Void
	{
		if (CoolUtil.inPlayState() && PlayState.SONG != null) {
			var song = Song.loadFromJson('picospeaker', PlayState.SONG.song);
			if (song != null) {
				var noteData:Array<SwagSection> = song.notes;
				for (section in noteData) {
					for (songNotes in section.sectionNotes) {
						animationNotes.push(songNotes);
					}
				}
				animationNotes.sort(sortAnims);
			}
		}
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	private var settingCharacterUp:Bool = true;
	public function recalculateDanceIdle() {
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animation.exists('danceLeft$idleSuffix') && animation.exists('danceRight$idleSuffix'));
		if(settingCharacterUp)
		{
			danceEveryNumBeats = (danceIdle ? 1 : 2);
			settingCharacterUp = false;
		}
		else if(lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if(danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		animation.addByPrefix(name, anim, 24, false);
	}

	public static function getFile(name:String):Dynamic {
		var characterPath:String = 'characters/$name.json';
		var path:String = Paths.getPath(characterPath);
		if (!Paths.exists(path, TEXT))
		{
			path = Paths.getPreloadPath('characters/$DEFAULT_CHARACTER.json'); //If a character couldn't be found, change them to BF just to prevent a crash
		}

		var rawJson = Paths.getContent(path);
		if (rawJson == null) {
			return null;
		}

		var json = cast Json.parse(rawJson);
		return json;
	}

	public static function getCharacterGroupLength(name:String):Int {
		var characterFile = getFile(name);
		if (characterFile.characters != null) {
			return characterFile.characters.length;
		}
		return 1;
	}

	override public function destroy() {
		animOffsets = null;
		curCharacter = null;
		if (colorTween != null) {
			colorTween.cancel();
			colorTween.destroy();
		}
		colorTween = null;
		animationNotes = null;
		idleSuffix = null;
		keysPressed = null;
		healthIcon = null;
		animationsArray = null;
		playerPosition = null;
		enemyPosition = null;
		playerCameraPosition = null;
		enemyCameraPosition = null;
		imageFile = null;
		healthColorArray = null;
		associatedSprites = null;
		super.destroy();
	}
}
