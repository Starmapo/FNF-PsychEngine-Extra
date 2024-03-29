package editors;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.animation.FlxAnimation;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.ui.FlxButton;
import haxe.Json;
import haxe.io.Path;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import Character;
#if sys
import sys.FileSystem;
#end

using StringTools;

/**
	*DEBUG MODE
 */
class CharacterEditorState extends MusicBeatState
{
	var char:Character;
	var ghostChar:Character;
	var guideChar:FlxSprite;
	var textAnim:FlxText;
	var bgLayer:FlxTypedGroup<FlxSprite>;
	var charLayer:FlxTypedGroup<Character>;
	var dumbTexts:FlxTypedGroup<FlxText>;
	var curAnim:Int = 0;
	var daAnim:String = 'spooky';
	var goToPlayState:Bool = true;
	var camFollow:FlxObject;

	public function new(daAnim:String = 'spooky', goToPlayState:Bool = true)
	{
		super();
		this.daAnim = daAnim;
		this.goToPlayState = goToPlayState;
	}

	var UI_box:FlxUITabMenu;
	var UI_characterbox:FlxUITabMenu;

	private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;
	private var camMenu:FlxCamera;

	var changeBGbutton:FlxButton;
	var leHealthIcon:HealthIcon;
	var characterList:Array<String> = [];

	var cameraFollowPointer:FlxSprite;
	var healthBarBG:FlxSprite;

	override function create()
	{
		super.create();
		
		camEditor = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camMenu = new FlxCamera();
		camMenu.bgColor.alpha = 0;

		FlxG.cameras.reset(camEditor);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camMenu, false);

		bgLayer = new FlxTypedGroup<FlxSprite>();
		add(bgLayer);
		guideChar = new FlxSprite();
		guideChar.visible = false;
		add(guideChar);
		charLayer = new FlxTypedGroup<Character>();
		add(charLayer);

		var pointer:FlxGraphic = FlxGraphic.fromClass(GraphicCursorCross);
		cameraFollowPointer = new FlxSprite().loadGraphic(pointer);
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();
		cameraFollowPointer.color = FlxColor.WHITE;
		add(cameraFollowPointer);

		changeBGbutton = new FlxButton(FlxG.width - 360, 25, "", function()
		{
			onPixelBG = !onPixelBG;
			reloadBGs();
		});
		changeBGbutton.cameras = [camMenu];

		loadChar(!daAnim.startsWith('bf'), false);

		healthBarBG = new FlxSprite(30, FlxG.height - 75).loadGraphic(Paths.image('uiskins/default/base/healthBar'));
		healthBarBG.scrollFactor.set();
		add(healthBarBG);
		healthBarBG.cameras = [camHUD];

		leHealthIcon = new HealthIcon(char.healthIcon, false);
		leHealthIcon.y = FlxG.height - 150;
		add(leHealthIcon);
		leHealthIcon.cameras = [camHUD];

		dumbTexts = new FlxTypedGroup<FlxText>();
		add(dumbTexts);
		dumbTexts.cameras = [camHUD];

		textAnim = new FlxText(300, 16);
		textAnim.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		textAnim.borderSize = 1;
		textAnim.size = 32;
		textAnim.scrollFactor.set();
		textAnim.cameras = [camHUD];
		add(textAnim);

