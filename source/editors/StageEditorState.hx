package editors;

import openfl.events.IOErrorEvent;
import openfl.events.Event;
import openfl.net.FileReference;
import haxe.Json;
import flixel.addons.ui.FlxUICheckBox;
import flixel.FlxSprite;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.ui.FlxButton;
import flixel.FlxObject;
import flixel.addons.ui.FlxUIInputText;
import flixel.FlxCamera;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.text.FlxText;
import haxe.io.Path;
#if sys
import sys.FileSystem;
#end
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.FlxG;
import flixel.addons.ui.FlxUITabMenu;
import StageData.StageFile;

using StringTools;

class StageEditorState extends MusicBeatState {
    var stage:Stage;
    var stageFile:StageFile;
    var curStage:String = 'stage';
    var boyfriend:Character;
    var dad:Character;
    var gf:Character;

    var UI_box:FlxUITabMenu;

    private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;
	private var camMenu:FlxCamera;

    public var camFollow:FlxPoint;
	public var camFollowPos:FlxObject;

    var cameraFollowPointerBoyfriend:FlxSprite;
    var cameraFollowPointerDad:FlxSprite;
    var cameraFollowPointerGF:FlxSprite;

    public function new(stage:String = 'stage') {
        super();
        curStage = stage;
        stageFile = StageData.getStageFile(curStage);
    }

    override public function create() {
        FlxG.mouse.visible = true;
        camEditor = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camMenu = new FlxCamera();
		camMenu.bgColor.alpha = 0;

		FlxG.cameras.reset(camEditor);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camMenu, false);

        stage = new Stage('', this);
        add(stage.background);

        gf = new Character(0, 0, 'gf', false, true);
        gf.scrollFactor.set(0.95, 0.95);
        add(gf);
        add(stage.overGF);
        dad = new Character(0, 0, 'dad', false, true);
        add(dad);
        add(stage.overDad);
        boyfriend = new Character(0, 0, 'bf', true, true);
        add(boyfriend);
        add(stage.foreground);

        var pointer:FlxGraphic = FlxGraphic.fromClass(GraphicCursorCross);
        cameraFollowPointerGF = new FlxSprite().loadGraphic(pointer);
		cameraFollowPointerGF.setGraphicSize(40, 40);
		cameraFollowPointerGF.updateHitbox();
		cameraFollowPointerGF.color = FlxColor.RED;
		add(cameraFollowPointerGF);
        cameraFollowPointerDad = new FlxSprite().loadGraphic(pointer);
		cameraFollowPointerDad.setGraphicSize(40, 40);
		cameraFollowPointerDad.updateHitbox();
		cameraFollowPointerDad.color = FlxColor.PINK;
		add(cameraFollowPointerDad);
		cameraFollowPointerBoyfriend = new FlxSprite().loadGraphic(pointer);
		cameraFollowPointerBoyfriend.setGraphicSize(40, 40);
		cameraFollowPointerBoyfriend.updateHitbox();
		cameraFollowPointerBoyfriend.color = FlxColor.BLUE;
		add(cameraFollowPointerBoyfriend);

        var tabs = [
			{name: 'Stage', label: 'Stage'},
		];
		UI_box = new FlxUITabMenu(null, tabs, true);
        UI_box.cameras = [camMenu];
		UI_box.resize(250, 375);
		UI_box.x = FlxG.width - UI_box.width;
		UI_box.y = FlxG.height - UI_box.height;
		UI_box.scrollFactor.set();
        addStageUI();
        add(UI_box);

        var tipTextArray:Array<String> = "WASD - Move Camera
        \nSpace - Center Camera to Girlfriend
		\nHold Shift to Move 10x faster\n".split('\n');

		for (i in 0...tipTextArray.length-1)
		{
			var tipText:FlxText = new FlxText(0, FlxG.height - 15 - 16 * (tipTextArray.length - i), 300, tipTextArray[i], 12);
			tipText.cameras = [camHUD];
			tipText.setFormat(null, 12, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
			tipText.scrollFactor.set();
			tipText.borderSize = 1;
			add(tipText);
		}

        camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);
        add(camFollowPos);
        FlxG.camera.follow(camFollowPos, LOCKON, 1);

        loadStage();

        camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
        camFollowPos.setPosition(camFollow.x, camFollow.y);

        super.create();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        FlxG.mouse.visible = true;

