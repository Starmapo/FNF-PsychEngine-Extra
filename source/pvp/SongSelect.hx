package pvp;

import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.text.FlxText;
import flixel.FlxSprite;
import pvp.PvPSongState.SongMetadata;
import flixel.group.FlxSpriteGroup;

class SongSelect extends FlxSpriteGroup {
    public var songs:Array<SongMetadata> = [];
    public var isGamepad:Bool = false;
    public var id:Int = 0;
    public var difficulties:Array<String> = ['Easy', 'Normal', 'Hard'];
    public var ready:Bool = false;

    public var curSelected:Int = 0;
	public var curDifficulty:Int = -1;
	private var lastDifficultyName:String = '';
    public var storyWeek:Int = 0;

    var scoreBG:FlxSprite;
	var diffText:FlxText;

    private var grpSongs:FlxTypedSpriteGroup<Alphabet>;
	private var grpIcons:FlxTypedSpriteGroup<HealthIcon>;

	private var iconArray:Array<HealthIcon> = [];

    var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;

    var noGamepadBlack:FlxSprite;
    var noGamepadText:FlxText;
    var noGamepadSine:Float = 0;

    public function new(x:Float = 0, y:Float = 0, songs:Array<SongMetadata>, isGamepad:Bool = false) {
        super(x, y);
        this.songs = songs.copy();
        this.isGamepad = isGamepad;
        id = (isGamepad ? 0 : 1);

        bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.x = ((FlxG.width / 2) - bg.width) / 2;
		bg.antialiasing = ClientPrefs.globalAntialiasing;
        bg.scrollFactor.set();
        var daClipRect = new FlxRect(0, 0, FlxG.width / 2, bg.frameHeight);
        daClipRect.x -= bg.x;
        bg.clipRect = daClipRect;
        add(bg);

        grpSongs = new FlxTypedSpriteGroup();
		add(grpSongs);
		grpIcons = new FlxTypedSpriteGroup();
		add(grpIcons);

        if (PvPSongState.lastSelected[id] != null)
            curSelected = PvPSongState.lastSelected[id];
		if (curSelected >= songs.length)
            curSelected = 0;
		regenMenu(false);

        scoreBG = new FlxSprite((FlxG.width / 2) * 0.7 - 6, 0).makeGraphic(195, 24, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(0, 0, 0, "", 24);
		diffText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
        diffText.x = Std.int((scoreBG.x + (scoreBG.width / 2)) - (diffText.width / 2));
		add(diffText);

        if (isGamepad) {
            noGamepadBlack = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width / 2), 720, FlxColor.BLACK);
            noGamepadBlack.scrollFactor.set();
            noGamepadBlack.alpha = 0.8;
            noGamepadBlack.visible = (FlxG.gamepads.lastActive == null);
            add(noGamepadBlack);

            noGamepadText = new FlxText(0, 360 - 16, FlxG.width / 2, "Waiting for gamepad...", 32);
            noGamepadText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            noGamepadText.scrollFactor.set();
            noGamepadText.borderSize = 2;
            noGamepadText.visible = (FlxG.gamepads.lastActive == null);
            add(noGamepadText);
        }

        if (songs.length > 0)
            bg.color = songs[curSelected].color;
		intendedColor = bg.color;

