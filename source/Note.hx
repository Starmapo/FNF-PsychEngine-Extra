package;

import flixel.FlxSprite;
import editors.ChartingState;

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
	var xOff:Float = 50;
	public var noteSize:Float = 0.7;

	private function set_texture(value:String):String {
		if(texture != value) {
			reloadNote('', value);
		}
		texture = value;
		return value;
	}

	private function set_noteType(value:String):String {
		if(noteData > -1) {
			noteSplashTexture = PlayState.SONG.splashSkin;
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

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?keyAmount:Int = 4)
	{
		super();

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;
		this.keyAmount = keyAmount;

		switch (keyAmount) {
			case 5:
				colors = ['left', 'down', 'center', 'up', 'right'];
				xOff = 1;
			case 6:
				colors = ['left', 'up', 'right', 'left2', 'down', 'right2'];
				swagWidth = 160 * 0.6;
				xOff = -8;
				noteSize = 0.6;
			case 7:
				colors = ['left', 'up', 'right', 'center', 'left2', 'down', 'right2'];
				swagWidth = 160 * 0.55;
				xOff = -28;
				noteSize = 0.55;
			case 8:
				colors = ['left', 'down', 'up', 'right', 'left2', 'down2', 'up2', 'right2'];
				swagWidth = 160 * 0.5;
				xOff = -9;
				noteSize = 0.5;
			case 9:
				colors = ['left', 'down', 'up', 'right', 'center', 'left2', 'down2', 'up2', 'right2'];
				swagWidth = 160 * 0.4;
				xOff = -9;
				noteSize = 0.4;
		}

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

			if (PlayState.isPixelStage)
				offsetX += 30;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(colors[prevNote.noteData % keyAmount] + 'hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				if(PlayState.instance != null)
				{
					prevNote.scale.y *= PlayState.instance.songSpeed;
				}

				if(PlayState.isPixelStage) {
					prevNote.scale.y *= 1.19;
				}
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}

			if(PlayState.isPixelStage) {
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
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
		if(texture.length < 1) {
			skin = PlayState.SONG.arrowSkin;
			if(skin == null || skin.length < 1) {
				skin = 'NOTE_assets';
			}
		}

		var animName:String = null;
		if(animation.curAnim != null) {
			animName = animation.curAnim.name;
		}

		var arraySkin:Array<String> = skin.split('/');
		arraySkin[arraySkin.length-1] = prefix + arraySkin[arraySkin.length-1] + suffix;

		var lastScaleY:Float = scale.y;
		var blahblah:String = arraySkin.join('/');
		if(PlayState.isPixelStage) {
			if(isSustainNote) {
				loadGraphic(Paths.image('pixelUI/' + blahblah + 'ENDS'));
				width = width / 4;
				height = height / 2;
				loadGraphic(Paths.image('pixelUI/' + blahblah + 'ENDS'), true, Math.floor(width), Math.floor(height));
			} else {
				loadGraphic(Paths.image('pixelUI/' + blahblah));
				width = width / 4;
				height = height / 5;
				loadGraphic(Paths.image('pixelUI/' + blahblah), true, Math.floor(width), Math.floor(height));
			}
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			loadPixelNoteAnims();
			antialiasing = false;
		} else {
			frames = Paths.getSparrowAtlas(blahblah);
			loadNoteAnims();
			antialiasing = ClientPrefs.globalAntialiasing;
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
		var anims = ['left', 'down', 'up', 'right', 'center', 'left2', 'down2', 'up2', 'right2'];
		for (i in anims) {
			animation.addByPrefix(i, i + '0');
			if (isSustainNote) {
				animation.addByPrefix(i + 'hold', i + ' hold0');
				animation.addByPrefix(i + 'holdend', i + ' tail0');
			}
		}

		setGraphicSize(Std.int(width * noteSize));
		updateHitbox();
	}

	function loadPixelNoteAnims() {
		if(isSustainNote) {
			animation.add('leftholdend', [PURP_NOTE + 4]);
			animation.add('upholdend', [GREEN_NOTE + 4]);
			animation.add('rightholdend', [RED_NOTE + 4]);
			animation.add('downholdend', [BLUE_NOTE + 4]);

			animation.add('lefthold', [PURP_NOTE]);
			animation.add('uphold', [GREEN_NOTE]);
			animation.add('righthold', [RED_NOTE]);
			animation.add('downhold', [BLUE_NOTE]);
		} else {
			animation.add('up', [GREEN_NOTE + 4]);
			animation.add('right', [RED_NOTE + 4]);
			animation.add('down', [BLUE_NOTE + 4]);
			animation.add('left', [PURP_NOTE + 4]);
		}
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
