package pvp;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.FlxG;
import openfl.geom.Rectangle;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

using StringTools;

typedef CharacterData = {
    var name:String;
    var displayName:String;
    var alternateForms:Array<AlternateForm>;
}

typedef AlternateForm = {
    var name:String;
    var displayName:String;
}

class CharacterSelect extends FlxSpriteGroup {
    public var characters:Array<CharacterData> = [];
    public var fullCharList:Array<String> = [];

    public var grpIcons:FlxTypedSpriteGroup<HealthIcon>;
    var panel:FlxSprite;
    var cornerSize:Int = 5;
    var curSelectSprite(get, never):FlxSprite;
    var select1:AttachedSprite;
    var select2:AttachedSprite;
    
    var grpIconsPos:FlxPoint = new FlxPoint(5, 5);

    public var curSelectedX:Int = 0;
    public var curSelectedY:Int = 0;
    var curCharSelect:Int = 0;
    var firstSelected:Array<Int> = [0, 0];

    public var isGamepad:Bool = false;
    public var id:Int = 0;

    var curCharIndex(get, never):Int;
    var curCharPos(get, never):FlxPoint;
    var maxX:Int = 0;
    var maxY:Int = 1;

    var character:FlxSprite;
    var characterText:FlxText;
    var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;
    var selectingAlt:Bool = false;
    public var selectedChars:Array<String> = ['bf', 'pico'];
    var curAltIndex:Int = 0;
    public var ready:Bool = false;
    var curAlts(get, never):Array<AlternateForm>;
    public var readyText:FlxText;

    var noGamepadBlack:FlxSprite;
    var noGamepadText:FlxText;
    var noGamepadSine:Float = 0;

    function get_curCharIndex() {
        return curSelectedX * 2 + curSelectedY;
    }

    function get_curCharPos() {
        return new FlxPoint(grpIcons.members[curCharIndex].x, grpIcons.members[curCharIndex].y);
    }

    function get_curAlts() {
        return characters[curCharIndex].alternateForms;
    }

    function get_curSelectSprite() {
        return curCharSelect > 0 ? select2 : select1;
    }

    public function new(x:Float = 0, y:Float = 0, characters:Array<CharacterData>, isGamepad:Bool = false) {
        super(x, y);
        this.characters = characters;
        this.isGamepad = isGamepad;
        id = (isGamepad ? 0 : 1);

        for (i in characters) {
            fullCharList.push(i.name);
            for (j in i.alternateForms)
                fullCharList.push(j.name);
        }

        scrollFactor.set();

        panel = new FlxSprite(20, 560);
        makeSelectorGraphic(panel, 600, 160, 0xff999999);
        panel.scrollFactor.set();

        grpIcons = new FlxTypedSpriteGroup(25, 565);
        grpIcons.scrollFactor.set();

        for (i in 0...characters.length) {
            var char = characters[i].name;
            var charFile = Character.getFile(char);
            if (char == '!random')
                charFile.healthicon = '!random'; //incredibly smart coding
            
            var icon = new HealthIcon(charFile.healthicon);
            icon.setGraphicSize(75, 75);
            updateIconHitbox(icon);
            icon.x = 75 * Math.floor(i / 2);
            if (icon.x / 75 > maxX)
                maxX = Std.int(icon.x / 75);
            icon.y = 75 * (i % 2);
            grpIcons.add(icon);
        }

        select1 = new AttachedSprite('pvp/select1');
        select1.scrollFactor.set();
        select1.copyAlpha = false;
        select2 = new AttachedSprite('pvp/select2');
        select2.scrollFactor.set();
        select2.alpha = 0;
        select2.copyAlpha = false;

        character = new FlxSprite();
        character.antialiasing = ClientPrefs.globalAntialiasing;
        character.scrollFactor.set();
        if (!isGamepad) character.flipX = true;

        characterText = new FlxText(0, panel.y - 64, 640, "", 32);
		characterText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		characterText.scrollFactor.set();
        characterText.borderSize = 2;

        leftArrow = new FlxSprite(0, 280);
		leftArrow.frames = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		leftArrow.antialiasing = ClientPrefs.globalAntialiasing;
        leftArrow.visible = false;
        leftArrow.y -= leftArrow.height / 2;

        rightArrow = new FlxSprite(640, 280);
		rightArrow.frames = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		rightArrow.animation.addByPrefix('idle', "arrow right");
		rightArrow.animation.addByPrefix('press', "arrow push right");
		rightArrow.animation.play('idle');
		rightArrow.antialiasing = ClientPrefs.globalAntialiasing;
        rightArrow.visible = false;
        rightArrow.x -= rightArrow.width;
        rightArrow.y -= rightArrow.height / 2;

        readyText = new FlxText(0, 280 - 32, 640, "READY", 64);
		readyText.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		readyText.scrollFactor.set();
        readyText.borderSize = 2;
        readyText.visible = false;

        if (isGamepad) {
            noGamepadBlack = new FlxSprite(0, 0).makeGraphic(640, 720, FlxColor.BLACK);
            noGamepadBlack.scrollFactor.set();
            noGamepadBlack.alpha = 0.8;
            noGamepadBlack.visible = (FlxG.gamepads.lastActive == null);

            noGamepadText = new FlxText(0, 360 - 16, 640, "Waiting for gamepad...", 32);
            noGamepadText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            noGamepadText.scrollFactor.set();
            noGamepadText.borderSize = 2;
            noGamepadText.visible = (FlxG.gamepads.lastActive == null);
        }

        add(panel);
        add(grpIcons);
        add(select1);
        add(select2);
        add(character);
        add(characterText);
        add(leftArrow);
        add(rightArrow);
        add(readyText);
        if (isGamepad) {
            add(noGamepadBlack);
            add(noGamepadText);
        }

        if (PvPCharacterState.lastCharacters[id].length == 2) {
            curSelectedX = PvPCharacterState.lastCharacters[id][0];
            curSelectedY = PvPCharacterState.lastCharacters[id][1];
        }

        setClipRect();
        changeSelection();
    }

