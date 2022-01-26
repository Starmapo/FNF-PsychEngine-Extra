package;

import flixel.FlxG;
import flixel.FlxSprite;
#if MODS_ALLOWED
import sys.FileSystem;
#end
import openfl.utils.Assets;

class NoteSplash extends FlxSprite
{
	public var colorSwap:ColorSwap = null;
	private var idleAnim:String;
	private var textureLoaded:String = null;

	var daNote:Note = null;
	var colors:Array<String>;

	public function new(x:Float = 0, y:Float = 0, ?note:Note = null) {
		super(x, y);

		var skin:String = 'noteSplashes';

		loadAnims(skin);
		
		colorSwap = new ColorSwap();
		shader = colorSwap.shader;

		//setupNoteSplash(x, y, note);
		antialiasing = ClientPrefs.globalAntialiasing;
	}

	public function setupNoteSplash(x:Float, y:Float, note:Note = null, texture:String = null, hueColor:Float = 0, satColor:Float = 0, brtColor:Float = 0, keyAmount:Int = 4, ?colors:Array<String>) {
		if (note != null) {
			daNote = note;
			setGraphicSize(Std.int(note.width * 2.68), Std.int(note.height * 2.77));
		}
		if (colors != null) {
			this.colors = colors;
		}
		updateHitbox();
		alpha = 0.6;

		if(texture == null || texture.length < 1) {
			texture = 'noteSplashes';
		}

		loadAnims(texture);
		colorSwap.hue = hueColor;
		colorSwap.saturation = satColor;
		colorSwap.brightness = brtColor;

		var animNum:Int = FlxG.random.int(1, 2);
		if (note != null) {
			animation.play('note' + note.noteData + '-' + animNum, true);
		} else {
			animation.play('note1' + '-' + animNum, true);
		}
		if (animation.curAnim != null) animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
		updateHitbox();
        centerOrigin();
		if (note != null) {
			setPosition(note.x - (note.width), note.y - (note.height));
			alpha = note.alpha;
			angle = note.angle;
		}
	}

	function loadAnims(skin:String) {
		if (daNote == null) {
			frames = Paths.getSparrowAtlas('uiskins/default/splashes/noteSplashes');
			animation.addByPrefix("note0-1", "note splash left 1", 24, false);
		} else {
			antialiasing = ClientPrefs.globalAntialiasing;
			if (daNote.uiSkin.noAntialiasing) {
				antialiasing = false;
			}
			frames = Paths.getSparrowAtlas(UIData.checkImageFile('splashes/$skin', daNote.uiSkin));
			for (i in 1...3) {
				animation.addByPrefix("note" + daNote.noteData + '-$i', "note splash " + colors[daNote.noteData] + ' $i', 24, false);
			}
		}
	}

	override function update(elapsed:Float) {
		if(animation.curAnim != null)if(animation.curAnim.finished) kill();

		if (daNote != null) {
			setPosition(daNote.x - (daNote.width), daNote.y - (daNote.height));
			alpha = daNote.alpha;
			angle = daNote.angle;
		}

		super.update(elapsed);
	}
}