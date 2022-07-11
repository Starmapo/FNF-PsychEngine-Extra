package pvp;

import haxe.Json;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;
import flixel.util.FlxColor;
#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

using StringTools;

class PvPSongState extends MusicBeatState {
    var songs:Array<SongMetadata> = [];
	var songsOG:Array<SongMetadata> = [];

    private static var curSelected:Int = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = '';

    var scoreBG:FlxSprite;
	var diffText:FlxText;

    private var grpSongs:FlxTypedGroup<Alphabet>;
	private var grpIcons:FlxTypedGroup<HealthIcon>;

	private var iconArray:Array<HealthIcon> = [];

    var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;

    override function create() {
		PlayerSettings.player1.controls.removeGamepad(0);
		MainMenuState.inPvP = true;

        persistentUpdate = true;
		WeekData.reloadWeekFiles(false);
		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();

        #if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

        var rawJson = Paths.getContent(Paths.json('pvpSongs')).trim();
        var stuff:Dynamic = Json.parse(rawJson);
        var daList:Dynamic = Reflect.getProperty(stuff, "songs");

        for (i in 0...WeekData.weeksList.length) {
			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);

			for (song in leWeek.songs)
			{
                var songData:Dynamic = Reflect.getProperty(daList, Paths.formatToSongPath(song[0]));
                if (songData == null) {
                    songData = {
						blocked: false,
                        skipStage: false,
                        difficulties: null
                    };
                }
				if (songData.blocked == true) continue;

				var colors:Array<Int> = song[2];
				if (colors == null || colors.length != 3)
				{
					colors = [146, 113, 253];
				}

				songsOG.push(new SongMetadata(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]), Song.getDisplayName(song[0]), (songData.skipStage == true), songData.difficulties));
			}
		}

        bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);
		bg.screenCenter();

		grpSongs = new FlxTypedGroup();
		add(grpSongs);
		grpIcons = new FlxTypedGroup();
		add(grpIcons);

        songs = songsOG.copy();
        songs.sort(sortAlphabetically);
		if (curSelected >= songs.length) curSelected = 0;
		regenMenu(false);

        scoreBG = new FlxSprite(FlxG.width * 0.7 - 6, 0).makeGraphic(390, 24, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(FlxG.width * 0.7, 0, 0, "", 24);
		diffText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
        diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
		add(diffText);

        if (songs.length > 0) bg.color = songs[curSelected].color;
		intendedColor = bg.color;

        if (lastDifficultyName == '')
        {
            lastDifficultyName = CoolUtil.defaultDifficulty;
        }
        curDifficulty = FlxMath.maxInt(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName));
        
        changeSelection();

        super.create();
    }

    var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
        var upP = controls.UI_UP_P;
        var downP = controls.UI_DOWN_P;
		var leftP = controls.UI_LEFT_P;
        var rightP = controls.UI_RIGHT_P;
        var up = controls.UI_UP;
        var down = controls.UI_DOWN;
        var accepted = controls.ACCEPT || FlxG.mouse.justPressed;
        var back = controls.BACK;

        var gamepad = FlxG.gamepads.lastActive;
        if (gamepad != null) {
            if (gamepad.justPressed.LEFT_STICK_DIGITAL_UP || gamepad.justPressed.DPAD_UP) upP = true;
            if (gamepad.justPressed.LEFT_STICK_DIGITAL_DOWN || gamepad.justPressed.DPAD_DOWN) downP = true;
			if (gamepad.justPressed.LEFT_STICK_DIGITAL_LEFT || gamepad.justPressed.DPAD_LEFT) leftP = true;
			if (gamepad.justPressed.LEFT_STICK_DIGITAL_RIGHT || gamepad.justPressed.DPAD_RIGHT) rightP = true;
            if (gamepad.pressed.LEFT_STICK_DIGITAL_UP || gamepad.pressed.DPAD_UP) up = true;
            if (gamepad.pressed.LEFT_STICK_DIGITAL_DOWN || gamepad.pressed.DPAD_DOWN) down = true;
            if (gamepad.justPressed.A) accepted = true;
            if (gamepad.justPressed.B) back = true;
        }

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

            if (down || up)
            {
                var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
                holdTime += elapsed;
                var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

                if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
                {
                    changeSelection((checkNewHold - checkLastHold) * (up ? -shiftMult : shiftMult));
                    changeDiff();
                }
            }
        }

        if (songs.length > 0 && CoolUtil.difficulties.length > 1) {
            if (leftP || (FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel < 0))
                changeDiff(-1);
            else if (rightP || (FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel > 0))
                changeDiff(1);
        }

        if (back)
        {
			var gamepad = FlxG.gamepads.getByID(0);
			if (gamepad != null)
				PlayerSettings.player1.controls.addDefaultGamepad(0);

            persistentUpdate = false;
            if (colorTween != null) {
                colorTween.cancel();
            }
            CoolUtil.playCancelSound();
            MusicBeatState.switchState(new MainMenuState());
        }

       if (songs.length > 0)
        {
            if (accepted)
            {
                persistentUpdate = false;
                var song:String = songs[curSelected].songName;
                var poop:String = Highscore.formatSong(song, curDifficulty);
                trace(poop);

                PlayState.SONG = Song.loadFromJson(poop, song);
                PlayState.storyDifficulty = curDifficulty;

                trace('CURRENT WEEK: ${WeekData.getWeekName()}');
                if (colorTween != null) {
                    colorTween.cancel();
                }
                
				if (FlxG.keys.pressed.SHIFT) {
					LoadingState.loadAndSwitchState(new PvPPlayState());
				} else {
					if (songs[curSelected].skipStage) {
						PvPPlayState.skipStage = true;
					}
                	MusicBeatState.switchState(new PvPCharacterState());
				}
                CoolUtil.playConfirmSound();
            }
        }

		super.update(elapsed);
	}

    function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficulties.length - 1;
		if (curDifficulty >= CoolUtil.difficulties.length)
			curDifficulty = 0;

		lastDifficultyName = CoolUtil.difficulties[curDifficulty];

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
		if (playSound) CoolUtil.playScrollSound();

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

			PlayState.storyWeek = songs[curSelected].week;
			
            if (songs[curSelected].difficulties == null)
			    CoolUtil.getDifficulties(songs[curSelected].songName, true);
            else
                CoolUtil.difficulties = songs[curSelected].difficulties.split(',');
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

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			grpIcons.add(icon);
		}
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
	public var displayName:String = "";
	public var difficulties:String = null;
    public var skipStage:Bool = false;

	public function new(song:String, week:Int, songCharacter:String, color:Int, ?displayName:String, ?skipStage:Bool = false, ?difficulties:String)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.displayName = displayName;
		if (this.displayName == null) this.displayName = this.songName;
        this.skipStage = skipStage;
        this.difficulties = difficulties.trim();
	}
}