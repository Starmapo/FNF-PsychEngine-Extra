package pvp;

import flixel.util.FlxDestroyUtil;
import flixel.tweens.FlxTween;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.system.FlxSound;
import flixel.group.FlxGroup.FlxTypedGroup;

class PvPPauseSubState extends MusicBeatSubState {
    public static var songName:String = '';

    var grpMenuShit:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = [];
	var menuItemsOG:Array<String> = ['Resume', 'Restart Song', 'Reload Song', 'Change Difficulty', 'Options', 'Exit to menu'];
	var difficultyChoices = [];
	var curSelected:Int = 0;

	var pauseMusic:FlxSound;

	public function new()
	{
		super();
		if (CoolUtil.difficulties.length < 2) menuItemsOG.remove('Change Difficulty'); //No need to change difficulty if there is only one!

		menuItems = menuItemsOG;

		for (i in 0...CoolUtil.difficulties.length) {
			if (i != PlayState.storyDifficulty) {
				var diff:String = CoolUtil.difficulties[i];
				difficultyChoices.push(diff);
			}
		}
		difficultyChoices.push('BACK');

		pauseMusic = new FlxSound();
		if(songName != null) {
			pauseMusic.loadEmbedded(Paths.music(songName), true, true);
		} else if (ClientPrefs.pauseMusic != 'None') {
			pauseMusic.loadEmbedded(Paths.music(Paths.formatToSongPath(ClientPrefs.pauseMusic)), true, true);
		}
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		regenMenu();

		var levelInfo:FlxText = new FlxText(20, 15, 0, "", 32);
		levelInfo.text += PvPPlayState.instance.curSongDisplayName;
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("vcr.ttf"), 32);
		levelInfo.updateHitbox();
		add(levelInfo);

		var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, "", 32);
		levelDifficulty.text += CoolUtil.difficultyString();
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		add(levelDifficulty);

		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	var holdTime:Float = 0;
	var cantUnpause:Float = 0.1;
	override function update(elapsed:Float)
	{
		cantUnpause -= elapsed;
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);

		var upP = controls.UI_UP_P || FlxG.mouse.wheel > 0;
		var downP = controls.UI_DOWN_P || FlxG.mouse.wheel < 0;
		var up = controls.UI_UP;
		var down = controls.UI_DOWN;
		var accepted = controls.ACCEPT || FlxG.mouse.justPressed;

		var gamepad = FlxG.gamepads.lastActive;
		if (gamepad != null) {
			if (gamepad.justPressed.LEFT_STICK_DIGITAL_UP || gamepad.justPressed.DPAD_UP) upP = true;
            if (gamepad.justPressed.LEFT_STICK_DIGITAL_DOWN || gamepad.justPressed.DPAD_DOWN) downP = true;
            if (gamepad.pressed.LEFT_STICK_DIGITAL_UP || gamepad.pressed.DPAD_UP) up = true;
            if (gamepad.pressed.LEFT_STICK_DIGITAL_DOWN || gamepad.pressed.DPAD_DOWN) down = true;
            if (gamepad.justPressed.A) accepted = true;
		}

		if (upP)
		{
			changeSelection(-1);
			holdTime = 0;
		}
		if (downP)
		{
			changeSelection(1);
			holdTime = 0;
		}
		
		if (down || up)
		{
			var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
			holdTime += elapsed;
			var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

			if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
			{
				changeSelection((checkNewHold - checkLastHold) * (up ? -1 : 1));
			}
		}

		var daSelected:String = menuItems[curSelected];

		if (accepted && cantUnpause <= 0)
		{
			if (menuItems == difficultyChoices)
			{
				if(menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected)) {
					var player1 = PlayState.SONG.player1;
					var player2 = PlayState.SONG.player2;
					var actualDiff = CoolUtil.difficulties.indexOf(daSelected);
					var name:String = PlayState.SONG.song;
					var poop = Highscore.formatSong(name, actualDiff);
					PlayState.SONG = Song.loadFromJson(poop, name);
					PlayState.SONG.player1 = player1;
					PlayState.SONG.player2 = player2;
					PlayState.storyDifficulty = actualDiff;
					LoadingState.loadAndResetState();
					pauseMusic.volume = 0;
					return;
				}

				menuItems = menuItemsOG;
				regenMenu();
			}

			switch (daSelected)
			{
				case "Resume":
					close();
				case 'Change Difficulty':
					menuItems = difficultyChoices;
					regenMenu();
				case "Restart Song":
					restartSong();
					pauseMusic.volume = 0;
				case "Restart Cutscene":
					restartSong();
					pauseMusic.volume = 0;
				case 'Reload Song':
					var oldP1 = PlayState.SONG.player1;
					var oldP2 = PlayState.SONG.player2;
					var name:String = PlayState.SONG.song;
					var poop = Highscore.formatSong(name, PlayState.storyDifficulty);
					PlayState.SONG = Song.loadFromJson(poop, name);
					PlayState.SONG.player1 = oldP1;
					PlayState.SONG.player2 = oldP2;
					restartSong();
					pauseMusic.volume = 0;
				case "Options":
					MusicBeatState.switchState(new options.OptionsState(true));
					CoolUtil.playMenuMusic();
				case "Exit to menu":
					MusicBeatState.switchState(new PvPCharacterState());
					PvPPlayState.cancelMusicFadeTween();
					CoolUtil.playMenuMusic();
			}
		}
	}

	public static function restartSong(noTrans:Bool = false)
	{
		FlxG.timeScale = 1;
		PvPPlayState.instance.paused = true; // For lua
		PvPPlayState.instance.vocals.volume = 0;
		PvPPlayState.instance.vocalsDad.volume = 0;

		if (noTrans)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
		}
		MusicBeatState.resetState();
	}

	override function destroy()
	{
		pauseMusic = FlxDestroyUtil.destroy(pauseMusic);
		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		CoolUtil.playScrollSound();

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpMenuShit.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}
	}

	function regenMenu():Void {
		for (i in 0...grpMenuShit.members.length) {
			var obj = grpMenuShit.members[0];
			obj.kill();
			grpMenuShit.remove(obj, true);
			obj.destroy();
		}

		for (i in 0...menuItems.length) {
			var item = new Alphabet(0, 70 * i + 30, menuItems[i], true, false);
			item.isMenuItem = true;
			item.targetY = i;
			grpMenuShit.add(item);
		}
		curSelected = 0;
		changeSelection(0);
	}
}