		genBoyOffsets();

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);

		var tipTextArray:Array<String> = "E/Q - Camera Zoom In/Out
		\nR - Reset Camera Zoom & Position
		\nJKLI - Move Camera
		\nW/S - Previous/Next Animation
		\nSpace - Play Animation
		\nArrow Keys - Move Character Offset
		\nT - Reset Current Offset
		\nH - Toggle Guide Character
		\nHold Shift to Move 10x faster\n".split('\n');

		for (i in 0...tipTextArray.length-1)
		{
			var tipText:FlxText = new FlxText(FlxG.width - 320, FlxG.height - 15 - 16 * (tipTextArray.length - i), 300, tipTextArray[i], 12);
			tipText.cameras = [camHUD];
			tipText.setFormat(null, 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
			tipText.scrollFactor.set();
			tipText.borderSize = 1;
			add(tipText);
		}

		FlxG.camera.follow(camFollow);

		var tabs = [
			{name: 'Settings', label: 'Settings'}
		];

		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.cameras = [camMenu];

		UI_box.resize(250, 120);
		UI_box.x = FlxG.width - 275;
		UI_box.y = 25;
		UI_box.scrollFactor.set();

		var tabs = [
			{name: 'Character', label: 'Character'},
			{name: 'Animations', label: 'Animations'},
		];
		UI_characterbox = new FlxUITabMenu(null, tabs, true);
		UI_characterbox.cameras = [camMenu];

		UI_characterbox.resize(350, 250);
		UI_characterbox.x = UI_box.x - 100;
		UI_characterbox.y = UI_box.y + UI_box.height;
		UI_characterbox.scrollFactor.set();
		add(UI_characterbox);
		add(UI_box);
		add(changeBGbutton);

		addSettingsUI();

		addCharacterUI();
		addAnimationsUI();
		UI_characterbox.selected_tab_id = 'Character';

		FlxG.mouse.visible = true;
		reloadCharacterOptions();
		reloadGuideChar();
	}

	var onPixelBG:Bool = false;
	var OFFSET_X:Float = 300;
	function reloadBGs() {
		var i:Int = bgLayer.members.length-1;
		while(i >= 0) {
			var memb:FlxSprite = bgLayer.members[i];
			if (memb != null) {
				memb.kill();
				bgLayer.remove(memb);
				memb.destroy();
			}
			--i;
		}
		bgLayer.clear();
		var playerXDifference = 0;
		if (char.flipped) playerXDifference = 670;

		if (onPixelBG) {
			if (char.flipped) {
				playerXDifference += 200;
			}

			var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0 + OFFSET_X, -100, 0.1, 0.1);
			bgLayer.add(bgSky);
			bgSky.antialiasing = false;

			var repositionShit = -200 + OFFSET_X - playerXDifference;

			var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, -94, 0.6, 0.90);
			bgLayer.add(bgSchool);
			bgSchool.antialiasing = false;

			var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, -100, 0.95, 0.95);
			bgLayer.add(bgStreet);
			bgStreet.antialiasing = false;

			var widShit = Std.int(bgSky.width * 6);
			var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -900);
			bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
			bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
			bgTrees.animation.play('treeLoop');
			bgTrees.scrollFactor.set(0.85, 0.85);
			bgLayer.add(bgTrees);
			bgTrees.antialiasing = false;

			bgSky.setGraphicSize(widShit);
			bgSchool.setGraphicSize(widShit);
			bgStreet.setGraphicSize(widShit);
			bgTrees.setGraphicSize(Std.int(widShit * 1.4));

			bgSky.updateHitbox();
			bgSchool.updateHitbox();
			bgStreet.updateHitbox();
			bgTrees.updateHitbox();
			changeBGbutton.text = "Regular BG";
		} else {
			var bg:BGSprite = new BGSprite('stageback', -600 + OFFSET_X - playerXDifference, -300, 0.9, 0.9);
			bgLayer.add(bg);

			var stageFront:BGSprite = new BGSprite('stagefront', -650 + OFFSET_X - playerXDifference, 500, 0.9, 0.9);
			stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
			stageFront.updateHitbox();
			bgLayer.add(stageFront);
			changeBGbutton.text = "Pixel BG";
		}
	}

	var TemplateCharacter:String = '{
			"animations": [
				{
					"loop": false,
					"playerOffsets": [
						0,
						0
					],
					"enemyOffsets": [
						0,
						0
					],
					"fps": 24,
					"anim": "idle",
					"indices": [],
					"name": "Dad idle dance"
				},
				{
					"playerOffsets": [
						0,
						0
					],
					"enemyOffsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singLEFT",
					"loop": false,
					"name": "Dad Sing Note LEFT"
				},
				{
					"playerOffsets": [
						0,
						0
					],
					"enemyOffsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singDOWN",
					"loop": false,
					"name": "Dad Sing Note DOWN"
				},
				{
					"playerOffsets": [
						0,
						0
					],
					"enemyOffsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singUP",
					"loop": false,
					"name": "Dad Sing Note UP"
				},
				{
					"playerOffsets": [
						0,
						0
					],
					"enemyOffsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singRIGHT",
					"loop": false,
					"name": "Dad Sing Note RIGHT"
				}
			],
			"no_antialiasing": false,
			"image": "characters/DADDY_DEAREST",
			"position": [
				0,
				0
			],
			"healthicon": "face",
			"flip_x": false,
			"healthbar_colors": [
				161,
				161,
				161
			],
			"camera_position": [
				0,
				0
			],
			"sing_duration": 6.1,
			"scale": 1,
			"repeatHoldAnimation": true
		}';

	var charDropDown:FlxUIDropDownMenu;
	var check_player:FlxUICheckBox;
	function addSettingsUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Settings";

		check_player = new FlxUICheckBox(10, 60, null, null, "Playable Character", 100);
		check_player.checked = true;
		check_player.callback = function()
		{
			char.flipped = !char.flipped;
			char.flipX = !char.flipX;
			updatePointerPos();
			reloadGuideChar();
			reloadBGs();
			ghostChar.flipped = char.flipped;
			ghostChar.flipX = char.flipX;
		};

		charDropDown = new FlxUIDropDownMenu(10, 30, FlxUIDropDownMenu.makeStrIdLabelArray([''], true), function(character:String)
		{
			daAnim = characterList[Std.parseInt(character)];
			loadChar(!check_player.checked);
			updatePresence();
			reloadCharacterDropDown();
		});
		charDropDown.selectedLabel = daAnim;
		reloadCharacterDropDown();

		var reloadCharacter:FlxButton = new FlxButton(140, 20, "Reload Char", function()
		{
			loadChar(!check_player.checked);
			reloadCharacterDropDown();
		});

		var templateCharacter:FlxButton = new FlxButton(140, 50, "Load Template", function()
		{
			curAnim = 0;
			var parsedJson:CharacterFile = cast Json.parse(TemplateCharacter);
			var characters:Array<Character> = [char, ghostChar];
			for (character in characters)
			{
				character.animOffsets.clear();
				character.animationsArray = parsedJson.animations;
				for (anim in character.animationsArray)
				{
					character.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
				}

				character.singDuration = parsedJson.sing_duration;
				character.playerPosition = parsedJson.position;
				character.enemyPosition = parsedJson.position;
				character.playerCameraPosition = parsedJson.camera_position;
				character.enemyCameraPosition = parsedJson.camera_position;
				
				character.imageFile = parsedJson.image;
				character.jsonScale = parsedJson.scale;
				character.noAntialiasing = parsedJson.no_antialiasing;
				character.originalFlipX = parsedJson.flip_x;
				character.flipX = character.originalFlipX;
				if (character.flipped) character.flipX = !character.flipX;
				character.healthIcon = parsedJson.healthicon;
				character.healthColorArray = parsedJson.healthbar_colors;
				character.setPosition(OFFSET_X + 100 + char.positionArray[0], character.positionArray[1]);
				character.setGraphicSize(Std.int(character.frameWidth * character.jsonScale));
				character.updateHitbox();
				character.setOffsets();
			}

			reloadCharacterOptions();
			reloadCharacterImage();
			reloadCharacterDropDown();
			resetHealthBarColor();
			genBoyOffsets();
		});
		templateCharacter.color = FlxColor.RED;
		templateCharacter.label.color = FlxColor.WHITE;
		
		tab_group.add(new FlxText(charDropDown.x, charDropDown.y - 18, 0, 'Character:'));
		tab_group.add(check_player);
		tab_group.add(reloadCharacter);
		tab_group.add(charDropDown);
		tab_group.add(reloadCharacter);
		tab_group.add(templateCharacter);
		UI_box.addGroup(tab_group);
	}
	
	var imageInputText:FlxUIInputText;
	var healthIconInputText:FlxUIInputText;

	var singDurationStepper:FlxUINumericStepper;
	var scaleStepper:FlxUINumericStepper;
	var positionXStepper:FlxUINumericStepper;
	var positionYStepper:FlxUINumericStepper;
	var positionCameraXStepper:FlxUINumericStepper;
	var positionCameraYStepper:FlxUINumericStepper;

	var flipXCheckBox:FlxUICheckBox;
	var noAntialiasingCheckBox:FlxUICheckBox;
	var repeatHoldAnimationCheckBox:FlxUICheckBox;

	var healthColorStepperR:FlxUINumericStepper;
	var healthColorStepperG:FlxUINumericStepper;
	var healthColorStepperB:FlxUINumericStepper;

	function addCharacterUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Character";

		imageInputText = new FlxUIInputText(15, 30, 200, 'characters/BOYFRIEND', 8);
		var reloadImage:FlxButton = new FlxButton(imageInputText.x + 210, imageInputText.y - 3, "Reload Image", function()
		{
			char.imageFile = imageInputText.text;
			reloadCharacterImage();
		});

		var decideIconColor:FlxButton = new FlxButton(reloadImage.x, reloadImage.y + 30, "Get Icon Color", function()
			{
				var coolColor = FlxColor.fromInt(CoolUtil.dominantColor(leHealthIcon));
				healthColorStepperR.value = coolColor.red;
				healthColorStepperG.value = coolColor.green;
				healthColorStepperB.value = coolColor.blue;
				getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperR, null);
				getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperG, null);
				getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperB, null); 
			});

		healthIconInputText = new FlxUIInputText(15, imageInputText.y + 35, 75, leHealthIcon.char, 8);

		singDurationStepper = new FlxUINumericStepper(15, healthIconInputText.y + 45, 0.1, 4, 0, 999, 1);

		scaleStepper = new FlxUINumericStepper(15, singDurationStepper.y + 40, 0.1, 1, 0.05, 20, 1);

		flipXCheckBox = new FlxUICheckBox(singDurationStepper.x + 80, singDurationStepper.y, null, null, "Flip X", 50);
		flipXCheckBox.checked = char.flipX;
		flipXCheckBox.callback = function() {
			char.originalFlipX = !char.originalFlipX;
			char.flipX = !char.flipX;
			
			ghostChar.flipX = char.flipX;
		};

		noAntialiasingCheckBox = new FlxUICheckBox(flipXCheckBox.x, flipXCheckBox.y + 20, null, null, "No Antialiasing", 80);
		noAntialiasingCheckBox.checked = char.noAntialiasing;
		noAntialiasingCheckBox.callback = function() {
			char.antialiasing = false;
			if (!noAntialiasingCheckBox.checked && ClientPrefs.globalAntialiasing) {
				char.antialiasing = true;
			}
			char.noAntialiasing = noAntialiasingCheckBox.checked;
			ghostChar.antialiasing = char.antialiasing;
		};

		repeatHoldAnimationCheckBox = new FlxUICheckBox(noAntialiasingCheckBox.x, noAntialiasingCheckBox.y + 20, null, null, "Repeat Animation on Hold Notes", 80);
		repeatHoldAnimationCheckBox.checked = char.repeatHoldAnimation;
		repeatHoldAnimationCheckBox.callback = function() {
			char.repeatHoldAnimation = repeatHoldAnimationCheckBox.checked;
			ghostChar.repeatHoldAnimation = char.repeatHoldAnimation;
		};

		positionXStepper = new FlxUINumericStepper(flipXCheckBox.x + 110, flipXCheckBox.y, 10, char.positionArray[0], -9000, 9000, 3);
		positionYStepper = new FlxUINumericStepper(positionXStepper.x + 60, positionXStepper.y, 10, char.positionArray[1], -9000, 9000, 3);
		
		positionCameraXStepper = new FlxUINumericStepper(positionXStepper.x, positionXStepper.y + 40, 10, char.cameraPosition[0], -9000, 9000, 3);
		positionCameraYStepper = new FlxUINumericStepper(positionYStepper.x, positionYStepper.y + 40, 10, char.cameraPosition[1], -9000, 9000, 3);

		var saveCharacterButton:FlxButton = new FlxButton(reloadImage.x, noAntialiasingCheckBox.y + 40, "Save Character", function() {
			saveCharacter();
		});

		healthColorStepperR = new FlxUINumericStepper(singDurationStepper.x, saveCharacterButton.y, 20, char.healthColorArray[0], 0, 255, 0);
		healthColorStepperG = new FlxUINumericStepper(singDurationStepper.x + 65, saveCharacterButton.y, 20, char.healthColorArray[1], 0, 255, 0);
		healthColorStepperB = new FlxUINumericStepper(singDurationStepper.x + 130, saveCharacterButton.y, 20, char.healthColorArray[2], 0, 255, 0);

		tab_group.add(new FlxText(15, imageInputText.y - 18, 0, 'Image file name:'));
		tab_group.add(new FlxText(15, healthIconInputText.y - 18, 0, 'Health icon name:'));
		tab_group.add(new FlxText(15, singDurationStepper.y - 18, 0, 'Sing Animation length:'));
		tab_group.add(new FlxText(15, scaleStepper.y - 18, 0, 'Scale:'));
		tab_group.add(new FlxText(positionXStepper.x, positionXStepper.y - 18, 0, 'Character X/Y:'));
		tab_group.add(new FlxText(positionCameraXStepper.x, positionCameraXStepper.y - 18, 0, 'Camera X/Y:'));
		tab_group.add(new FlxText(healthColorStepperR.x, healthColorStepperR.y + 18, 0, 'Health bar R/G/B:'));
		tab_group.add(imageInputText);
		tab_group.add(reloadImage);
		tab_group.add(decideIconColor);
		tab_group.add(healthIconInputText);
		tab_group.add(singDurationStepper);
		tab_group.add(scaleStepper);
		tab_group.add(flipXCheckBox);
		tab_group.add(noAntialiasingCheckBox);
		tab_group.add(repeatHoldAnimationCheckBox);
		tab_group.add(positionXStepper);
		tab_group.add(positionYStepper);
		tab_group.add(positionCameraXStepper);
		tab_group.add(positionCameraYStepper);
		tab_group.add(healthColorStepperR);
		tab_group.add(healthColorStepperG);
		tab_group.add(healthColorStepperB);
		tab_group.add(saveCharacterButton);
		UI_characterbox.addGroup(tab_group);
	}

	var ghostDropDown:FlxUIDropDownMenu;
	var animationDropDown:FlxUIDropDownMenu;
	var animationInputText:FlxUIInputText;
	var animationNameInputText:FlxUIInputText;
	var animationIndicesInputText:FlxUIInputText;
	var animationNameFramerate:FlxUINumericStepper;
	var animationLoopCheckBox:FlxUICheckBox;
	function addAnimationsUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Animations";
		
		animationInputText = new FlxUIInputText(15, 85, 80, '', 8);
		animationNameInputText = new FlxUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		animationIndicesInputText = new FlxUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
		animationNameFramerate = new FlxUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
		animationLoopCheckBox = new FlxUICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, null, null, "Should it Loop?", 100);

		animationDropDown = new FlxUIDropDownMenu(15, animationInputText.y - 55, FlxUIDropDownMenu.makeStrIdLabelArray([''], true), function(pressed:String) {
			var selectedAnimation:Int = Std.parseInt(pressed);
			var anim:AnimArray = char.animationsArray[selectedAnimation];
			animationInputText.text = anim.anim;
			animationNameInputText.text = anim.name;
			animationLoopCheckBox.checked = anim.loop;
			animationNameFramerate.value = anim.fps;

			var indicesStr:String = '';
			if (anim.indices != null)
				indicesStr = anim.indices.toString();
			animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
		});

		ghostDropDown = new FlxUIDropDownMenu(animationDropDown.x + 150, animationDropDown.y, FlxUIDropDownMenu.makeStrIdLabelArray([''], true), function(pressed:String) {
			var selectedAnimation:Int = Std.parseInt(pressed);
			ghostChar.visible = false;
			char.alpha = 1;
			if (selectedAnimation > 0 && ghostChar.animation.exists(char.animationsArray[selectedAnimation - 1].anim)) {
				ghostChar.visible = true;
				ghostChar.playAnim(char.animationsArray[selectedAnimation - 1].anim, true);
				char.alpha = 0.85;
			}
		});

		var addUpdateButton:FlxButton = new FlxButton(70, animationIndicesInputText.y + 30, "Add/Update", function() {
			var indices:Array<Int> = [];
			var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');
			if (indicesStr.length > 1) {
				for (i in 0...indicesStr.length) {
					var index:Int = Std.parseInt(indicesStr[i]);
					if (indicesStr[i] != null && indicesStr[i] != '' && !Math.isNaN(index) && index > -1) {
						indices.push(index);
					}
				}
			}

			var lastAnim:String = '';
			if (char.animationsArray[curAnim] != null) {
				lastAnim = char.animationsArray[curAnim].anim;
			}

			var lastOffsets:Array<Float> = [0, 0];
			for (anim in char.animationsArray) {
				if (animationInputText.text == anim.anim) {
					lastOffsets = anim.offsets;
					if (char.animation.exists(animationInputText.text))
						char.animation.remove(animationInputText.text);
					char.animationsArray.remove(anim);
				}
			}

			var newAnim:AnimArray = {
				anim: animationInputText.text,
				name: animationNameInputText.text,
				fps: Math.round(animationNameFramerate.value),
				loop: animationLoopCheckBox.checked,
				indices: indices,
				offsets: lastOffsets
			};
			if (indices != null && indices.length > 0) {
				char.animation.addByIndices(newAnim.anim, newAnim.name, newAnim.indices, "", newAnim.fps, newAnim.loop);
			} else {
				char.animation.addByPrefix(newAnim.anim, newAnim.name, newAnim.fps, newAnim.loop);
			}
			
			if (!char.animOffsets.exists(newAnim.anim)) {
				char.addOffset(newAnim.anim, 0, 0);
			}
			char.animationsArray.push(newAnim);

			for(i in 0...char.animationsArray.length) {
				if (char.animationsArray[i] != null && char.animationsArray[i].anim == animationInputText.text) {
					var leAnim = char.animation.getByName(char.animationsArray[i].anim);
					if (leAnim != null && leAnim.frames.length > 0) {
						char.playAnim(char.animationsArray[i].anim, true);
						curAnim = i;
						break;
					}
				}
			}

			reloadAnimationDropDown();
			genBoyOffsets();
			trace('Added/Updated animation: ${animationInputText.text}');
		});

		var removeButton:FlxButton = new FlxButton(180, animationIndicesInputText.y + 30, "Remove", function() {
			for (anim in char.animationsArray) {
				if (animationInputText.text == anim.anim) {
					var resetAnim:Bool = false;
					if (char.animation.curAnim != null && anim.anim == char.animation.curAnim.name) resetAnim = true;

					if (char.animation.exists(anim.anim)) {
						char.animation.remove(anim.anim);
					}
					if (char.animOffsets.exists(anim.anim)) {
						char.animOffsets.remove(anim.anim);
					}
					char.animationsArray.remove(anim);

					if (resetAnim && char.animationsArray.length > 0 && char.animation.exists(char.animationsArray[0].anim)) {
						curAnim = 0;
						char.playAnim(char.animationsArray[curAnim].anim, true);
					}
					reloadAnimationDropDown();
					genBoyOffsets();
					trace('Removed animation: ${animationInputText.text}');
					break;
				}
			}
		});

		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 0, 'Animations:'));
		tab_group.add(new FlxText(ghostDropDown.x, ghostDropDown.y - 18, 0, 'Animation Ghost:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 0, 'Animation name:'));
		tab_group.add(new FlxText(animationNameFramerate.x, animationNameFramerate.y - 18, 0, 'Framerate:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 0, 'Animation on .XML/.TXT file:'));
		tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 0, 'ADVANCED - Animation Indices:'));

		tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationNameFramerate);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(ghostDropDown);
		tab_group.add(animationDropDown);
		UI_characterbox.addGroup(tab_group);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)) {
			if (sender == healthIconInputText) {
				leHealthIcon.changeIcon(healthIconInputText.text);
				char.healthIcon = healthIconInputText.text;
				updatePresence();
			}
			else if (sender == imageInputText) {
				char.imageFile = imageInputText.text;
			}
		} else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {
			if (sender == scaleStepper)
			{
				char.jsonScale = sender.value;
				ghostChar.jsonScale = sender.value;
				reloadCharacterImage();
			}
			else if (sender == positionXStepper)
			{
				char.playerPosition[0] = positionXStepper.value;
				char.enemyPosition[0] = positionXStepper.value;
				char.x = OFFSET_X + 100 + char.positionArray[0];
				updatePointerPos();
			}
			else if (sender == positionYStepper)
			{
				char.playerPosition[1] = positionYStepper.value;
				char.enemyPosition[1] = positionYStepper.value;
				char.y = char.positionArray[1];
				updatePointerPos();
			}
			else if (sender == positionCameraXStepper)
			{
				char.playerCameraPosition[0] = positionCameraXStepper.value;
				char.enemyCameraPosition[0] = positionCameraXStepper.value;
				updatePointerPos();
			}
			else if (sender == positionCameraYStepper)
			{
				char.playerCameraPosition[1] = positionCameraYStepper.value;
				char.enemyCameraPosition[1] = positionCameraYStepper.value;
				updatePointerPos();
			}
			else if (sender == singDurationStepper)
			{
				char.singDuration = singDurationStepper.value;//ermm you forgot this??
			}
			else if (sender == healthColorStepperR)
			{
				char.healthColorArray[0] = Math.round(healthColorStepperR.value);
				healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
			}
			else if (sender == healthColorStepperG)
			{
				char.healthColorArray[1] = Math.round(healthColorStepperG.value);
				healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
			}
			else if (sender == healthColorStepperB)
			{
				char.healthColorArray[2] = Math.round(healthColorStepperB.value);
				healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
			}
		}
	}

	function reloadCharacterImage() {
		var lastAnim:String = '';
		if (char.animation.curAnim != null)
			lastAnim = char.animation.curAnim.name;

		if (Paths.existsPath('images/${char.imageFile}/Animation.json', TEXT))
			char.frames = AtlasFrameMaker.construct(char.imageFile);
		else if (Paths.existsPath('images/${char.imageFile}.txt', TEXT))
			char.frames = Paths.getPackerAtlas(char.imageFile);
		else if (Paths.existsPath('images/${char.imageFile}.json', TEXT))
			char.frames = Paths.getTexturePackerAtlas(char.imageFile);
		else
			char.frames = Paths.getSparrowAtlas(char.imageFile);

		if (char.animationsArray != null && char.animationsArray.length > 0) {
			for (anim in char.animationsArray) {
				var animAnim:String = '${anim.anim}';
				var animName:String = '${anim.name}';
				var animFps:Int = anim.fps;
				var animLoop:Bool = !!anim.loop; //Bruh
				var animIndices:Array<Int> = anim.indices;
				if (animIndices != null && animIndices.length > 0)
					char.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
				else
					char.animation.addByPrefix(animAnim, animName, animFps, animLoop);
			}
		} else
			char.quickAnimAdd('idle', 'BF idle dance');
		char.dance();

		ghostDropDown.selectedLabel = '';
		reloadGhost();
		updateScale();
		
		if (lastAnim != '' && char.animation.exists(lastAnim))
			char.playAnim(lastAnim, true);
	}

	function updateScale() {
		char.scale.set(char.jsonScale, char.jsonScale);
		char.updateHitbox();
		char.setOffsets();
		ghostChar.scale.set(ghostChar.jsonScale, ghostChar.jsonScale);
		ghostChar.updateHitbox();
		ghostChar.setOffsets();
		updatePointerPos();
	}

	function genBoyOffsets():Void
	{
		var daLoop:Int = 0;

		var i:Int = dumbTexts.members.length-1;
		while(i >= 0) {
			var memb:FlxText = dumbTexts.members[i];
			if (memb != null) {
				memb.kill();
				dumbTexts.remove(memb);
				memb.destroy();
			}
			--i;
		}
		dumbTexts.clear();

		for (anim => offsets in char.animOffsets)
		{
			var text:FlxText = new FlxText(10, 20 + (18 * daLoop), 0, '$anim: $offsets', 15);
			text.setFormat(null, 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.scrollFactor.set();
			text.borderSize = 1;
			dumbTexts.add(text);
			text.cameras = [camHUD];

			daLoop++;
		}

		textAnim.visible = true;
		if (dumbTexts.length < 1) {
			var text:FlxText = new FlxText(10, 38, 0, "ERROR! No animations found.", 15);
			text.scrollFactor.set();
			text.borderSize = 1;
			dumbTexts.add(text);
			textAnim.visible = false;
		}
	}

	function loadChar(isDad:Bool, blahBlahBlah:Bool = true) {
		var i:Int = charLayer.members.length - 1;
		while(i >= 0) {
			var memb:Character = charLayer.members[i];
			if (memb != null) {
				memb.kill();
				charLayer.remove(memb);
				memb.destroy();
			}
			--i;
		}
		charLayer.clear();

		ghostChar = new Character(0, 0, daAnim, !isDad, true);
		ghostChar.alpha = 0.6;

		char = new Character(0, 0, daAnim, !isDad, true);
		char.setPosition(OFFSET_X + 100 + char.positionArray[0], char.positionArray[1]);
		updateScale();

		reloadGuideChar();

		charLayer.add(ghostChar);
		charLayer.add(char);

		for (i in 0...char.animationsArray.length) {
			var anim = char.animationsArray[i];
			if (anim.anim == char.animation.name)
				curAnim = i;
		}

		if (blahBlahBlah)
			genBoyOffsets();
		reloadCharacterOptions();
		reloadBGs();
	}

	var curGuideChar:Int = 0;
	function reloadGuideChar() {
		var daChar:String = 'BF';
		switch (curGuideChar) {
			case 2:
				daChar = 'Dad';
			case 3:
				daChar = 'GF';
		}
		guideChar.loadGraphic(Paths.image('guide$daChar'));
		guideChar.flipX = char.flipped;
		guideChar.alpha = 0.3;
		guideChar.x = OFFSET_X + 100;
		guideChar.visible = curGuideChar > 0;
		guideChar.color = FlxColor.RED;
	}

	function updatePointerPos() {
		var x:Float = CoolUtil.getCamFollowCharacter(char).x;
		var y:Float = CoolUtil.getCamFollowCharacter(char).y;
		x += char.cameraPosition[0];
		y += char.cameraPosition[1];

		x -= cameraFollowPointer.width / 2;
		y -= cameraFollowPointer.height / 2;
		cameraFollowPointer.setPosition(x, y);
	}

	function findAnimationByName(name:String):AnimArray {
		for (anim in char.animationsArray) {
			if (anim.anim == name) {
				return anim;
			}
		}
		return null;
	}

	function reloadCharacterOptions() {
		if (UI_characterbox != null) {
			imageInputText.text = char.imageFile;
			healthIconInputText.text = char.healthIcon;
			singDurationStepper.value = char.singDuration;
			scaleStepper.value = char.jsonScale;
			flipXCheckBox.checked = char.originalFlipX;
			noAntialiasingCheckBox.checked = char.noAntialiasing;
			repeatHoldAnimationCheckBox.checked = char.repeatHoldAnimation;
			resetHealthBarColor();
			leHealthIcon.changeIcon(healthIconInputText.text);
			positionXStepper.value = char.positionArray[0];
			positionYStepper.value = char.positionArray[1];
			positionCameraXStepper.value = char.cameraPosition[0];
			positionCameraYStepper.value = char.cameraPosition[1];
			reloadAnimationDropDown();
			updatePresence();
		}
	}

	function reloadAnimationDropDown() {
		var anims:Array<String> = [];
		var ghostAnims:Array<String> = [''];
		for (anim in char.animationsArray) {
			anims.push(anim.anim);
			ghostAnims.push(anim.anim);
		}
		if (anims.length < 1) anims.push('NO ANIMATIONS'); //Prevents crash

		var lastSelected = animationDropDown.selectedLabel;
		var lastSelectedGhost = ghostDropDown.selectedLabel;
		animationDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(anims, true));
		ghostDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(ghostAnims, true));
		animationDropDown.selectedLabel = lastSelected;
		ghostDropDown.selectedLabel = lastSelectedGhost;
		reloadGhost();
	}

	function reloadGhost() {
		var lastAnim = ghostChar.animation.name;
		ghostChar.frames = char.frames;
		for (anim in char.animationsArray) {
			var animAnim:String = '${anim.anim}';
			var animName:String = '${anim.name}';
			var animFps:Int = anim.fps;
			var animLoop:Bool = !!anim.loop; //Bruh
			var animIndices:Array<Int> = anim.indices;
			if (animIndices != null && animIndices.length > 0) {
				ghostChar.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
			} else {
				ghostChar.animation.addByPrefix(animAnim, animName, animFps, animLoop);
			}

			ghostChar.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
		}

		char.alpha = 0.85;
		ghostChar.dance();
		if (ghostDropDown.selectedLabel.length > 0 && ghostChar.animation.exists(lastAnim))
			ghostChar.playAnim(lastAnim, true);
		ghostChar.visible = true;
		if (ghostDropDown.selectedLabel == '') {
			ghostChar.visible = false;
			char.alpha = 1;
		}
		ghostChar.color = 0xFF666688;
		ghostChar.antialiasing = char.antialiasing;
	}

	function reloadCharacterDropDown() {
		var charsLoaded:Map<String, Bool> = new Map();

		#if sys
		characterList = [];
		var directories:Array<String> = [Paths.getPreloadPath('characters/')];
		#if MODS_ALLOWED
		directories.push(Paths.mods('characters/'));
		#end
		for (i in 0...directories.length) {
			var directory:String = directories[i];
			if (FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json')) {
						var charToCheck:String = file.substr(0, file.length - 5);
						if (!charsLoaded.exists(charToCheck)) {
							var fileCheck = Character.getFile(charToCheck);
							if (fileCheck.characters == null) { //don't add group characters
								characterList.push(charToCheck);
								charsLoaded.set(charToCheck, true);
							}
						}
					}
				}
			}
		}
		#else
		characterList = CoolUtil.coolTextFile(Paths.txt('characterList'));
		#end

		charDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(characterList, true));
		charDropDown.selectedLabel = daAnim;
	}

	function resetHealthBarColor() {
		healthColorStepperR.value = char.healthColorArray[0];
		healthColorStepperG.value = char.healthColorArray[1];
		healthColorStepperB.value = char.healthColorArray[2];
		healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
	}

	function updatePresence() {
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Character Editor", 'Character: $daAnim', leHealthIcon.char);
		#end
	}

	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (char.animationsArray[curAnim] != null) {
			textAnim.text = char.animationsArray[curAnim].anim;

			var curAnim:FlxAnimation = char.animation.getByName(char.animationsArray[curAnim].anim);
			if (curAnim == null || curAnim.frames.length < 1) {
				textAnim.text += ' (ERROR!)';
			}
		} else {
			textAnim.text = '';
		}

		var inputTexts:Array<FlxUIInputText> = [animationInputText, imageInputText, healthIconInputText, animationNameInputText, animationIndicesInputText];
		for (i in 0...inputTexts.length) {
			if (inputTexts[i].hasFocus) {
				if (FlxG.keys.justPressed.ENTER) {
					inputTexts[i].hasFocus = false;
				}
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				super.update(elapsed);
				return;
			}
		}
		inputTexts = [];
		var steppers:Array<FlxUINumericStepper> = [singDurationStepper, scaleStepper, positionXStepper, positionYStepper, positionCameraXStepper, positionCameraYStepper, healthColorStepperR, healthColorStepperG, healthColorStepperB, animationNameFramerate];
		for (stepper in steppers) {
			@:privateAccess
			var leText:Dynamic = stepper.text_field;
			var leText:FlxUIInputText = leText;
			if (leText.hasFocus) {
				if (FlxG.keys.justPressed.ENTER) {
					leText.hasFocus = false;
					leText.focusLost();
				}
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				super.update(elapsed);
				return;
			}
		}
		FlxG.sound.muteKeys = TitleState.muteKeys;
		FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;

		FlxG.mouse.visible = true;//cause reasons. trust me 

		if (!charDropDown.dropPanel.visible) {
			if (FlxG.keys.justPressed.ESCAPE) {
				if (goToPlayState) {
					MusicBeatState.switchState(new PlayState());
				} else {
					MusicBeatState.switchState(new editors.MasterEditorMenu());
					CoolUtil.playMenuMusic();
				}
				FlxG.mouse.visible = false;
				return;
			}
			
			if (FlxG.keys.justPressed.R) {
				FlxG.camera.zoom = 1;
				camFollow.setPosition(cameraFollowPointer.x + cameraFollowPointer.width / 2, cameraFollowPointer.y + cameraFollowPointer.height / 2);
			}

			if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3) {
				FlxG.camera.zoom += elapsed * FlxG.camera.zoom;
				if (FlxG.camera.zoom > 3) FlxG.camera.zoom = 3;
			}
			if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1) {
				FlxG.camera.zoom -= elapsed * FlxG.camera.zoom;
				if (FlxG.camera.zoom < 0.1) FlxG.camera.zoom = 0.1;
			}

			if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
			{
				var addToCam:Float = 500 * elapsed;
				if (FlxG.keys.pressed.SHIFT)
					addToCam *= 4;

				if (FlxG.keys.pressed.I)
					camFollow.y -= addToCam;
				else if (FlxG.keys.pressed.K)
					camFollow.y += addToCam;

				if (FlxG.keys.pressed.J)
					camFollow.x -= addToCam;
				else if (FlxG.keys.pressed.L)
					camFollow.x += addToCam;
			}

			if (char.animationsArray.length > 0) {
				if (FlxG.keys.justPressed.W)
				{
					curAnim -= 1;
				}

				if (FlxG.keys.justPressed.S)
				{
					curAnim += 1;
				}

				if (curAnim < 0)
					curAnim = char.animationsArray.length - 1;

				if (curAnim >= char.animationsArray.length)
					curAnim = 0;

				if ((FlxG.keys.justPressed.S || FlxG.keys.justPressed.W || FlxG.keys.justPressed.SPACE) && char.animation.exists(char.animationsArray[curAnim].anim))
				{
					char.playAnim(char.animationsArray[curAnim].anim, true);
					genBoyOffsets();
				}

				if (FlxG.keys.justPressed.T)
				{
					char.animationsArray[curAnim].offsets = [0, 0];
					char.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0], char.animationsArray[curAnim].offsets[1]);
					ghostChar.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0], char.animationsArray[curAnim].offsets[1]);

					char.setOffsets();
					if (ghostChar.animation.curAnim != null && char.animation.curAnim != null && char.animation.curAnim.name == ghostChar.animation.curAnim.name) {
						ghostChar.setOffsets();
					}
					genBoyOffsets();
				}

				if (FlxG.keys.justPressed.H)
				{
					curGuideChar++;
					if (curGuideChar > 3) curGuideChar = 0;
					reloadGuideChar();
				}

				var controlArray:Array<Bool> = [FlxG.keys.justPressed.LEFT, FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.UP, FlxG.keys.justPressed.DOWN];
				
				for (i in 0...controlArray.length) {
					if (controlArray[i]) {
						var holdShift = FlxG.keys.pressed.SHIFT;
						var multiplier = 1;
						if (holdShift)
							multiplier = 10;

						var arrayVal = 0;
						if (i > 1) arrayVal = 1;

						var negaMult:Int = 1;
						if (i % 2 == 1) negaMult = -1;
						char.animationsArray[curAnim].offsets[arrayVal] += negaMult * multiplier;
						char.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0], char.animationsArray[curAnim].offsets[1]);
						ghostChar.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0], char.animationsArray[curAnim].offsets[1]);
						
						char.setOffsets();
						if (ghostChar.animation.curAnim != null && char.animation.curAnim != null && char.animation.curAnim.name == ghostChar.animation.curAnim.name) {
							ghostChar.setOffsets();
						}
						genBoyOffsets();
						holdTime = 0;
					}
				}

				controlArray = [FlxG.keys.pressed.LEFT, FlxG.keys.pressed.RIGHT, FlxG.keys.pressed.UP, FlxG.keys.pressed.DOWN];
				
				if (controlArray.contains(true)) {
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 40);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 40);
					
					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0) {
						for (i in 0...controlArray.length) {
							if (controlArray[i]) {
								var holdShift = FlxG.keys.pressed.SHIFT;
								var multiplier = 1;
								if (holdShift)
									multiplier = 10;
		
								var arrayVal = 0;
								if (i > 1) arrayVal = 1;
		
								var negaMult:Int = 1;
								if (i % 2 == 1) negaMult = -1;
								char.animationsArray[curAnim].offsets[arrayVal] += negaMult * multiplier;
								char.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0], char.animationsArray[curAnim].offsets[1]);
								ghostChar.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0], char.animationsArray[curAnim].offsets[1]);
								
								char.setOffsets();
								if (ghostChar.animation.curAnim != null && char.animation.curAnim != null && char.animation.curAnim.name == ghostChar.animation.curAnim.name) {
									ghostChar.setOffsets();
								}
								genBoyOffsets();
							}
						}
					}
				}
			}
		}
		ghostChar.setPosition(char.x, char.y);
		super.update(elapsed);
	}

	var _file:FileReference;

	function onSaveComplete(_):Void
	{
		if (_file != null) {
			_file.removeEventListener(Event.COMPLETE, onSaveComplete);
			_file.removeEventListener(Event.CANCEL, onSaveCancel);
			_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file = null;
			FlxG.log.notice("Successfully saved file.");
		}
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onSaveCancel(_):Void
	{
		if (_file != null) {
			_file.removeEventListener(Event.COMPLETE, onSaveComplete);
			_file.removeEventListener(Event.CANCEL, onSaveCancel);
			_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file = null;
		}
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onSaveError(_):Void
	{
		if (_file != null) {
			_file.removeEventListener(Event.COMPLETE, onSaveComplete);
			_file.removeEventListener(Event.CANCEL, onSaveCancel);
			_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file = null;
			FlxG.log.error("Problem saving file");
		}
	}

	function saveCharacter() {
		var animArray:Array<Dynamic> = [];
		for (i in 0...char.animationsArray.length) {
			var daAnim = char.animationsArray[i];
			var newAnim = {
				anim: daAnim.anim,
				name: daAnim.name,
				fps: daAnim.fps,
				loop: daAnim.loop,
				indices: daAnim.indices,
				offsets: daAnim.offsets
			};
			animArray.push(newAnim);
		}
		var json = {
			"animations": animArray,
			"image": char.imageFile,
			"scale": char.jsonScale,
			"sing_duration": char.singDuration,
			"healthicon": char.healthIcon,
		
			"position": char.positionArray,
			"camera_position": char.cameraPosition,
		
			"flip_x": char.originalFlipX,
			"no_antialiasing": char.noAntialiasing,
			"healthbar_colors": char.healthColorArray,

			"repeatHoldAnimation": char.repeatHoldAnimation
		};

		var data:String = Json.stringify(json, "\t");

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, '${daAnim}.json');
		}
	}
}