        var steppers:Array<FlxUINumericStepper> = [boyfriendPositionXStepper, boyfriendPositionYStepper, dadPositionXStepper, dadPositionYStepper, gfPositionXStepper, gfPositionYStepper];
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
				return;
			}
		}

        var dropDowns:Array<FlxUIDropDownMenu> = [stageDropDown];
        for (dropDown in dropDowns) {
            if (dropDown.dropPanel.visible) {
                FlxG.sound.muteKeys = [];
                FlxG.sound.volumeDownKeys = [];
                FlxG.sound.volumeUpKeys = [];
                return;
            }
        }

        FlxG.sound.muteKeys = TitleState.muteKeys;
		FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;

        if (FlxG.keys.justPressed.ESCAPE) {
            MusicBeatState.switchState(new editors.MasterEditorMenu());
            CoolUtil.playMenuMusic();
            FlxG.mouse.visible = false;
            return;
        }

        if (FlxG.keys.pressed.W || FlxG.keys.pressed.A || FlxG.keys.pressed.S || FlxG.keys.pressed.D)
        {
            var addToCam:Float = 500 * elapsed;
            if (FlxG.keys.pressed.SHIFT)
                addToCam *= 4;

            if (FlxG.keys.pressed.W)
                camFollow.y -= addToCam;
            else if (FlxG.keys.pressed.S)
                camFollow.y += addToCam;

            if (FlxG.keys.pressed.A)
                camFollow.x -= addToCam;
            else if (FlxG.keys.pressed.D)
                camFollow.x += addToCam;
        }

        if (FlxG.keys.justPressed.SPACE) {
            camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
        }

        var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * stageFile.camera_speed, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
    }

    override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)) {
			if (sender == directoryInputText) {
				stageFile.directory = directoryInputText.text;
			}
		} else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {
		    if (sender == boyfriendPositionXStepper)
			{
				stageFile.boyfriend[0] = boyfriendPositionXStepper.value;
                repositionChars();
			}
            else if (sender == boyfriendPositionYStepper)
            {
                stageFile.boyfriend[1] = boyfriendPositionYStepper.value;
                repositionChars();
            }
            else if (sender == dadPositionXStepper)
			{
				stageFile.opponent[0] = dadPositionXStepper.value;
                repositionChars();
			}
            else if (sender == dadPositionYStepper)
            {
                stageFile.opponent[1] = dadPositionYStepper.value;
                repositionChars();
            }
            else if (sender == gfPositionXStepper)
			{
				stageFile.girlfriend[0] = gfPositionXStepper.value;
                repositionChars();
			}
            else if (sender == gfPositionYStepper)
            {
                stageFile.girlfriend[1] = gfPositionYStepper.value;
                repositionChars();
            }
            else if (sender == defaultZoomStepper)
            {
                stageFile.defaultZoom = defaultZoomStepper.value;
                FlxG.camera.zoom = stageFile.defaultZoom;
            }
            else if (sender == cameraSpeedStepper)
            {
                stageFile.camera_speed = cameraSpeedStepper.value;
            }
            else if (sender == boyfriendCameraXStepper)
			{
				stageFile.camera_boyfriend[0] = boyfriendCameraXStepper.value;
                updatePointerPos();
			}
            else if (sender == boyfriendCameraYStepper)
			{
				stageFile.camera_boyfriend[1] = boyfriendCameraYStepper.value;
                updatePointerPos();
			}
            else if (sender == dadCameraXStepper)
			{
				stageFile.camera_opponent[0] = dadCameraXStepper.value;
                updatePointerPos();
			}
            else if (sender == dadCameraYStepper)
			{
				stageFile.camera_opponent[1] = dadCameraYStepper.value;
                updatePointerPos();
			}
            else if (sender == gfCameraXStepper)
			{
				stageFile.camera_girlfriend[0] = gfCameraXStepper.value;
                updatePointerPos();
			}
            else if (sender == gfCameraYStepper)
			{
				stageFile.camera_girlfriend[1] = gfCameraYStepper.value;
                updatePointerPos();
			}
		}
	}
    
    var stageDropDown:FlxUIDropDownMenu;

    var boyfriendPositionXStepper:FlxUINumericStepper;
	var boyfriendPositionYStepper:FlxUINumericStepper;
    var dadPositionXStepper:FlxUINumericStepper;
	var dadPositionYStepper:FlxUINumericStepper;
    var gfPositionXStepper:FlxUINumericStepper;
	var gfPositionYStepper:FlxUINumericStepper;
    var defaultZoomStepper:FlxUINumericStepper;
    var cameraSpeedStepper:FlxUINumericStepper;
    var boyfriendCameraXStepper:FlxUINumericStepper;
	var boyfriendCameraYStepper:FlxUINumericStepper;
    var dadCameraXStepper:FlxUINumericStepper;
	var dadCameraYStepper:FlxUINumericStepper;
    var gfCameraXStepper:FlxUINumericStepper;
	var gfCameraYStepper:FlxUINumericStepper;

    var directoryInputText:FlxUIInputText;

    var check_pixelStage:FlxUICheckBox;
    var check_hideGF:FlxUICheckBox;

    function addStageUI() {
        var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Stage";

        stageDropDown = new FlxUIDropDownMenu(10, 30, FlxUIDropDownMenu.makeStrIdLabelArray([''], true), function(stage:String)
		{
			curStage = stageList[Std.parseInt(stage)];
			loadStage();
			reloadStageDropDown();
		});
		stageDropDown.selectedLabel = curStage;
		reloadStageDropDown();

        var reloadStage:FlxButton = new FlxButton(stageDropDown.x + stageDropDown.width, stageDropDown.y, "Reload Stage", function()
        {
            Paths.setCurrentLevel(stageFile.directory);
            stage.createStage(curStage);
        });

        boyfriendPositionXStepper = new FlxUINumericStepper(stageDropDown.x, stageDropDown.y + 40, 10, stageFile.boyfriend[0], -9000, 9000, 3);
		boyfriendPositionYStepper = new FlxUINumericStepper(boyfriendPositionXStepper.x + 60, boyfriendPositionXStepper.y, 10, stageFile.boyfriend[1], -9000, 9000, 3);
        dadPositionXStepper = new FlxUINumericStepper(boyfriendPositionXStepper.x, boyfriendPositionXStepper.y + 40, 10, stageFile.opponent[0], -9000, 9000, 3);
		dadPositionYStepper = new FlxUINumericStepper(dadPositionXStepper.x + 60, dadPositionXStepper.y, 10, stageFile.opponent[1], -9000, 9000, 3);
        gfPositionXStepper = new FlxUINumericStepper(dadPositionXStepper.x, dadPositionXStepper.y + 40, 10, stageFile.girlfriend[0], -9000, 9000, 3);
		gfPositionYStepper = new FlxUINumericStepper(gfPositionXStepper.x + 60, gfPositionXStepper.y, 10, stageFile.girlfriend[1], -9000, 9000, 3);

        defaultZoomStepper = new FlxUINumericStepper(dadPositionYStepper.x + 60, dadPositionYStepper.y, 0.05, stageFile.defaultZoom, 0.1, 5, 3);
        cameraSpeedStepper = new FlxUINumericStepper(defaultZoomStepper.x, defaultZoomStepper.y + 40, 0.1, stageFile.camera_speed, 0.1, 10, 3);
        
        boyfriendCameraXStepper = new FlxUINumericStepper(gfPositionXStepper.x, gfPositionXStepper.y + 40, 10, stageFile.camera_boyfriend[0], -9000, 9000, 3);
		boyfriendCameraYStepper = new FlxUINumericStepper(boyfriendCameraXStepper.x + 60, boyfriendCameraXStepper.y, 10, stageFile.camera_boyfriend[1], -9000, 9000, 3);
        dadCameraXStepper = new FlxUINumericStepper(boyfriendCameraXStepper.x, boyfriendCameraXStepper.y + 40, 10, stageFile.camera_opponent[0], -9000, 9000, 3);
		dadCameraYStepper = new FlxUINumericStepper(dadCameraXStepper.x + 60, dadCameraXStepper.y, 10, stageFile.opponent[1], -9000, 9000, 3);
        gfCameraXStepper = new FlxUINumericStepper(dadCameraXStepper.x, dadCameraXStepper.y + 40, 10, stageFile.camera_girlfriend[0], -9000, 9000, 3);
		gfCameraYStepper = new FlxUINumericStepper(gfCameraXStepper.x + 60, gfCameraXStepper.y, 10, stageFile.camera_girlfriend[1], -9000, 9000, 3);

        directoryInputText = new FlxUIInputText(boyfriendPositionYStepper.x + 60, boyfriendPositionYStepper.y, 80, stageFile.directory, 8);

        check_pixelStage = new FlxUICheckBox(cameraSpeedStepper.x, cameraSpeedStepper.y + 40, null, null, "Pixel Stage", 100);
		check_pixelStage.checked = stageFile.isPixelStage;
		check_pixelStage.callback = function()
		{
			stageFile.isPixelStage = check_pixelStage.checked;
		};

        check_hideGF = new FlxUICheckBox(check_pixelStage.x, check_pixelStage.y + 40, null, null, "Hide Girlfriend", 100);
		check_hideGF.checked = stageFile.hide_girlfriend;
		check_hideGF.callback = function()
		{
			stageFile.hide_girlfriend = check_hideGF.checked;
            gf.visible = (stageFile.hide_girlfriend == false);
            updatePointerPos();
		};

        var saveStageButton:FlxButton = new FlxButton(gfCameraXStepper.x, gfCameraXStepper.y + 40, "Save Stage", function() {
			saveStage();
		});

        tab_group.add(new FlxText(stageDropDown.x, stageDropDown.y - 18, 0, 'Stage:'));
        tab_group.add(new FlxText(boyfriendPositionXStepper.x, boyfriendPositionXStepper.y - 18, 0, 'Boyfriend X/Y:'));
        tab_group.add(new FlxText(dadPositionXStepper.x, dadPositionXStepper.y - 18, 0, 'Opponent X/Y:'));
        tab_group.add(new FlxText(gfPositionXStepper.x, gfPositionXStepper.y - 18, 0, 'Girlfriend X/Y:'));
        tab_group.add(new FlxText(defaultZoomStepper.x, defaultZoomStepper.y - 18, 0, 'Default Camera Zoom:'));
        tab_group.add(new FlxText(cameraSpeedStepper.x, cameraSpeedStepper.y - 18, 0, 'Camera Speed;'));
        tab_group.add(new FlxText(boyfriendCameraXStepper.x, boyfriendCameraXStepper.y - 18, 0, 'Boyfriend Camera X/Y:'));
        tab_group.add(new FlxText(dadCameraXStepper.x, dadCameraXStepper.y - 18, 0, 'Opponent Camera X/Y:'));
        tab_group.add(new FlxText(gfCameraXStepper.x, gfCameraXStepper.y - 18, 0, 'Girlfriend Camera X/Y:'));
        tab_group.add(new FlxText(directoryInputText.x, directoryInputText.y - 18, 0, 'Directory:'));

        tab_group.add(reloadStage);
        tab_group.add(saveStageButton);
        tab_group.add(boyfriendPositionXStepper);
        tab_group.add(boyfriendPositionYStepper);
        tab_group.add(dadPositionXStepper);
        tab_group.add(dadPositionYStepper);
        tab_group.add(gfPositionXStepper);
        tab_group.add(gfPositionYStepper);
        tab_group.add(defaultZoomStepper);
        tab_group.add(cameraSpeedStepper);
        tab_group.add(boyfriendCameraXStepper);
        tab_group.add(boyfriendCameraYStepper);
        tab_group.add(dadCameraXStepper);
        tab_group.add(dadCameraYStepper);
        tab_group.add(gfCameraXStepper);
        tab_group.add(gfCameraYStepper);
        tab_group.add(directoryInputText);
        tab_group.add(check_pixelStage);
        tab_group.add(check_hideGF);
        tab_group.add(stageDropDown);

        UI_box.addGroup(tab_group);
    }

    var stageList:Array<String> = [];
    function reloadStageDropDown() {
		#if sys
		stageList = [];
        var stagesLoaded:Map<String, Bool> = new Map();
		var directories:Array<String> = [Paths.getPreloadPath('stages/')];
		#if MODS_ALLOWED
		directories.push(Paths.mods('stages/'));
		#end
		for (i in 0...directories.length) {
			var directory:String = directories[i];
			if (FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json')) {
						var charToCheck:String = file.substr(0, file.length - 5);
						if (!stagesLoaded.exists(charToCheck)) {
                            stageList.push(charToCheck);
                            stagesLoaded.set(charToCheck, true);
						}
					}
				}
			}
		}
		#else
		stageList = CoolUtil.coolTextFile(Paths.txt('stageList'));
		#end

		stageDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(stageList, true));
		stageDropDown.selectedLabel = curStage;
	}

    function updatePointerPos() {
        if (!gf.visible)
            cameraFollowPointerGF.setPosition(stageFile.camera_girlfriend[0], stageFile.camera_girlfriend[1]);
        else
            cameraFollowPointerGF.setPosition(gf.getMidpoint().x + stageFile.camera_girlfriend[0], gf.getMidpoint().y + stageFile.camera_girlfriend[1]);
        cameraFollowPointerDad.setPosition(dad.getMidpoint().x + 150 + stageFile.camera_opponent[0], dad.getMidpoint().y - 100 + stageFile.camera_opponent[1]);
        cameraFollowPointerBoyfriend.setPosition(boyfriend.getMidpoint().x - 100 + stageFile.camera_boyfriend[0], boyfriend.getMidpoint().y - 100 + stageFile.camera_boyfriend[1]);

        cameraFollowPointerGF.x -= 20;
        cameraFollowPointerGF.y -= 20;
        cameraFollowPointerDad.x -= 20;
        cameraFollowPointerDad.y -= 20;
        cameraFollowPointerBoyfriend.x -= 20;
        cameraFollowPointerBoyfriend.y -= 20;
    }

    function loadStage() {
        stageFile = StageData.getStageFile(curStage);
        if (stageFile == null) {
            stageFile = {
                directory: "",
                defaultZoom: 0.9,
                isPixelStage: false,
            
                boyfriend: [770, 100],
                girlfriend: [400, 130],
                opponent: [100, 100],
                hide_girlfriend: false,

                camera_boyfriend: [0, 0],
                camera_opponent: [0, 0],
                camera_girlfriend: [0, 0],
                camera_speed: 1
            };
        }
        Paths.setCurrentLevel(stageFile.directory);
        stage.createStage(curStage);
        gf.visible = (stageFile.hide_girlfriend == false);
        repositionChars();
        FlxG.camera.zoom = stageFile.defaultZoom;

        boyfriendPositionXStepper.value = stageFile.boyfriend[0];
        boyfriendPositionYStepper.value = stageFile.boyfriend[1];
        dadPositionXStepper.value = stageFile.opponent[0];
        dadPositionYStepper.value = stageFile.opponent[1];
        gfPositionXStepper.value = stageFile.girlfriend[0];
        gfPositionYStepper.value = stageFile.girlfriend[1];
        directoryInputText.text = stageFile.directory;
        defaultZoomStepper.value = stageFile.defaultZoom;
        cameraSpeedStepper.value = stageFile.camera_speed;
        boyfriendCameraXStepper.value = stageFile.camera_boyfriend[0];
        boyfriendCameraYStepper.value = stageFile.camera_boyfriend[1];
        dadCameraXStepper.value = stageFile.camera_opponent[0];
        dadCameraYStepper.value = stageFile.camera_opponent[1];
        gfCameraXStepper.value = stageFile.camera_girlfriend[0];
        gfCameraYStepper.value = stageFile.camera_girlfriend[1];
        check_pixelStage.checked = stageFile.isPixelStage;
        check_hideGF.checked = stageFile.hide_girlfriend;
    }

    function repositionChars() {
        gf.setPosition(stageFile.girlfriend[0] + gf.positionArray[0], stageFile.girlfriend[1] + gf.positionArray[1]);
        dad.setPosition(stageFile.opponent[0] + dad.positionArray[0], stageFile.opponent[1] + dad.positionArray[1]);
        boyfriend.setPosition(stageFile.boyfriend[0] + boyfriend.positionArray[0], stageFile.boyfriend[1] + boyfriend.positionArray[1]);
        updatePointerPos();
    }

    var _file:FileReference;

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}

    function saveStage() {
		var json = {
			"directory": stageFile.directory,
            "defaultZoom": stageFile.defaultZoom,
            "isPixelStage": stageFile.isPixelStage,

            "boyfriend": stageFile.boyfriend,
            "girlfriend": stageFile.girlfriend,
            "opponent": stageFile.opponent,
            "hide_girlfriend": stageFile.hide_girlfriend,

            "camera_boyfriend": stageFile.camera_boyfriend,
            "camera_opponent": stageFile.camera_opponent,
            "camera_girlfriend": stageFile.camera_girlfriend,
            "camera_speed": stageFile.camera_speed
		};

		var data:String = Json.stringify(json, "\t");

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, '$curStage.json');
		}
	}
}