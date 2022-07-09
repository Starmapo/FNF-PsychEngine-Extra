package;

import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxSort;
import flixel.FlxBasic;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxG;
import flixel.FlxSprite;

using StringTools;

class StrumNote extends FlxSprite
{
	private var colorSwap:ColorSwap;
	public var resetAnim:Float = 0;
	public var noteData:Int = 0;
	public var direction:Float = 90;
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;

	public var postAdded:Bool = false;

	public var keyAmount:Int = 4;
	public var directions:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
	public var colors:Array<String> = ['left', 'down', 'up', 'right'];
	public var spacing:Float = 0;
	public var xOffset:Float = 0;
	public var noteSize:Float = 0.7;
	public var skinModifier:String = '';
	
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		texture = value;
		reloadNote();
		return value;
	}

	public function new(x:Float, y:Float, leData:Int, ?keyAmount:Int = 4) {
		colorSwap = new ColorSwap();
		shader = colorSwap.shader;
		noteData = leData;
		this.noteData = leData % keyAmount;
		this.keyAmount = keyAmount;
		super(x, y);

		spacing = Std.parseFloat(CoolUtil.coolTextFile(Paths.txt('note_spacings'))[keyAmount-1]);
		directions = CoolUtil.coolArrayTextFile(Paths.txt('note_directions'))[keyAmount-1];
		colors = CoolUtil.coolArrayTextFile(Paths.txt('note_colors'))[keyAmount-1];
		xOffset = Std.parseFloat(CoolUtil.coolTextFile(Paths.txt('note_offsets'))[keyAmount-1]);
		noteSize = Std.parseFloat(CoolUtil.coolTextFile(Paths.txt('note_sizes'))[keyAmount-1]);

		var skin:String = 'NOTE_assets';
		if(PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 0) skin = PlayState.SONG.arrowSkin;
		texture = skin; //Load texture and anims

		scrollFactor.set();
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if (animation.curAnim != null) lastAnim = animation.curAnim.name;

		if (skinModifier.length < 1) {
			skinModifier = 'base';
			if (PlayState.SONG != null && PlayState.instance != null)
				skinModifier = PlayState.SONG.skinModifier;
		}
		var image = SkinData.getNoteFile(texture, skinModifier);
		if (!Paths.exists('images/$image.xml', TEXT)) { //assume it is pixel notes
			loadGraphic(Paths.image(image));
			width = width / 4;
			height = height / 5;
			loadGraphic(Paths.image(image), true, Math.floor(width), Math.floor(height));

			setGraphicSize(Std.int((width * (noteSize / Note.DEFAULT_NOTE_SIZE)) * PlayState.daPixelZoom));
			
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
		} else {
			frames = Paths.getSparrowAtlas(image);
			animation.addByPrefix('static', 'arrow${directions[noteData].toUpperCase()}0');
			animation.addByPrefix('pressed', '${colors[noteData]} press', 24, false);
			animation.addByPrefix('confirm', '${colors[noteData]} confirm', 24, false);
			if (skinModifier.endsWith('pixel')) {
				setGraphicSize(Std.int((width * (noteSize / Note.DEFAULT_NOTE_SIZE)) * PlayState.daPixelZoom));
			} else {
				setGraphicSize(Std.int(width * noteSize));
			}
		}
		updateHitbox();
		antialiasing = ClientPrefs.globalAntialiasing && !skinModifier.endsWith('pixel');

		if (lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	public function postAddedToGroup() {
		playAnim('static');
		x += (((160 * noteSize) + spacing) * noteData) + xOffset;
		ID = noteData;
		postAdded = true;
	}

	override function update(elapsed:Float) {
		if (resetAnim > 0) {
			resetAnim -= elapsed;
			if (resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		if (animation.curAnim != null && animation.curAnim.name == 'confirm' && !skinModifier.endsWith('pixel')) {
			centerOrigin();
		}

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();
		if (animation.curAnim == null || animation.curAnim.name == 'static') {
			colorSwap.hue = 0;
			colorSwap.saturation = 0;
			colorSwap.brightness = 0;
		} else {
			if (noteData > -1 && noteData < ClientPrefs.arrowHSV[keyAmount - 1].length)
			{
				colorSwap.hue = ClientPrefs.arrowHSV[keyAmount - 1][noteData][0] / 360;
				colorSwap.saturation = ClientPrefs.arrowHSV[keyAmount - 1][noteData][1] / 100;
				colorSwap.brightness = ClientPrefs.arrowHSV[keyAmount - 1][noteData][2] / 100;
			}

			if(animation.curAnim.name == 'confirm' && !skinModifier.endsWith('pixel')) {
				centerOrigin();
			}
		}
	}
}

typedef KeyChangeEvent =
{
	var section:Int;
	var keys:Int;
}

class StrumLine extends FlxTypedGroup<FlxBasic> {
	public var receptors:FlxTypedSpriteGroup<StrumNote>;
	public var notesGroup:FlxTypedGroup<Note>;
	public var holdsGroup:FlxTypedGroup<Note>;
	public var allNotes:FlxTypedGroup<Note>;

	public var keys:Int = 4;
	public var colors:Array<String> = [];
	public var animations:Array<String> = [];
	public var botPlay:Bool = true;
	public var isBoyfriend:Bool = false;

	public var keyChangeMap:Array<KeyChangeEvent> = [];

	public function new(x:Float = 0, y:Float = 0, keyAmount:Int = 4, isPlayer:Bool = false, tweenAlpha:Bool = false, inPlayState:Bool = false) {
		super();

		receptors = new FlxTypedSpriteGroup<StrumNote>();
		notesGroup = new FlxTypedGroup<Note>();
		holdsGroup = new FlxTypedGroup<Note>();
		allNotes = new FlxTypedGroup<Note>();

		createStrumLine(x, y, keyAmount, isPlayer, tweenAlpha, inPlayState);

		add(receptors);
		add(holdsGroup);
		add(notesGroup);
	}

	public function createStrumLine(x:Float = 0, y:Float = 0, keyAmount:Int = 4, isPlayer:Bool = false, tweenAlpha:Bool = false, inPlayState:Bool = false) {
		for (spr in members) {
			spr.kill();
			remove(spr);
			spr.destroy();
		}

		colors = CoolUtil.coolArrayTextFile(Paths.txt('note_colors'))[keyAmount-1];
		animations = CoolUtil.coolArrayTextFile(Paths.txt('note_animations'))[keyAmount-1];

		for (i in 0...keyAmount) {
			var targetAlpha:Float = 1;
			if (inPlayState && !isPlayer) {
				if(!ClientPrefs.opponentStrums) targetAlpha = 0;
				else if(ClientPrefs.middleScroll) targetAlpha = 0.35;
			}

			var babyArrow:StrumNote = new StrumNote(x, y, i, keyAmount);
			babyArrow.downScroll = ClientPrefs.downScroll;
			if (inPlayState && tweenAlpha)
			{
				var delay = Conductor.normalizedCrochet / (250 * keyAmount);
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {alpha: targetAlpha}, delay, {ease: FlxEase.circOut, startDelay: delay * (i + 1)});
			}
			else
			{
				babyArrow.alpha = targetAlpha;
			}

			if (inPlayState && !isPlayer && ClientPrefs.middleScroll)
			{
				babyArrow.x = -18;
				if (i >= Math.floor(keyAmount / 2)) {
					babyArrow.x += FlxG.width / 2 + 25;
				}
			}

			receptors.add(babyArrow);
			babyArrow.postAddedToGroup();

			//centering it where 4k note size would be
			babyArrow.x += (80 - (babyArrow.frameWidth / 2)) * babyArrow.noteSize;
			babyArrow.y += (80 - (babyArrow.frameHeight / 2)) * babyArrow.noteSize;
		}

		keys = keyAmount;
	}

	public function push(newNote:Note)
	{
		var chosenGroup = (newNote.isSustainNote ? holdsGroup : notesGroup);
		chosenGroup.add(newNote);
		allNotes.add(newNote);
		chosenGroup.sort(FlxSort.byY, (!ClientPrefs.downScroll ? FlxSort.DESCENDING : FlxSort.ASCENDING));
	}

	public function takeNotesFrom(strum:StrumLine) {
		for (newNote in strum.allNotes) {
			push(newNote);
			var chosenGroup = (newNote.isSustainNote ? strum.holdsGroup : strum.notesGroup);
			chosenGroup.remove(newNote, true);
			strum.allNotes.remove(newNote, true);
		}
	}

	public function pushEvent(event:KeyChangeEvent)
	{
		keyChangeMap.push(event);
		keyChangeMap.sort(sortByShit);
	}

	function sortByShit(Obj1:KeyChangeEvent, Obj2:KeyChangeEvent):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.section, Obj2.section);
	}
}