    var holdTime:Float = 0;
    override function update(elapsed:Float) {
        var lerpVal:Float = CoolUtil.boundTo(elapsed * 10, 0, 1);
        grpIcons.setPosition(FlxMath.lerp(grpIcons.x, panel.x + grpIconsPos.x, lerpVal), FlxMath.lerp(grpIcons.y, panel.y + grpIconsPos.y, lerpVal));

        super.update(elapsed);

        if (!PvPCharacterState.exiting) {
            var controls = PlayerSettings.player1.controls;
            var leftP = controls.UI_LEFT_P;
            var rightP = controls.UI_RIGHT_P;
            var left = controls.UI_LEFT;
            var right = controls.UI_RIGHT;
            var upP = controls.UI_UP_P;
            var downP = controls.UI_DOWN_P;
            var accept = controls.ACCEPT;
            var back = controls.BACK;
            if (isGamepad) {
                var gamepad = FlxG.gamepads.lastActive;
                if (gamepad != null) {
                    noGamepadBlack.visible = false;
                    noGamepadText.visible = false;
                    leftP = gamepad.justPressed.LEFT_STICK_DIGITAL_LEFT || gamepad.justPressed.DPAD_LEFT;
                    rightP = gamepad.justPressed.LEFT_STICK_DIGITAL_RIGHT || gamepad.justPressed.DPAD_RIGHT;
                    left = gamepad.pressed.LEFT_STICK_DIGITAL_LEFT || gamepad.pressed.DPAD_LEFT;
                    right = gamepad.pressed.LEFT_STICK_DIGITAL_RIGHT || gamepad.pressed.DPAD_RIGHT;
                    upP = gamepad.justPressed.LEFT_STICK_DIGITAL_UP || gamepad.justPressed.DPAD_UP;
                    downP = gamepad.justPressed.LEFT_STICK_DIGITAL_DOWN || gamepad.justPressed.DPAD_DOWN;
                    accept = gamepad.justPressed.A;
                    back = gamepad.justPressed.B;
                } else {
                    noGamepadBlack.visible = true;
                    noGamepadText.visible = true;
                    leftP = false;
                    rightP = false;
                    left = false;
                    right = false;
                    upP = false;
                    downP = false;
                    accept = false;
                    back = false;
                }
            }
            if (ready) {
                if (back) {
                    playerUnready();
                }
            } else {
                if (!selectingAlt) {
                    if (grpIcons.length > 1) {
                        if (upP) {
                            changeSelection(0, -1);
                        }
                        if (downP) {
                            changeSelection(0, 1);
                        }
                        if (grpIcons.length > 2) {
                            if (leftP) {
                                changeSelection(-1);
                                holdTime = 0;
                            }
                            if (rightP) {
                                changeSelection(1);
                                holdTime = 0;
                            }
                            if (left || right)
                            {
                                var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
                                holdTime += elapsed;
                                var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
                
                                if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
                                {
                                    changeSelection((checkNewHold - checkLastHold) * (left ? -1 : 1));
                                }
                            }
                        }
                    }
        
                    if (back) {
                        if (curCharSelect > 0) {
                            curCharSelect = 0;
                            select2.alpha = 0;
                            curSelectedX = firstSelected[0];
                            curSelectedY = firstSelected[1];
                            changeSelection();
                        } else {
                            CoolUtil.playCancelSound();
                            MusicBeatState.switchState(new PvPSongState());
                            PvPCharacterState.exiting = true;
                        }
                    }

                    if (accept) {
                        if (curAlts.length > 0) {
                            selectingAlt = true;
                            leftArrow.visible = true;
                            rightArrow.visible = true;
                            CoolUtil.playScrollSound();
                        } else {
                            if (curCharSelect > 0)
                                playerReady();
                            else {
                                firstSelected = [curSelectedX, curSelectedY];
                                curCharSelect = 1;
                                select2.alpha = 1;
                                var lastAlt = curAltIndex;
                                changeSelection();
                                curAltIndex = lastAlt;
                                changeAlt();
                                CoolUtil.playConfirmSound();
                            }
                        }
                    }
                } else {
                    if (curAlts.length > 0) {
                        if (left)
                            leftArrow.animation.play('press');
                        else
                            leftArrow.animation.play('idle');

                        if (right)
                            rightArrow.animation.play('press')
                        else
                            rightArrow.animation.play('idle');

                        if (leftP) {
                            changeAlt(-1);
                            CoolUtil.playScrollSound();
                        }
                        if (rightP) {
                            changeAlt(1);
                            CoolUtil.playScrollSound();
                        }
                    }

                    if (back) {
                        selectingAlt = false;
                        leftArrow.visible = false;
                        rightArrow.visible = false;
                        curAltIndex = 0;
                        changeAlt();
                        CoolUtil.playCancelSound();
                    } else if (accept) {
                        if (curCharSelect > 0)
                            playerReady();
                        else {
                            firstSelected = [curSelectedX, curSelectedY];
                            curCharSelect = 1;
                            select2.alpha = 1;
                            var lastAlt = curAltIndex;
                            changeSelection();
                            curAltIndex = lastAlt;
                            changeAlt();
                            CoolUtil.playConfirmSound();
                        }
                    }
                }
            }
        }

        setClipRect();

        if (isGamepad && noGamepadText.visible) {
            noGamepadSine += 180 * elapsed;
            noGamepadText.alpha = 1 - Math.sin((Math.PI * noGamepadSine) / 180);
        }
    }

