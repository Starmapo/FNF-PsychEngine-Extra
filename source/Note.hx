package;

import flixel.FlxSprite;
import editors.ChartingState;
import UIData;
#if MODS_ALLOWED
import sys.FileSystem;
#end
import openfl.utils.Assets;

using StringTools;

class Note extends FlxSprite
{
	public var strumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var colorSwap:ColorSwap;
	public var inEditor:Bool = false;
	public var gfNote:Bool = false;
	private var hitMult:Float = 1;
	private var earlyHitMult:Float = 0.5;

	public var swagWidth:Float = 160 * 0.7;
	public static var PURP_NOTE:Int = 0;
	public static var GREEN_NOTE:Int = 2;
	public static var BLUE_NOTE:Int = 1;
	public static var RED_NOTE:Int = 3;

	// Lua shit
	public var noteSplashDisabled:Bool = false;
	public var noteSplashTexture:String = null;
	public var noteSplashHue:Float = 0;
	public var noteSplashSat:Float = 0;
	public var noteSplashBrt:Float = 0;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;

	public var texture(default, set):String = null;

	public var noAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000;//plan on doing scroll directions soon -bb

	var keyAmount:Int = 4;
	var colors:Array<String> = ['left', 'down', 'up', 'right'];
	var xOff:Float = 54;
	public var noteSize:Float = 0.7;
	public var uiSkin:SkinFile;

	private function set_texture(value:String):String {
		if(texture != value) {
			reloadNote('', value);
		}
		texture = value;
		return value;
	}

	private function set_noteType(value:String):String {
		if(noteData > -1) {
			noteSplashTexture = 'noteSplashes';
			colorSwap.hue = ClientPrefs.arrowHSV[noteData % 4][0] / 360;
			colorSwap.saturation = ClientPrefs.arrowHSV[noteData % 4][1] / 100;
			colorSwap.brightness = ClientPrefs.arrowHSV[noteData % 4][2] / 100;
			if(noteType != value) {
				switch(value) {
					case 'Hurt Note':
						ignoreNote = mustPress;
						reloadNote('HURT');
						noteSplashTexture = 'HURTnoteSplashes';
						colorSwap.hue = 0;
						colorSwap.saturation = 0;
						colorSwap.brightness = 0;
						if(isSustainNote) {
							missHealth = 0.1;
						} else {
							missHealth = 0.3;
						}
						hitCausesMiss = true;
						hitMult = 0.5;
						if(isSustainNote) {
							earlyHitMult = 0.3;
						} else {
							earlyHitMult = 0.5;
						}
					case 'No Animation':
						noAnimation = true;
					case 'GF Sing':
						gfNote = true;
				}
				noteType = value;
			}
			noteSplashHue = colorSwap.hue;
			noteSplashSat = colorSwap.saturation;
			noteSplashBrt = colorSwap.brightness;
		}
		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?keyAmount:Int = 4, ?uiSkin:SkinFile = null)
	{
		super();

		if (prevNote == null)
			prevNote = this;

		if (uiSkin == null) {
			uiSkin = UIData.getUIFile('');
		}

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;
		this.keyAmount = keyAmount;
		this.uiSkin = uiSkin;

		var maniaData:ManiaArray = null;
		for (i in uiSkin.mania) {
			if (i.keys == keyAmount) {
				maniaData = i;
				break;
			}
		}
		if (maniaData == null) {
			var bad:SkinFile = UIData.getUIFile('default');
			for (i in bad.mania) {
				if (i.keys == keyAmount) {
					maniaData = i;
					break;
				}
			}
		}

		colors = maniaData.colors;
		swagWidth = maniaData.noteSpacing;
		xOff = maniaData.xOffset;
		noteSize = maniaData.noteSize;

		x += (ClientPrefs.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + xOff;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if(!inEditor) this.strumTime += ClientPrefs.noteOffset;

		this.noteData = noteData;
		var data = noteData % keyAmount;

		if(noteData > -1) {
			texture = '';
			colorSwap = new ColorSwap();
			shader = colorSwap.shader;

			x += swagWidth * data;
			if (!isSustainNote) { //Doing this 'if' check to fix the warnings on Senpai songs
				animation.play(colors[data]);
			}
		}

		// trace(prevNote);

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			multAlpha = 0.6;
			if(ClientPrefs.downScroll) flipY = true;

			offsetX += width / 2;
			copyAngle = false;

			animation.play(colors[data] + 'holdend');

			updateHitbox();

			offsetX -= width / 2;

			offsetX += uiSkin.sustainXOffset;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(colors[prevNote.noteData % keyAmount] + 'hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				if(PlayState.instance != null)
				{
					prevNote.scale.y *= PlayState.instance.songSpeed;
				}

				prevNote.scale.y *= uiSkin.sustainYScale;
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}

			scale.y *= uiSkin.scale;
			updateHitbox();
		} else if(!isSustainNote) {
			earlyHitMult = 1;
		}
		x += offsetX;
	}

	function reloadNote(?prefix:String = '', ?texture:String = '', ?suffix:String = '') {
		if(prefix == null) prefix = '';
		if(texture == null) texture = '';
		if(suffix == null) suffix = '';
		
		var skin:String = texture;
		if(skin == null || skin.length < 1) {
			skin = 'NOTE_assets';
		}

		var animName:String = null;
		if(animation.curAnim != null) {
			animName = animation.curAnim.name;
		}

		var arraySkin:Array<String> = skin.split('/');
		arraySkin[arraySkin.length-1] = prefix + arraySkin[arraySkin.length-1] + suffix;

		var lastScaleY:Float = scale.y;
		var uiFile:String = uiSkin.name;
		if (uiFile == null || uiFile.length < 1) {
			uiFile = 'default';
		}
		var path:String = 'uiskins/$uiFile/notes/' + arraySkin.join('/');
		#if MODS_ALLOWED
		if (!FileSystem.exists(Paths.getPath('images/$path.png', IMAGE)) && !FileSystem.exists(Paths.modFolders('images/$path.png'))) {
		#else
		if (!Assets.exists(Paths.getPath('images/$path.png', IMAGE))) {
		#end
			path = 'uiskins/default/notes/' + arraySkin.join('/');
		}
		frames = Paths.getSparrowAtlas(path);
		loadNoteAnims();
		antialiasing = ClientPrefs.globalAntialiasing;
		if (uiSkin.noAntialiasing) {
			antialiasing = false;
		}
		if(isSustainNote) {
			scale.y = lastScaleY;
			if(ClientPrefs.keSustains) {
				scale.y *= 0.75;
			}
		}
		updateHitbox();

		if(animName != null)
			animation.play(animName, true);

		if(inEditor) {
			setGraphicSize(ChartingState.GRID_SIZE, ChartingState.GRID_SIZE);
			updateHitbox();
		}
	}

	function loadNoteAnims() {
		for (i in colors) {
			animation.addByPrefix(i, i + '0');
			if (isSustainNote) {
				animation.addByPrefix(i + 'hold', i + ' hold0');
				animation.addByPrefix(i + 'holdend', i + ' tail0');
			}
		}

		setGraphicSize(Std.int((width * noteSize) * uiSkin.scale * uiSkin.noteScale));
		updateHitbox();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			// ok river
			if (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * hitMult)
				&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
				canBeHit = true;
			else
				canBeHit = false;

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (strumTime <= Conductor.songPosition)
				wasGoodHit = true;
		}

		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}
}
