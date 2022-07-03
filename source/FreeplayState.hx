package;

import flixel.FlxSubState;
#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end
import editors.ChartingState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.system.FlxSound;
import WeekData;

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
	private var grpIcons:FlxTypedGroup<HealthIcon>;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;

	var showSearch:Bool = false;
	var searchY:Float = 0;
	var searchBG:FlxSprite;
	var searchText:AttachedInputText;
	var searchSort:AttachedDropDownMenu;
	static var lastSearch:String = '';
	static var lastSort:String = 'Week (Default)';

	public static var lastPlayed:Array<SongMetadata> = [];

	public static var fromPlayState:Bool = false;

	#if mobile
	var grpButtons:FlxTypedGroup<Button> = new FlxTypedGroup();
	var buttonUP:Button;
	var buttonDOWN:Button;
	var buttonLEFT:Button;
	var buttonRESET:Button;
	var buttonRIGHT:Button;
	var buttonENTER:Button;
	var buttonESC:Button;
	var buttonCTRL:Button;
	var buttonSPACE:Button;
	#end

	override function create()
	{
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

				var meta = Song.getMetaFile(song[0]);
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]), meta.displayName, (meta.iconHiddenUntilPlayed == true));
			}
		}
		WeekData.loadTheFirstEnabledMod();

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);
		bg.screenCenter();

		grpSongs = new FlxTypedGroup();
		add(grpSongs);
		grpIcons = new FlxTypedGroup();
		add(grpIcons);

		songs = songsOG.copy();
		if ((curSelected >= songs.length) || (fromPlayState && lastSort == 'Last Played')) curSelected = 0;
		setListFromSearch(lastSearch, lastSort, false);
		regenMenu(false);
		fromPlayState = false;

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

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

		var leText:String = "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy";
		var size:Int = 16;
		if (songsOG.length < 1) {
			leText = "Press CTRL to open the Gameplay Changers Menu";
		}
		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, size);
		text.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);

		searchBG = new FlxSprite(0, 0).makeGraphic(FlxG.width, 75, FlxColor.BLACK);
		searchBG.alpha = 0.6;
		searchY = -searchBG.height;
		add(searchBG);

		searchText = new AttachedInputText(0, 0, 140);
		searchText.text = lastSearch;
		searchText.sprTracker = searchBG;
		searchText.xAdd = 150;
		searchText.yAdd = (searchBG.height / 2) - (searchText.height / 2);
		add(searchText);
		var text = new AttachedFlxText(0, 0, 0, 'Search:');
		text.sprTracker = searchText;
		text.yAdd = -15;
		add(text);

		var sortTypes = [
			'Week (Default)',
			'Name',
			'Last Played'
		];
		searchSort = new AttachedDropDownMenu(0, 0, FlxUIDropDownMenu.makeStrIdLabelArray(sortTypes, true), function(pressed:String) {
			var selectedType:Int = Std.parseInt(pressed);
			setListFromSearch(lastSearch, sortTypes[selectedType]);
		});
		searchSort.sprTracker = searchBG;
		searchSort.xAdd = 350;
		searchSort.yAdd = (searchBG.height / 2) - (searchSort.header.height / 2);
		add(searchSort);
		var text = new AttachedFlxText(0, 0, 0, 'Sort by:');
		text.sprTracker = searchSort;
		text.yAdd = -15;
		add(text);

		#if mobile
		buttonUP = new Button(10, 130, 'UP');
		buttonDOWN = new Button(buttonUP.x, buttonUP.y + buttonUP.height + 10, 'DOWN');
		buttonLEFT = new Button(834, 564, 'LEFT');
		buttonRESET = new Button(984, buttonLEFT.y, 'RESET');
		buttonRIGHT = new Button(buttonLEFT.x + 300, buttonLEFT.y, 'RIGHT');
		buttonENTER = new Button(492, 564, 'ENTER');
		buttonESC = new Button(buttonENTER.x + 136, buttonENTER.y, 'ESC');
		buttonCTRL = new Button(10,  buttonLEFT.y, 'CTRL');
		buttonSPACE = new Button(984, buttonLEFT.y - buttonLEFT.height - 10, 'SPACE');

		grpButtons.add(buttonUP);
		grpButtons.add(buttonDOWN);
		grpButtons.add(buttonLEFT);
		grpButtons.add(buttonRESET);
		grpButtons.add(buttonRIGHT);
		grpButtons.add(buttonENTER);
		grpButtons.add(buttonESC);
		grpButtons.add(buttonCTRL);
		grpButtons.add(buttonSPACE);
		add(grpButtons);
		#end

		super.create();
	}

	override function openSubState(subState:FlxSubState) {
		#if mobile
		if (!persistentUpdate) {
			for (btn in grpButtons) {
				btn.visible = false;
			}
		}
		#end
		super.openSubState(subState);
	}

	override function closeSubState() {
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
		#if mobile
		for (btn in grpButtons) {
			btn.visible = true;
		}
		#end
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int, displayName:String, iconHiddenUntilPlayed:Bool = false)
	{
		songsOG.push(new SongMetadata(songName, weekNum, songCharacter, color, displayName, iconHiddenUntilPlayed));
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && !Highscore.completedWeek(leWeek.weekBefore));
	}

	public static var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	public static var vocalsDad:FlxSound = null;
	private static var foundDadVocals = false;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		#if !mobile
		FlxG.mouse.visible = true;
		#end

		if (FlxG.sound.music != null) {
			if (FlxG.sound.music.volume < 0.7)
			{
				FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
			}

			if (instPlaying > -1) {
				Conductor.songPosition = FlxG.sound.music.time;
			}
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

		var blockInput:Bool = false;
		var blockPressWhileTypingOn = [searchText];
		for (inputText in blockPressWhileTypingOn) {
			if (inputText.hasFocus) {
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				blockInput = true;
				break;
			}
		}

		if (!blockInput) {
			FlxG.sound.muteKeys = TitleState.muteKeys;
			FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
			var blockPressWhileScrolling = [searchSort];
			for (dropDownMenu in blockPressWhileScrolling) {
				if (dropDownMenu.dropPanel.visible) {
					blockInput = true;
					break;
				}
			}
		}

		if (!blockInput) {
			var upP = controls.UI_UP_P #if mobile || buttonUP.justPressed #end;
			var downP = controls.UI_DOWN_P #if mobile || buttonDOWN.justPressed #end;
			var accepted = controls.ACCEPT || #if mobile buttonENTER.justPressed #else FlxG.mouse.justPressed #end;
			var space = FlxG.keys.justPressed.SPACE #if mobile || buttonSPACE.justPressed #end;
			var ctrl = FlxG.keys.justPressed.CONTROL #if mobile || buttonCTRL.justPressed #end;

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

				if (controls.UI_DOWN || controls.UI_UP #if mobile || buttonDOWN.pressed || buttonUP.pressed #end)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						changeSelection((checkNewHold - checkLastHold) * ((controls.UI_UP #if mobile || buttonUP.pressed #end) ? -shiftMult : shiftMult));
						changeDiff();
					}
				}
			}

			if (songs.length > 0 && CoolUtil.difficulties.length > 1) {
				if ((controls.UI_LEFT_P #if mobile || buttonLEFT.justPressed #end) || (FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel < 0))
					changeDiff(-1);
				else if ((controls.UI_RIGHT_P #if mobile || buttonRIGHT.justPressed #end) || (FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel > 0))
					changeDiff(1);
			}

			if (controls.BACK #if mobile || buttonESC.justPressed #end)
			{
				persistentUpdate = false;
				if (colorTween != null) {
					colorTween.cancel();
				}
				FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
				MusicBeatState.switchState(new MainMenuState());
				FlxG.mouse.visible = false;
			}

			if (ctrl)
			{
				persistentUpdate = false;
				openSubState(new GameplayChangersSubState());
			}
			else if (songs.length > 0)
			{
				if (space)
				{
					if (instPlaying != curSelected)
					{
						destroyFreeplayVocals();
						FlxG.sound.music.volume = 0;
						Conductor.songPosition = 0;
						passedFirstStep = false;
						Paths.currentModDirectory = songs[curSelected].folder;
						var poop:String = Highscore.formatSong(songs[curSelected].songName, curDifficulty, false);
						PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName);
						vocals = new FlxSound();
						vocalsDad = new FlxSound();
						if (PlayState.SONG.needsVoices) {
							vocals.loadEmbedded(Paths.voices(PlayState.SONG.song, CoolUtil.getDifficultyFilePath()));
							
							foundDadVocals = false;
							var file = Paths.voicesDad(PlayState.SONG.song, CoolUtil.getDifficultyFilePath());
							if (file != null) {
								foundDadVocals = true;
								vocalsDad.loadEmbedded(file);
							}
						}

						FlxG.sound.list.add(vocals);
						FlxG.sound.list.add(vocalsDad);
						FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song, CoolUtil.getDifficultyFilePath()), 0.7, false);
						vocals.play();
						vocals.persist = true;
						vocals.volume = 0.7;
						vocalsDad.play();
						vocalsDad.persist = true;
						vocalsDad.volume = 0.7;
						vocals.time = vocalsDad.time = FlxG.sound.music.time;
						Conductor.mapBPMChanges(PlayState.SONG);
						Conductor.changeBPM(PlayState.SONG.bpm);
						Conductor.changeSignature(PlayState.SONG.timeSignature);
						instPlaying = curSelected;
					}
				}
				else if (accepted && !showSearch)
				{
					fromPlayState = true;
					persistentUpdate = false;
					var song:String = songs[curSelected].songName;
					var poop:String = Highscore.formatSong(song, curDifficulty, false);
					trace(poop);

					PlayState.SONG = Song.loadFromJson(poop, song);
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
					
					destroyFreeplayVocals();

					var metadata = songs[curSelected];
					for (i in lastPlayed) {
						if (i.songName == metadata.songName && i.folder == metadata.folder) {
							lastPlayed.remove(i);
							break;
						}
					}
					lastPlayed.unshift(metadata);
					FlxG.save.data.lastPlayed = lastPlayed;
					FlxG.save.flush();
				}
				else if (controls.RESET #if mobile || buttonRESET.justPressed #end)
				{
					persistentUpdate = false;
					openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter, '', songs[curSelected].displayName));
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				}

				if (showSearch && FlxG.mouse.screenY > searchBG.height) {
					showSearch = false;
					searchY = -searchBG.height;
				}
			}
		}

		if (!showSearch && FlxG.mouse.screenY <= 50) {
			showSearch = true;
			searchY = 0;
		}

		searchBG.y = FlxMath.lerp(searchBG.y, searchY, CoolUtil.boundTo(elapsed * 9.6, 0, 1));

		super.update(elapsed);
	}

	override function sectionHit() {
		super.sectionHit();

		if (instPlaying > -1) {
			Conductor.getLastBPM(PlayState.SONG, curStep);

			if (ClientPrefs.camZooms && FlxG.camera.zoom < 1.35) {
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

			if (iconArray[curSelected] != null)
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
		var val1 = a.displayName.toUpperCase();
		var val2 = b.displayName.toUpperCase();
		if (val1 < val2) {
		  return -1;
		} else if (val1 > val2) {
		  return 1;
		} else {
		  return 0;
		}
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if (id == FlxUIInputText.CHANGE_EVENT && (sender is AttachedInputText)) {
			if (sender == searchText) {
				setListFromSearch(searchText.text, lastSort);
			}
		}
	}

	function sortArray(arrayInput:Array<SongMetadata>, sort:String = ''):Array<SongMetadata> {
		var arr = arrayInput.copy();
		switch (sort) {
			case 'Name':
				arr.sort(sortAlphabetically);
			case 'Last Played':
				var sortedArray:Array<SongMetadata> = [];
				for (song in lastPlayed) {
					for (j in arr) {
						if (j.songName == song.songName && j.folder == song.folder) {
							sortedArray.push(j);
							break;
						}
					}
				}
				arr = sortedArray.copy();
		}
		return arr;
	}

	function setListFromSearch(text:String = '', sort:String = '', change:Bool = true) {
		var lastSongs:Array<String> = [];
		for (i in songs) {
			lastSongs.push(WeekData.formatWeek(i.songName, i.folder));
		}

		if (text == '') {
			songs = sortArray(songsOG, sort);
		} else {
			var daText = text.toLowerCase();
			var filteredSongs = songsOG.filter(song -> song.displayName.toLowerCase().startsWith(daText));
			if (sort == 'Name')
				filteredSongs = sortArray(filteredSongs, sort);
			var daOtherSongs = songsOG.filter(song -> (!song.displayName.toLowerCase().startsWith(daText) && song.displayName.toLowerCase().contains(daText)));
			if (sort == 'Name')
				daOtherSongs = sortArray(daOtherSongs, sort);
			for (i in daOtherSongs) {
				if (!filteredSongs.contains(i)) {
					filteredSongs.push(i);
				}
			}
			if (sort != 'Name') {
				filteredSongs = sortArray(filteredSongs, sort);
			}
			if (songs != filteredSongs) {
				songs = filteredSongs;
			}
		}
		lastSearch = text;
		lastSort = sort;

		var equal = true;
		if (songs.length == lastSongs.length) {
			for (i in 0...songs.length) {
				if (WeekData.formatWeek(songs[i].songName, songs[i].folder) != lastSongs[i]) {
					equal = false;
					break;
				}
			}
		} else {
			equal = false;
		}
		if (!equal) {
			regenMenu(change);
		}
	}

	function regenMenu(change:Bool = true) {
		for (i in 0...grpSongs.members.length) {
			var obj = grpSongs.members[0];
			obj.kill();
			grpSongs.remove(obj, true);
			obj.destroy();
		}
		for (i in 0...grpIcons.members.length) {
			var obj = grpIcons.members[0];
			obj.kill();
			grpIcons.remove(obj, true);
			obj.destroy();
		}
		iconArray = [];
		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].displayName, true, false);
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
			var iconVisible = !songs[i].iconHiddenUntilPlayed;
			if (!iconVisible) {
				var match = false;
				for (song in lastPlayed) {
					if (songs[i].songName == song.songName && songs[i].folder == song.folder) {
						match = true;
						break;
					}
				}
				iconVisible = match;
			}
			icon.visible = iconVisible;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			grpIcons.add(icon);
		}
		WeekData.setDirectoryFromWeek();
		if (change) {
			changeSelection(0, false);
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
	public var displayName:String = "";
	public var difficulties:Array<String> = null;
	public var iconHiddenUntilPlayed:Bool = false;

	public function new(song:String, week:Int, songCharacter:String, color:Int, ?displayName:String, iconHiddenUntilPlayed:Bool = false)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Paths.currentModDirectory;
		if (this.folder == null) this.folder = '';
		this.displayName = displayName;
		if (this.displayName == null) this.displayName = this.songName;
		this.iconHiddenUntilPlayed = iconHiddenUntilPlayed;
	}
}