    function changeSelection(x:Int = 0, y:Int = 0) {
        var playSound = false;
        var lastX = curSelectedX;
        curSelectedX += x;
        if (curSelectedX < 0) {
			curSelectedX = maxX;
            if (grpIcons.members[curCharIndex] == null)
                curSelectedX -= 1;
        }
		if (curSelectedX > maxX || grpIcons.members[curCharIndex] == null)
			curSelectedX = 0;
        if (curSelectedX != lastX)
            playSound = true;
        
        var lastY = curSelectedY;
        curSelectedY += y;
        if (curSelectedY < 0)
			curSelectedY = maxY;
        if (curSelectedY > maxY)
            curSelectedY = 0;
        if (grpIcons.members[curCharIndex] == null)
            curSelectedY -= 1;
        if (curSelectedY != lastY)
            playSound = true;

        if (playSound)
            CoolUtil.playScrollSound();

        if (maxX > 8)
            grpIconsPos.x = FlxMath.remapToRange(curSelectedX, 0, maxX, 5, panel.width - grpIcons.width - 5);
        curAltIndex = 0;
        changeAlt();

        if (curCharSelect == 0) {
            select1.sprTracker = grpIcons.members[curCharIndex];
            PvPCharacterState.lastCharacters[id] = [curSelectedX, curSelectedY];
        }
        select2.sprTracker = grpIcons.members[curCharIndex];
    }

