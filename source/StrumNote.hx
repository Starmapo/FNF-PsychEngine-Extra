package;

import flixel.FlxG;
import flixel.FlxSprite;

using StringTools;

class StrumNote extends FlxSprite
{
	private var colorSwap:ColorSwap;
	public var resetAnim:Float = 0;
	private var noteData:Int = 0;
	public var direction:Float = 90;//plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;//plan on doing scroll directions soon -bb

	private var player:Int;

	var keyAmount:Int = 4;
	var directions:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
	var colors:Array<String> = ['left', 'down', 'up', 'right'];
	public var swagWidth:Float = 160 * 0.7;
	var xOff:Float = 50;
	public var noteSize:Float = 0.7;
	
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}

	public function new(x:Float, y:Float, leData:Int, player:Int, ?keyAmount:Int = 4) {
		colorSwap = new ColorSwap();
		shader = colorSwap.shader;
		noteData = leData;
		this.player = player;
		this.noteData = leData;
		this.keyAmount = keyAmount;
		super(x, y);

		switch (keyAmount) {
			case 5:
				directions = ['LEFT', 'DOWN', 'CENTER', 'UP', 'RIGHT'];
				colors = ['left', 'down', 'center', 'up', 'right'];
				xOff = 1;
			case 6:
				directions = ['LEFT', 'UP', 'RIGHT', 'LEFT', 'DOWN', 'RIGHT'];
				colors = ['left', 'up', 'right', 'left2', 'down', 'right2'];
				swagWidth = 160 * 0.6;
				xOff = -8;
				noteSize = 0.6;
			case 7:
				directions = ['LEFT', 'UP', 'RIGHT', 'CENTER', 'LEFT', 'DOWN', 'RIGHT'];
				colors = ['left', 'up', 'right', 'center', 'left2', 'down', 'right2'];
				swagWidth = 160 * 0.55;
				xOff = -28;
				noteSize = 0.55;
			case 8:
				directions = ['LEFT', 'DOWN', 'UP', 'RIGHT', 'LEFT', 'DOWN', 'UP', 'RIGHT'];
				colors = ['left', 'down', 'up', 'right', 'left2', 'down2', 'up2', 'right2'];
				swagWidth = 160 * 0.5;
				xOff = -9;
				noteSize = 0.5;
			case 9:
				directions = ['LEFT', 'DOWN', 'UP', 'RIGHT', 'CENTER', 'LEFT', 'DOWN', 'UP', 'RIGHT'];
				colors = ['left', 'down', 'up', 'right', 'center', 'left2', 'down2', 'up2', 'right2'];
				swagWidth = 160 * 0.4;
				xOff = -9;
				noteSize = 0.4;
		}

		var skin:String = 'NOTE_assets';
		if(PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
		texture = skin; //Load texture and anims

		scrollFactor.set();
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		if(PlayState.isPixelStage)
		{
			loadGraphic(Paths.image('pixelUI/' + texture));
			width = width / 4;
			height = height / 5;
			loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));

			antialiasing = false;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));

			switch (noteData)
			{
				case 0:
					animation.add('static', [0]);
					animation.add('pressed', [4, 8], 12, false);
					animation.add('confirm', [12, 16], 24, false);
				case 1:
					animation.add('static', [1]);
					animation.add('pressed', [5, 9], 12, false);
					animation.add('confirm', [13, 17], 24, false);
				case 2:
					animation.add('static', [2]);
					animation.add('pressed', [6, 10], 12, false);
					animation.add('confirm', [14, 18], 12, false);
				case 3:
					animation.add('static', [3]);
					animation.add('pressed', [7, 11], 12, false);
					animation.add('confirm', [15, 19], 24, false);
			}
		}
		else
		{
			frames = Paths.getSparrowAtlas(texture);

			animation.addByPrefix('static', 'arrow' + directions[noteData]);
			animation.addByPrefix('pressed', colors[noteData] + ' press', 24, false);
			animation.addByPrefix('confirm', colors[noteData] + ' confirm', 24, false);

			antialiasing = ClientPrefs.globalAntialiasing;
			setGraphicSize(Std.int(width * noteSize));
		}
		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	public function postAddedToGroup() {
		playAnim('static');
		x += swagWidth * noteData;
		x += xOff;
		x += ((FlxG.width / 2) * player);
		ID = noteData;
	}

	override function update(elapsed:Float) {
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		if(animation.curAnim != null){ //my bad i was upset
			if(animation.curAnim.name == 'confirm' && !PlayState.isPixelStage) {
				centerOrigin();
			}
		}

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();
		if(animation.curAnim == null || animation.curAnim.name == 'static') {
			colorSwap.hue = 0;
			colorSwap.saturation = 0;
			colorSwap.brightness = 0;
		} else {
			colorSwap.hue = ClientPrefs.arrowHSV[noteData % 4][0] / 360;
			colorSwap.saturation = ClientPrefs.arrowHSV[noteData % 4][1] / 100;
			colorSwap.brightness = ClientPrefs.arrowHSV[noteData % 4][2] / 100;

			if(animation.curAnim.name == 'confirm' && !PlayState.isPixelStage) {
				centerOrigin();
			}
		}
	}
}