        if (PvPSongState.lastDiff[id] == null) {
            lastDifficultyName = CoolUtil.defaultDifficulty;
            curDifficulty = FlxMath.maxInt(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName));
        } else {
            lastDifficultyName = PvPSongState.lastDiffName[id];
            curDifficulty = PvPSongState.lastDiff[id];
        }

        changeSelection();
    }

    var holdTime:Float = 0;
    override function update(elapsed:Float) {
        super.update(elapsed);

        for (i in 0...grpSongs.length) {
            var item = grpSongs.members[i];
            iconArray[i].y = item.y - 15;
        }

        if (!PvPSongState.exiting) {
            var controls = PlayerSettings.player1.controls;
            var upP = controls.UI_UP_P;
            var downP = controls.UI_DOWN_P;
            var leftP = controls.UI_LEFT_P;
            var rightP = controls.UI_RIGHT_P;
            var up = controls.UI_UP;
            var down = controls.UI_DOWN;
            var accepted = controls.ACCEPT;
            var back = controls.BACK;

            if (isGamepad) {
                var gamepad = FlxG.gamepads.lastActive;
                if (gamepad != null) {
                    noGamepadBlack.visible = false;
                    noGamepadText.visible = false;
                    upP = (gamepad.justPressed.LEFT_STICK_DIGITAL_UP || gamepad.justPressed.DPAD_UP);
                    downP = (gamepad.justPressed.LEFT_STICK_DIGITAL_DOWN || gamepad.justPressed.DPAD_DOWN);
                    leftP = (gamepad.justPressed.LEFT_STICK_DIGITAL_LEFT || gamepad.justPressed.DPAD_LEFT);
                    rightP = (gamepad.justPressed.LEFT_STICK_DIGITAL_RIGHT || gamepad.justPressed.DPAD_RIGHT);
                    up = (gamepad.pressed.LEFT_STICK_DIGITAL_UP || gamepad.pressed.DPAD_UP);
                    down = (gamepad.pressed.LEFT_STICK_DIGITAL_DOWN || gamepad.pressed.DPAD_DOWN);
                    accepted = (gamepad.justPressed.A);
                    back = (gamepad.justPressed.B);
                } else {
                    noGamepadBlack.visible = true;
                    noGamepadText.visible = true;
                    up = false;
                    down = false;
                    upP = false;
                    downP = false;
                    leftP = false;
                    rightP = false;
                    accepted = false;
                    back = false;
                }
            }

            var shiftMult:Int = 1;
            if (!isGamepad && FlxG.keys.pressed.SHIFT) shiftMult = 3;

            if (!ready) {
                if (songs.length > 1)
                {
                    if (upP)
                    {
                        changeSelection(-shiftMult);
                        holdTime = 0;
                    }
                    if (downP)
                    {
                        changeSelection(shiftMult);
                        holdTime = 0;
                    }

                    if (down || up)
                    {
                        var checkLastHold:Int = Math.floor((holdTime - 0.5) * 20);
                        holdTime += elapsed;
                        var checkNewHold:Int = Math.floor((holdTime - 0.5) * 20);

                        if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
                        {
                            changeSelection((checkNewHold - checkLastHold) * (up ? -shiftMult : shiftMult));
                            changeDiff();
                        }
                    }
                }

                if (songs.length > 0 && difficulties.length > 1) {
                    if (leftP)
                        changeDiff(-1);
                    else if (rightP)
                        changeDiff(1);
                }
            }

            if (back)
            {
                if (!ready) {
                    var gamepad = FlxG.gamepads.lastActive;
                    if (gamepad != null)
                        controls.addDefaultGamepad(0);

                    PvPSongState.exiting = true;
                    if (colorTween != null) {
                        colorTween.cancel();
                    }
                    CoolUtil.playCancelSound();
                    MusicBeatState.switchState(new MainMenuState());
                } else {
                    playerUnready();
                }
            }

            if (songs.length > 0 && accepted && !ready)
            {
                playerReady();
            }
        }

        if (isGamepad && noGamepadText.visible) {
            noGamepadSine += 180 * elapsed;
            noGamepadText.alpha = 1 - Math.sin((Math.PI * noGamepadSine) / 180);
        }
    }

    function playerReady() {
        ready = true;
        for (i in 0...grpSongs.length) {
            var item = grpSongs.members[i];
            if (item.targetY != 0) {
                item.visible = false;
                iconArray[i].visible = false;
            }
        }
        CoolUtil.playConfirmSound();
    }

    function playerUnready() {
        ready = false;
        for (i in 0...grpSongs.length) {
            var item = grpSongs.members[i];
            item.visible = true;
            iconArray[i].visible = true;
        }
        CoolUtil.playCancelSound();
    }

    private function positionHighscore() {
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}

    function difficultyString():String
	{
		return difficulties[curDifficulty].toUpperCase();
	}

    function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = difficulties.length - 1;
		if (curDifficulty >= difficulties.length)
			curDifficulty = 0;

        if (songs[curSelected].nothing) {
            curDifficulty = 0;
            lastDifficultyName = '';
            diffText.text = '';
        } else {
            lastDifficultyName = difficulties[curDifficulty];

            if (difficulties.length > 1) {
                diffText.text = '< ${difficultyString()} >';
            } else {
                diffText.text = difficultyString();
            }
            positionHighscore();
        }
        PvPSongState.lastDiff[id] = curDifficulty;
        PvPSongState.lastDiffName[id] = lastDifficultyName;
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
				iconArray[i].alpha = (songs[i].nothing ? 0 : 0.6);

			if (iconArray[curSelected] != null && !songs[curSelected].nothing)
				iconArray[curSelected].alpha = 1;

			for (item in grpSongs.members) {
				item.targetY = bullShit - curSelected;
				bullShit++;

				item.alpha = 0.6;

				if (item.targetY == 0)
				{
					item.alpha = 1;
				}
			}

			storyWeek = songs[curSelected].week;
			
            if (songs[curSelected].difficulties == null) {
			    CoolUtil.getDifficulties(songs[curSelected].songName, true);
                difficulties = CoolUtil.difficulties.copy();
            } else
                difficulties = songs[curSelected].difficulties.split(',');
		}

		if(difficulties.contains(CoolUtil.defaultDifficulty))
			curDifficulty = FlxMath.maxInt(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty));
		else
			curDifficulty = 0;

		var newPos:Int = difficulties.indexOf(lastDifficultyName);
		if (newPos < 0) newPos = difficulties.indexOf(lastDifficultyName.charAt(0).toUpperCase() + lastDifficultyName.substr(1));
		if (newPos < 0) newPos = difficulties.indexOf(lastDifficultyName.toLowerCase());
		if (newPos < 0) newPos = difficulties.indexOf(lastDifficultyName.toUpperCase());
		if (newPos > -1)
		{
			curDifficulty = newPos;
		}
		changeDiff();
        PvPSongState.lastSelected[id] = curSelected;
	}

    public function selectRandom() {
        curSelected = FlxG.random.int(1, songs.length - 1);
        storyWeek = songs[curSelected].week;
        if (songs[curSelected].difficulties == null) {
            CoolUtil.getDifficulties(songs[curSelected].songName, true);
            difficulties = CoolUtil.difficulties.copy();
        } else
            difficulties = songs[curSelected].difficulties.split(',');
        curDifficulty = FlxG.random.int(0, difficulties.length - 1);
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
			var songText:Alphabet = new Alphabet(0, (35 * i) + 15, songs[i].displayName, true, false, 0, 0.5);
			songText.isMenuItem = true;
			songText.targetY = i;
            songText.yMult = 80;
            if (!isGamepad) songText.xAdd = FlxG.width / 2;
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
            icon.setGraphicSize(Std.int(icon.width * 0.5));
            updateIconHitbox(icon);
			icon.sprTracker = songText;

            if (90 + songText.width + 10 + icon.width > 640)
            {
                var daWidth = 640 - (100 + icon.width);
                var textScale:Float = daWidth / songText.width;
                songText.scale.x *= textScale;
                for (letter in songText.lettersArray)
                {
                    letter.x *= textScale;
                    letter.offset.x *= textScale;
                }
            }

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			grpIcons.add(icon);
		}
		if (change)
			changeSelection(0, false);
	}

    function updateIconHitbox(icon:HealthIcon) {
        icon.updateHitbox();
        icon.offset.set((-0.5 * (icon.width - icon.frameWidth)) + icon.iconOffsets[0], (-0.5 * (icon.height - icon.frameHeight)) + icon.iconOffsets[1]);
    }
}