    function changeAlt(add:Int = 0) {
        curAltIndex += add;
        if (curAltIndex < 0)
			curAltIndex = curAlts.length;
		if (curAltIndex > curAlts.length)
			curAltIndex = 0;

        if (curAltIndex > 0) {
            selectedChars[curCharSelect] = curAlts[curAltIndex - 1].name;
            characterText.text = curAlts[curAltIndex - 1].displayName;
        } else {
            selectedChars[curCharSelect] = characters[curCharIndex].name;
            characterText.text = characters[curCharIndex].displayName;
        }
        character.loadGraphic(Paths.image('pvp/char/${selectedChars[curCharSelect]}'));
        character.flipX = (characters[curCharIndex].name != '!random' && !isGamepad);
    }

    function updateIconHitbox(icon:HealthIcon) {
        icon.updateHitbox();
        icon.offset.set(-0.5 * (icon.width - icon.frameWidth), -0.5 * (icon.height - icon.frameHeight));
    }

    function setClipRect() {
        var sprites:Array<FlxSprite> = [];
        for (spr in grpIcons)
            sprites.push(spr);
        sprites.push(select1);
        sprites.push(select2);
        for (spr in sprites) {
            if (spr.x + spr.width < panel.x || spr.x > panel.x + panel.width) {
                spr.visible = false;
            } else {
                spr.visible = true;
                var swagRect = new FlxRect(0, 0, spr.frameWidth, spr.frameHeight);
                if (spr.x < panel.x) {
                    swagRect.x += Math.abs(panel.x - spr.x) / spr.scale.x;
                    swagRect.width -= swagRect.x;
                    spr.clipRect = swagRect;
                } else if (spr.x + spr.width > panel.x + panel.width) {
                    swagRect.width -= ((spr.x + spr.width) - (panel.x + panel.width)) / spr.scale.x;
                    spr.clipRect = swagRect;
                }
                spr.clipRect = swagRect;
            }
        }
    }

    function playerReady() {
        ready = true;
        readyText.visible = true;
        character.alpha = 0.5;
        leftArrow.alpha = rightArrow.alpha = 0.5;
        CoolUtil.playConfirmSound();
    }

    function playerUnready() {
        ready = false;
        readyText.visible = false;
        character.alpha = 1;
        leftArrow.alpha = rightArrow.alpha = 1;
        CoolUtil.playCancelSound();
    }

    public function fadeStuff() {
        var stuff = [panel, grpIcons, select1, select2, leftArrow, rightArrow];
        for (i in stuff) {
            FlxTween.tween(i, {alpha: 0}, 0.4, {
                ease: FlxEase.quadOut,
                onComplete: function(twn:FlxTween)
                {
                    i.kill();
                }
            });
        }
    }

    function makeSelectorGraphic(panel:FlxSprite,w,h,color:FlxColor)
	{
		panel.makeGraphic(w, h, color);
		panel.pixels.fillRect(new Rectangle(0, 190, panel.width, 5), 0x0);

		panel.pixels.fillRect(new Rectangle(0, 0, cornerSize, cornerSize), 0x0);														 //top left
		drawCircleCornerOnSelector(panel,false, false,color);
		panel.pixels.fillRect(new Rectangle(panel.width - cornerSize, 0, cornerSize, cornerSize), 0x0);							 //top right
		drawCircleCornerOnSelector(panel,true, false,color);
		panel.pixels.fillRect(new Rectangle(0, panel.height - cornerSize, cornerSize, cornerSize), 0x0);							 //bottom left
		drawCircleCornerOnSelector(panel,false, true,color);
		panel.pixels.fillRect(new Rectangle(panel.width - cornerSize, panel.height - cornerSize, cornerSize, cornerSize), 0x0); //bottom right
		drawCircleCornerOnSelector(panel,true, true,color);
	}

    function drawCircleCornerOnSelector(panel:FlxSprite,flipX:Bool, flipY:Bool,color:FlxColor)
	{
		var antiX:Float = (panel.width - cornerSize);
		var antiY:Float = flipY ? (panel.height - 1) : 0;
		if(flipY) antiY -= 2;
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 1), Std.int(Math.abs(antiY - 8)), 10, 3), color);
		if(flipY) antiY += 1;
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 2), Std.int(Math.abs(antiY - 6)),  9, 2), color);
		if(flipY) antiY += 1;
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 3), Std.int(Math.abs(antiY - 5)),  8, 1), color);
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 4), Std.int(Math.abs(antiY - 4)),  7, 1), color);
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 5), Std.int(Math.abs(antiY - 3)),  6, 1), color);
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 6), Std.int(Math.abs(antiY - 2)),  5, 1), color);
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 8), Std.int(Math.abs(antiY - 1)),  3, 1), color);
	}
}