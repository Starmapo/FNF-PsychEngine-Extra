package;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end
import editors.ChartingState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.system.FlxSound;
import WeekData;
#if cpp
import lime.media.openal.AL;
#end

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];
	var songsOG:Array<SongMetadata> = [];

	private static var curSelected:Int = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = '';

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		AtlasFrameMaker.clearCache();
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);
		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		for (i in 0...WeekData.weeksList.length) {
			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			WeekData.setDirectoryFromWeek(leWeek);
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if (colors == null || colors.length < 3)
				{
					FlxG.log.warn('Failed to load ${song[0]}\'s colors!');
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		songs = songsOG.copy();
		WeekData.loadTheFirstEnabledMod();

		if (ClientPrefs.freeplayAlphabetic) {
			songs.sort(sortAlphabetically);
		}

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);
		bg.screenCenter();

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			if (songText.width > 980)
			{
				var textScale:Float = 980 / songText.width;
				songText.scale.x = textScale;
				for (letter in songText.lettersArray)
				{
					letter.x *= textScale;
					letter.offset.x *= textScale;
				}
			}

			Paths.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);
		}
		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

		if (curSelected >= songs.length) curSelected = 0;
		if (songs.length > 0) bg.color = songs[curSelected].color;
		intendedColor = bg.color;

		if (lastDifficultyName == '')
		{
			lastDifficultyName = CoolUtil.defaultDifficulty;
		}
		curDifficulty = FlxMath.maxInt(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName));
		
		changeSelection();

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		#if PRELOAD_ALL
		var leText:String = "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 16;
		#else
		var leText:String = "Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 18;
		#end
		if (songs.length < 1) {
			leText = "Press CTRL to open the Gameplay Changers Menu";
		}
		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, size);
		text.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);
		super.create();
	}

	override function closeSubState() {
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songsOG.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && !Highscore.completedWeek(leWeek.weekBefore));
	}

	public static var instPlaying:Int = -1;
	static var speedPlaying:Float = 1;
	private static var vocals:FlxSound = null;
	private static var vocalsDad:FlxSound = null;
	private static var foundDadVocals = false;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, CoolUtil.boundTo(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(Highscore.floorDecimal(lerpRating * 100, 2)).split('.');
		if (ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}
		
		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

		scoreText.text = 'PERSONAL BEST: $lerpScore (${ratingSplit.join('.')}%)';
		positionHighscore();

		FlxG.camera.zoom = FlxMath.lerp(1, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT || FlxG.mouse.justPressed;
		var space = FlxG.keys.justPressed.SPACE;
		var ctrl = FlxG.keys.justPressed.CONTROL;

		var shiftMult:Int = 1;
		if (FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if (songs.length > 1)
		{
			if (upP || (!FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel > 0))
			{
				changeSelection(-shiftMult);
				holdTime = 0;
			}
			if (downP || (!FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel < 0))
			{
				changeSelection(shiftMult);
				holdTime = 0;
			}

			if (controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
				{
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					changeDiff();
				}
			}
		}

		if (songs.length > 0 && CoolUtil.difficulties.length > 1) {
			if (controls.UI_LEFT_P || (FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel < 0))
				changeDiff(-1);
			else if (controls.UI_RIGHT_P || (FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel > 0))
				changeDiff(1);
		}

		if (controls.BACK)
		{
			persistentUpdate = false;
			if (colorTween != null) {
				colorTween.cancel();
			}
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
			MusicBeatState.switchState(new MainMenuState());
		}

		super.update(elapsed);

		if (ctrl)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if (songs.length > 0)
		{
			if (space)
			{
				if (instPlaying != curSelected || speedPlaying != ClientPrefs.getGameplaySetting('songspeed', 1))
				{
					#if PRELOAD_ALL
					destroyFreeplayVocals();
					FlxG.sound.music.volume = 0;
					Conductor.songPosition = 0;
					Paths.currentModDirectory = songs[curSelected].folder;
					var poop:String = Highscore.formatSong(songs[curSelected].songName, curDifficulty, false);
					PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName);
					if (PlayState.SONG.needsVoices) {
						vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
						vocalsDad = new FlxSound();
						foundDadVocals = false;
						if (Paths.fileExists('${Paths.formatToSongPath(PlayState.SONG.song)}/VoicesDad.${Paths.SOUND_EXT}', MUSIC, false, 'songs'))
						{
							var file = Paths.voices(Paths.formatToSongPath(PlayState.SONG.song), 'Dad');
							if (file != null) {
								foundDadVocals = true;
								vocalsDad.loadEmbedded(file);
							}
						}
					} else {
						vocals = new FlxSound();
						vocalsDad = new FlxSound();
					}

					FlxG.sound.list.add(vocals);
					FlxG.sound.list.add(vocalsDad);
					FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.7 * ClientPrefs.instVolume, false);
					vocals.play();
					vocals.persist = true;
					vocals.looped = false;
					vocals.volume = 0.7 * ClientPrefs.voicesVolume;
					vocalsDad.play();
					vocalsDad.persist = true;
					vocalsDad.looped = false;
					vocalsDad.volume = 0.7 * ClientPrefs.voicesVolume;
					Conductor.mapBPMChanges(PlayState.SONG, ClientPrefs.getGameplaySetting('songspeed', 1));
					Conductor.changeBPM(PlayState.SONG.bpm, ClientPrefs.getGameplaySetting('songspeed', 1));
					Conductor.changeSignature(PlayState.SONG.numerator, PlayState.SONG.denominator);
					instPlaying = curSelected;
					speedPlaying = ClientPrefs.getGameplaySetting('songspeed', 1);
					setSongStuff(false);
					#end
				}
			}
			else if (accepted)
			{
				persistentUpdate = false;
				var songLowercase:String = songs[curSelected].songName;
				var poop:String = Highscore.formatSong(songLowercase, curDifficulty, false);
				trace(poop);

				PlayState.SONG = Song.loadFromJson(poop, songLowercase);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;

				trace('CURRENT WEEK: ${WeekData.getWeekName()}');
				if (colorTween != null) {
					colorTween.cancel();
				}
				
				if (FlxG.keys.pressed.SHIFT) {
					PlayState.chartingMode = true;
					LoadingState.loadAndSwitchState(new ChartingState(false));
				} else {
					LoadingState.loadAndSwitchState(new PlayState());
				}

				FlxG.sound.music.volume = 0;
				
				#if PRELOAD_ALL
				destroyFreeplayVocals();
				#end
			}
			else if (controls.RESET)
			{
				persistentUpdate = false;
				openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			}
		}
	}

	public static function setSongStuff(changePosition:Bool = true) {
		if (FlxG.sound.music != null) {
			if (changePosition)
				Conductor.songPosition += FlxG.elapsed * 1000;
			if (Conductor.songPosition > FlxG.sound.music.length / speedPlaying) {
				Conductor.songPosition = 0;
				FlxG.sound.music.time = vocals.time = vocalsDad.time = 0;
			}
			if (Math.abs(FlxG.sound.music.time / speedPlaying - Conductor.songPosition) > 20
				|| (PlayState.SONG.needsVoices && ((Math.abs(vocals.time / speedPlaying - Conductor.songPosition) > 20) 
				|| (foundDadVocals && Math.abs(vocalsDad.time / speedPlaying - Conductor.songPosition) > 20)))) {
					resyncVocals();
			}
			#if (cpp && PRELOAD_ALL)
			@:privateAccess
			{
				if (instPlaying > -1 && speedPlaying != 1) {
					var songAudio = [FlxG.sound.music, vocals, vocalsDad];
					for (audio in songAudio) {
						if (audio != null && audio.playing && audio._channel != null && AL.getSourcef(audio._channel.__source.__backend.handle, AL.PITCH) != speedPlaying) {
							AL.sourcef(audio._channel.__source.__backend.handle, AL.PITCH, speedPlaying);
						}
					}
				}
			}
			#end
		}
	}

	static function resyncVocals() {
		vocals.pause();
		vocalsDad.pause();

		FlxG.sound.music.play();
		if (FlxG.sound.music.time > 200) {
			Conductor.songPosition = FlxG.sound.music.time / speedPlaying;
		} else {
			FlxG.sound.music.time = Conductor.songPosition * speedPlaying;
		}
		if (Conductor.songPosition * speedPlaying <= vocals.length) {
			vocals.time = Conductor.songPosition * speedPlaying;
			vocals.play();
		}
		if (Conductor.songPosition * speedPlaying <= vocalsDad.length) {
			vocalsDad.time = Conductor.songPosition * speedPlaying;
			vocalsDad.play();
		}
	}

	override function beatHit() {
		super.beatHit();

		if (instPlaying > -1) {
			Conductor.getLastBPM(PlayState.SONG, curStep, speedPlaying);

			if (Conductor.getCurNumeratorBeat(PlayState.SONG, curBeat) % 2 == 0 && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms) {
				FlxG.camera.zoom += 0.005;
			}
		}
	}

	public static function destroyFreeplayVocals() {
		if (vocals != null) {
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
		if (vocalsDad != null) {
			vocalsDad.stop();
			vocalsDad.destroy();
		}
		vocalsDad = null;
		instPlaying = -1;
		speedPlaying = 1;
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficulties.length - 1;
		if (curDifficulty >= CoolUtil.difficulties.length)
			curDifficulty = 0;

		lastDifficultyName = CoolUtil.difficulties[curDifficulty];

		#if HIGHSCORE_ALLOWED
		if (songs.length > 0) {
			intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
			intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		}
		#end

		PlayState.storyDifficulty = curDifficulty;
		if (CoolUtil.difficulties.length > 1) {
			diffText.text = '< ${CoolUtil.difficultyString()} >';
		} else {
			diffText.text = CoolUtil.difficultyString();
		}
		positionHighscore();
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;
		
		if (songs.length > 0) {
			var newColor:Int = songs[curSelected].color;
			if (newColor != intendedColor) {
				if (colorTween != null) {
					colorTween.cancel();
				}
				intendedColor = newColor;
				colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
					onComplete: function(twn:FlxTween) {
						colorTween = null;
					}
				});
			}

			#if HIGHSCORE_ALLOWED
			intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
			intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
			#end

			var bullShit:Int = 0;

			for (i in 0...iconArray.length)
			{
				iconArray[i].alpha = 0.6;
			}

			iconArray[curSelected].alpha = 1;

			for (item in grpSongs.members)
			{
				item.targetY = bullShit - curSelected;
				bullShit++;

				item.alpha = 0.6;

				if (item.targetY == 0)
				{
					item.alpha = 1;
				}
			}
			
			Paths.currentModDirectory = songs[curSelected].folder;
			PlayState.storyWeek = songs[curSelected].week;

			CoolUtil.getDifficulties(songs[curSelected].songName, true);
		}

		if(CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty))
		{
			curDifficulty = FlxMath.maxInt(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty));
		}
		else
		{
			curDifficulty = 0;
		}

		var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
		if (newPos < 0) newPos = CoolUtil.difficulties.indexOf(lastDifficultyName.charAt(0).toUpperCase() + lastDifficultyName.substr(1));
		if (newPos < 0) newPos = CoolUtil.difficulties.indexOf(lastDifficultyName.toLowerCase());
		if (newPos < 0) newPos = CoolUtil.difficulties.indexOf(lastDifficultyName.toUpperCase());
		if (newPos > -1)
		{
			curDifficulty = newPos;
		}
		changeDiff();
	}

	private function positionHighscore() {
		scoreText.x = FlxG.width - scoreText.width - 6;

		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}

	function sortAlphabetically(a:SongMetadata, b:SongMetadata):Int {
		var val1 = a.songName.toUpperCase();
		var val2 = b.songName.toUpperCase();
		if (val1 < val2) {
		  return -1;
		} else if (val1 > val2) {
		  return 1;
		} else {
		  return 0;
		}
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Paths.currentModDirectory;
		if (this.folder == null) this.folder = '';
	}
}