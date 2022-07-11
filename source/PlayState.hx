package;

import StrumNote.KeyChangeEvent;
import StrumNote.StrumLine;
import FreeplayState.SongMetadata;
#if cpp
import lime.media.openal.AL;
#end
import flixel.FlxBasic;
#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.effects.FlxTrail;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
#if HSCRIPT_ALLOWED
import hscript.ParserEx;
#end
import lime.app.Application;
import lime.graphics.Image;
import openfl.events.KeyboardEvent;
import openfl.utils.Assets as OpenFlAssets;
import Achievements;
import Character;
import Conductor.Rating;
import DialogueBoxPsych;
import FunkinLua;
import Note.EventNote;
import StageData;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

#if VIDEOS_ALLOWED
import vlc.MP4Handler;
#end

using StringTools;

class PlayState extends MusicBeatState
{
	public static var ratingStuff:Array<Array<Dynamic>> = [
		['You Suck!', 0.2], //From 0% to 19%
		['Shit', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Perfect!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];

	public var modchartTweens:Map<String, FlxTween> = new Map();
	public var modchartSprites:Map<String, ModchartSprite> = new Map();
	public var modchartTimers:Map<String, FlxTimer> = new Map();
	public var modchartSounds:Map<String, FlxSound> = new Map();
	public var modchartTexts:Map<String, ModchartText> = new Map();
	public var modchartSaves:Map<String, FlxSave> = new Map();

	//event variables
	private var isCameraOnForcedPos:Bool = false;
	public var boyfriendMap:Map<String, Character> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	public var variables:Map<String, Dynamic> = new Map();

	public var stage:Stage;
	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	
	public var boyfriendGroup:FlxTypedSpriteGroup<Character>;
	public var dadGroup:FlxTypedSpriteGroup<Character>;
	public var gfGroup:FlxTypedSpriteGroup<Character>;
	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var originalSong:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var noteKillOffset:Float = 350;
	public var spawnTime:Float = 2000;

	public var vocals:FlxSound;
	public var vocalsDad:FlxSound;
	var foundDadVocals:Bool = false;

	public var dad(get, never):Character;
	public var gf(get, never):Character;
	public var boyfriend(get, never):Character;
	public var playerChar(get, never):FlxTypedSpriteGroup<Character>;
	public var opponentChar(get, never):FlxTypedSpriteGroup<Character>;

	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	private var strumLine:FlxSprite;

	//Handles the new epic mega sexy cam code that i've done
	public var camFollow:FlxPoint;
	public var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumLine>;
	public var playerStrums(get, never):StrumLine;
	public var opponentStrums(get, never):StrumLine;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	public var keybindGroup:FlxTypedGroup<AttachedFlxText>;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	public var camBop:Bool = false;
	public var curSong:String = "";
	public var curSongDisplayName:String = "";

	public var health:Float = 1;
	public var shownHealth:Float = 1;
	public var combo:Int = 0;

	private var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;
	private var songPercent:Float = 0;

	private var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;

	private var underlayPlayer:FlxSprite;
	
	public var ratingsData:Array<Rating> = [];
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;
	
	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = true;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;
	public var opponentChart:Bool = false;
	public var playbackRate:Float = 1;
	public var demoMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;
	public var practiceFailedSine:Float = 0;
	public var practiceFailed:Bool = false;
	public var practiceFailedTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;
	public var iconBopSpeed:Int = 1;

	var dialogue:Array<String> = null;
	var dialogueJson:DialogueFile = null;

	var dadbattleBlack:BGSprite;
	var dadbattleLight:BGSprite;
	var dadbattleSmokes:FlxSpriteGroup;

	var blammedLightsBlack:FlxSprite;
	var phillyWindowEvent:BGSprite;
	var phillyGlowGradient:PhillyGlow.PhillyGlowGradient;
	var phillyGlowParticles:FlxTypedGroup<PhillyGlow.PhillyGlowParticle>;
	var curLightEvent:Int = -1;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var songTxt:FlxText;
	var scoreTxtTween:FlxTween;
	var stepTxt:FlxText;
	var beatTxt:FlxText;
	var sectionTxt:FlxText;

	public var ratingTxtGroup:FlxTypedGroup<FlxText>;
	public var ratingTxtTweens:Array<FlxTween> = [null];

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;
	public var defaultCamHudZoom:Float = 1;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	public var inCutscene:Bool = false;
	public var camMove:Bool = true;
	public var skipCountdown:Bool = false;
	public var songLength:Float = 0;
	public var showSongText:Bool = true;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if DISCORD_ALLOWED
	// Discord RPC variables
	public var storyDifficultyText:String = "";
	public var detailsText:String = "";
	public var detailsPausedText:String = "";
	public var detailsGameOverText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;
	public var luaArray:Array<FunkinLua> = [];
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;
	
	// Less laggy controls
	private var keysArray:Array<Array<FlxKey>>;

	public var playerKeys(get, never):Int;
	public var opponentKeys(get, never):Int;

	var playerColors:Array<String> = [];
	var opponentColors:Array<String> = [];

	var bfGroupFile:CharacterGroupFile = null;
	var dadGroupFile:CharacterGroupFile = null;
	var gfGroupFile:CharacterGroupFile = null;

	public var inEditor:Bool = false;
	public var startPos:Float = 0;
	var timerToStart:Float = 0;

	public var strumMaps:Array<Map<Int, StrumLine>> = [];

	var lastTitle = '';

	public var hideInDemoMode:Array<FlxBasic> = [];

	function get_boyfriend() {
		return boyfriendGroup.members[0];
	}

	function get_dad() {
		return dadGroup.members[0];
	}

	function get_gf() {
		return gfGroup.members[0];
	}

	function get_playerChar() {
		return opponentChart ? dadGroup : boyfriendGroup;
	}

	function get_opponentChar() {
		return !opponentChart ? dadGroup : boyfriendGroup;
	}

	function get_playerKeys() {
		return playerStrums.keys;
	}

	function get_opponentKeys() {
		return opponentStrums.keys;
	}

	function get_playerStrums() {
		return opponentChart ? strumLineNotes.members[0] : strumLineNotes.members[1];
	}

	function get_opponentStrums() {
		return !opponentChart ? strumLineNotes.members[0] : strumLineNotes.members[1];
	}

	public function new(?inEditor:Bool = false, ?startPos:Float = 0) {
		this.inEditor = inEditor;
		if (inEditor) {
			this.startPos = startPos;
			Conductor.songPosition = startPos;
			timerToStart = Conductor.normalizedCrochet;
		}
		super();
	}

	var precacheList:Map<String, String> = new Map<String, String>();

	override public function create()
	{
		Paths.clearStoredMemory();
		lastTitle = Application.current.window.title;
		FlxG.mouse.visible = false;
		FlxG.timeScale = 1;

		// for lua
		instance = this;

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; //Reset to default

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		if (!inEditor) {
			// Gameplay settings
			healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
			healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
			instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
			practiceMode = ClientPrefs.getGameplaySetting('practice', false);
			cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
			opponentChart = ClientPrefs.getGameplaySetting('opponentplay', false);
			playbackRate = ClientPrefs.getGameplaySetting('songspeed', 1);
			demoMode = ClientPrefs.getGameplaySetting('demomode', false);
			if (demoMode) {
				cpuControlled = true;
			}
			Conductor.playbackRate = playbackRate;

			camGame = new FlxCamera();
			camHUD = new FlxCamera();
			camOther = new FlxCamera();
			camHUD.bgColor.alpha = 0;
			camOther.bgColor.alpha = 0;

			FlxG.cameras.reset(camGame);
			FlxG.cameras.add(camHUD, false);
			FlxG.cameras.add(camOther, false);
		} else {
			var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
			bg.scrollFactor.set();
			bg.color = FlxColor.fromHSB(FlxG.random.int(0, 359), FlxG.random.float(0, 0.8), FlxG.random.float(0.3, 1));
			add(bg);
		}

		grpNoteSplashes = new FlxTypedGroup();

		if (!inEditor) {
			CustomFadeTransition.nextCamera = camOther;
			persistentUpdate = true;
		}
		
		if (SONG == null)
			SONG = Song.loadFromJson('test', 'test');

		originalSong = Reflect.copy(SONG);

		if (practiceMode || cpuControlled || opponentChart) SONG.validScore = false;

		curSong = Paths.formatToSongPath(SONG.song);
		curSongDisplayName = Song.getDisplayName(SONG.song);
		showSongText = (isStoryMode && ClientPrefs.timeBarType != 'Song Name' && deathCounter < 1);

		//Ratings
		ratingsData.push(new Rating('sick')); //default rating

		var rating:Rating = new Rating('good');
		rating.displayName = 'Good!';
		rating.ratingMod = 0.7;
		rating.score = 200;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('bad');
		rating.displayName = 'Bad';
		rating.ratingMod = 0.4;
		rating.score = 100;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('shit');
		rating.displayName = 'Shit';
		rating.ratingMod = 0;
		rating.score = 50;
		rating.noteSplash = false;
		rating.causesMiss = ClientPrefs.shitMisses;
		ratingsData.push(rating);

		for (i in ratingsData) {
			ratingTxtTweens.push(null);
		}

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);
		Conductor.changeSignature(SONG.timeSignature);

		if (storyDifficulty > CoolUtil.difficulties.length - 1) {
			storyDifficulty = CoolUtil.difficulties.indexOf('Normal');
			if (storyDifficulty == -1) storyDifficulty = 0;
		}

		#if DISCORD_ALLOWED
		if (!inEditor) {
			storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

			// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
			if (isStoryMode)
			{
				detailsText = 'Story Mode: ${WeekData.getCurrentWeek().weekName}';
			}
			else
			{
				detailsText = "Freeplay";
			}

			// String for when the game is paused
			detailsPausedText = 'Paused - $detailsText';

			// String for when the Game Over screen appears
			detailsGameOverText = 'Game Over - $detailsText';
		}
		#end

		GameOverSubstate.resetVariables();

		curStage = SONG.stage;
		if (SONG.stage == null || SONG.stage.length < 1) {
			curStage = StageData.getStageFromSong(curSong);
		}
		SONG.stage = curStage;

		var camPos:FlxPoint = null;
		if (!inEditor) {
			var stageData:StageFile = StageData.getStageFile(curStage);
			if (stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
				stageData = {
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

			defaultCamZoom = stageData.defaultZoom;
			isPixelStage = stageData.isPixelStage;
			BF_X = stageData.boyfriend[0];
			BF_Y = stageData.boyfriend[1];
			GF_X = stageData.girlfriend[0];
			GF_Y = stageData.girlfriend[1];
			DAD_X = stageData.opponent[0];
			DAD_Y = stageData.opponent[1];
			
			if(stageData.camera_speed != null)
				cameraSpeed = stageData.camera_speed;
	
			boyfriendCameraOffset = stageData.camera_boyfriend;
			if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
				boyfriendCameraOffset = [0, 0];
	
			opponentCameraOffset = stageData.camera_opponent;
			if(opponentCameraOffset == null)
				opponentCameraOffset = [0, 0];
	
			girlfriendCameraOffset = stageData.camera_girlfriend;
			if(girlfriendCameraOffset == null)
				girlfriendCameraOffset = [0, 0];

			boyfriendGroup = new FlxTypedSpriteGroup(BF_X, BF_Y);
			dadGroup = new FlxTypedSpriteGroup(DAD_X, DAD_Y);
			gfGroup = new FlxTypedSpriteGroup(GF_X, GF_Y);

			stage = new Stage(curStage, this);
			add(stage.background);

			switch(Paths.formatToSongPath(SONG.song))
            {
                case 'stress':
                    GameOverSubstate.characterName = 'bf-holding-gf-dead';
            }

			if(SONG.skinModifier.endsWith('pixel')) {
				introSoundsSuffix = '-pixel';
			}

			add(gfGroup); //Needed for blammed lights
			add(stage.overGF);

			add(dadGroup);
			add(stage.overDad);
			add(boyfriendGroup);

			add(stage.foreground);

			#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
			luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
			luaDebugGroup.cameras = [camOther];
			add(luaDebugGroup);

			#if sys
			// "GLOBAL" SCRIPTS
			var filesPushed:Array<String> = [];
			var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

			for (folder in foldersToCheck)
			{
				if (FileSystem.exists(folder))
				{
					for (file in FileSystem.readDirectory(folder))
					{
						#if LUA_ALLOWED
						if (file.endsWith('.lua') && !filesPushed.contains(file))
						{
							luaArray.push(new FunkinLua(folder + file));
							filesPushed.push(file);
						}
						#end
						#if HSCRIPT_ALLOWED
						if (file.endsWith('.hscript') && !filesPushed.contains(file))
						{
							addHscript(folder + file);
							filesPushed.push(file);
						}
						#end
					}
				}
			}
			#end
			
			// STAGE SCRIPTS
			if (ClientPrefs.gameQuality != 'Crappy') {
				#if LUA_ALLOWED
				var doPush:Bool = false;
				var luaFile:String = Paths.getPreloadPath('stages/$curStage.lua');
				if (Paths.exists(luaFile, TEXT)) {
					doPush = true;
				}

				if (doPush) 
					luaArray.push(new FunkinLua(luaFile));
				#end

				#if HSCRIPT_ALLOWED
				var doPush:Bool = false;
				var hscriptFile:String = Paths.getPreloadPath('stages/$curStage.hscript');
				if (Paths.exists(hscriptFile, TEXT)) {
					doPush = true;
				}

				if (doPush) 
					addHscript(hscriptFile);
				#end
			}
			#end

			var gfVersion:String = SONG.gfVersion;
			if (gfVersion == null || gfVersion.length < 1)
			{
				gfVersion = Song.getGFVersion(curSong, curStage);
				SONG.gfVersion = gfVersion; //Fix for the Chart Editor
			}

			if (stageData.hide_girlfriend == false)
			{
				gfGroupFile = Character.getFile(gfVersion);
				if (gfGroupFile != null && gfGroupFile.characters != null && gfGroupFile.characters.length > 0) {
					for (i in 0...gfGroupFile.characters.length) {
						addCharacter(gfGroupFile.characters[i].name, i, false, false, gfGroup, gfGroupFile.characters[i].position[0] + gfGroupFile.position[0], gfGroupFile.characters[i].position[1] + gfGroupFile.position[1], 0.95, 0.95);
						checkPicoSpeaker(gfGroup.members[i]);
					}
				} else {
					gfGroupFile = null;
					addCharacter(gfVersion, 0, false, false, gfGroup, 0, 0, 0.95, 0.95);
					checkPicoSpeaker(gfGroup.members[0]);
				}
				for (i in gfGroup) {
					startCharacterScripts(i.curCharacter);
					
				}
			}

			dadGroupFile = Character.getFile(SONG.player2);
			if (dadGroupFile != null && dadGroupFile.characters != null && dadGroupFile.characters.length > 0) {
				for (i in 0...dadGroupFile.characters.length) {
					addCharacter(dadGroupFile.characters[i].name, i, false, opponentChart, dadGroup, dadGroupFile.characters[i].position[0] + dadGroupFile.position[0], dadGroupFile.characters[i].position[1] + dadGroupFile.position[1]);
				}
			} else {
				dadGroupFile = null;
				addCharacter(SONG.player2, 0, false, opponentChart, dadGroup);
			}
			for (i in dadGroup) {
				startCharacterScripts(i.curCharacter);
			}

			bfGroupFile = Character.getFile(SONG.player1);
			if (bfGroupFile != null && bfGroupFile.characters != null && bfGroupFile.characters.length > 0) {
				for (i in 0...bfGroupFile.characters.length) {
					addCharacter(bfGroupFile.characters[i].name, i, true, !opponentChart, boyfriendGroup, bfGroupFile.characters[i].position[0] + bfGroupFile.position[0], bfGroupFile.characters[i].position[1] + bfGroupFile.position[1]);
				}
			} else {
				bfGroupFile = null;
				addCharacter(SONG.player1, 0, true, !opponentChart, boyfriendGroup);
			}
			for (i in boyfriendGroup) {
				startCharacterScripts(i.curCharacter);
			}
			
			camPos = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
			if(gf != null)
			{
				camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
				camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
			}

			if (dad.curCharacter.startsWith('gf')) {
				dad.setPosition(GF_X, GF_Y);
				if(gf != null)
					gf.visible = false;
			}

			stage.onCharacterInit();
		}

		underlayPlayer = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.BLACK);
		underlayPlayer.scrollFactor.set();
		underlayPlayer.alpha = ClientPrefs.underlayAlpha;
		underlayPlayer.visible = false;
		add(underlayPlayer);
		hideInDemoMode.push(underlayPlayer);

		Conductor.songPosition = -5000;

		//PRECACHING UI IMAGES
		var imagesToCheck = [
			'combo',
			'ready',
			'set',
			'go'
		];
		for (i in ratingsData) {
			imagesToCheck.push(i.image);
		}
		for (i in 0...10) {
			imagesToCheck.push('num$i');
		}

		for (img in imagesToCheck) {
			var spr = new FlxSprite().loadGraphic(Paths.image(getUIFile(img)));
			spr.alpha = 0.00001;
			spr.scrollFactor.set();
			spr.cameras = [camHUD];
			add(spr);
		}

		for (img in imagesToCheck) {
			precacheList.set(getUIFile(img), 'image');
		}

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		if (ClientPrefs.downScroll) strumLine.y = FlxG.height - 210;
		strumLine.scrollFactor.set();

		if (!inEditor) {
			var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled');
			timeTxt = new FlxText(42 + (FlxG.width / 2) - 248, 19, 400, "", 32);
			timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			timeTxt.scrollFactor.set();
			timeTxt.alpha = 0;
			timeTxt.borderSize = 2;
			timeTxt.visible = showTime;
			if (ClientPrefs.downScroll) timeTxt.y = FlxG.height - 44;
			if (ClientPrefs.timeBarType == 'Song Name') {
				timeTxt.text = curSongDisplayName;
				timeTxt.size = 24;
				timeTxt.y += 3;
			}
			timeTxt.screenCenter(X);
			hideInDemoMode.push(timeTxt);
			updateTime = showTime;

			if (showSongText) {
				songTxt = new FlxText(timeTxt.x, timeTxt.y + 3, timeTxt.fieldWidth, curSongDisplayName, 24);
				songTxt.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				songTxt.scrollFactor.set();
				songTxt.alpha = timeTxt.alpha;
				songTxt.borderSize = timeTxt.borderSize;
				songTxt.visible = timeTxt.visible;
				hideInDemoMode.push(songTxt);
			}

			timeBarBG = new AttachedSprite(getUIFile('timeBar'));
			timeBarBG.x = timeTxt.x;
			timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
			timeBarBG.scrollFactor.set();
			timeBarBG.alpha = 0;
			timeBarBG.visible = showTime;
			timeBarBG.color = FlxColor.BLACK;
			timeBarBG.xAdd = -4;
			timeBarBG.yAdd = -4;
			add(timeBarBG);
			hideInDemoMode.push(timeBarBG);

			timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
				'songPercent', 0, 1);
			timeBar.scrollFactor.set();
			timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
			timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
			timeBar.alpha = 0;
			timeBar.visible = showTime;
			hideInDemoMode.push(timeBar);
			add(timeBar);
			add(timeTxt);
			if (showSongText) add(songTxt);
			timeBarBG.sprTracker = timeBar;
		} else {
			updateTime = false;
		}

		strumLineNotes = new FlxTypedGroup();
		add(strumLineNotes);
		add(grpNoteSplashes);
		keybindGroup = new FlxTypedGroup();
		hideInDemoMode.push(strumLineNotes);
		hideInDemoMode.push(grpNoteSplashes);

		var splash:NoteSplash = new NoteSplash(100, 100, null);
		grpNoteSplashes.add(splash);
		splash.alphaMult = 0;

		add(keybindGroup);
		hideInDemoMode.push(keybindGroup);

		generateStaticArrows(0, SONG.dadKeyAmount, false);
		generateStaticArrows(1, SONG.boyfriendKeyAmount, true);
		strumLineNotes.add(strumMaps[0].get(SONG.dadKeyAmount));
		strumLineNotes.add(strumMaps[1].get(SONG.boyfriendKeyAmount));
		setKeysArray(playerKeys);

		generateSong();

		for (i in 0...strumLineNotes.length) {
			var strumGroup = strumLineNotes.members[i];
			for (event in strumGroup.keyChangeMap) {
				if (!strumMaps[i].exists(event.keys)) {
					generateStaticArrows(i, event.keys, strumGroup.isBoyfriend);
				}
			}
		}

		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		if (!inEditor) {
			for (notetype in noteTypeMap.keys())
			{
				#if LUA_ALLOWED
				var luaToLoad:String = Paths.getPreloadPath('custom_notetypes/$notetype.lua');
				if (Paths.exists(luaToLoad, TEXT))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
				#end

				#if HSCRIPT_ALLOWED
				var hscriptToLoad:String = Paths.getPreloadPath('custom_notetypes/$notetype.hscript');
				if (Paths.exists(hscriptToLoad, TEXT))
				{
					addHscript(hscriptToLoad);
				}
				#end
			}
			for (event in eventPushedMap.keys())
			{
				#if LUA_ALLOWED
				var luaToLoad:String = Paths.getPreloadPath('custom_events/$event.lua');
				if (Paths.exists(luaToLoad, TEXT))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
				#end

				#if HSCRIPT_ALLOWED
				var hscriptToLoad:String = Paths.getPreloadPath('custom_events/$event.hscript');
				if (Paths.exists(hscriptToLoad, TEXT))
				{
					addHscript(hscriptToLoad);
				}
				#end
			}
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		var doof:DialogueBox = null;
		if (!inEditor) {
			var file:String = Paths.json('$curSong/dialogue'); //Checks for json/Psych Engine dialogue
			if (Paths.exists(file, TEXT) && dialogueJson == null) {
				dialogueJson = DialogueBoxPsych.parseDialogue(file);
			}

			var file:String = Paths.txt('$curSong/${curSong}Dialogue'); //Checks for vanilla/Senpai dialogue
			if (Paths.exists(file, TEXT) && dialogue == null) {
				dialogue = CoolUtil.coolTextFile(file);
			}
			doof = new DialogueBox(dialogue);
			doof.scrollFactor.set();
			doof.finishThing = startCountdown;
			doof.nextDialogueThing = startNextDialogue;
			doof.skipDialogueThing = skipDialogue;

			camFollow = new FlxPoint();
			camFollowPos = new FlxObject(0, 0, 1, 1);

			snapCamFollowToPos(camPos.x, camPos.y);
			if (prevCamFollow != null)
			{
				camFollow = prevCamFollow;
				prevCamFollow = null;
			}
			if (prevCamFollowPos != null)
			{
				camFollowPos = prevCamFollowPos;
				prevCamFollowPos = null;
			}
			add(camFollowPos);

			FlxG.camera.follow(camFollowPos, LOCKON, 1);
			FlxG.camera.zoom = defaultCamZoom;
			camHUD.zoom = defaultCamHudZoom;
			FlxG.camera.focusOn(camFollow);

			FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

			FlxG.fixedTimestep = false;
			moveCameraSection();

			healthBarBG = new AttachedSprite(getUIFile('healthBar'));
			healthBarBG.y = FlxG.height * 0.89;
			healthBarBG.screenCenter(X);
			healthBarBG.scrollFactor.set();
			healthBarBG.visible = !ClientPrefs.hideHud;
			healthBarBG.xAdd = -4;
			healthBarBG.yAdd = -4;
			add(healthBarBG);
			if (ClientPrefs.downScroll) healthBarBG.y = 0.11 * FlxG.height;

			healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, (opponentChart ? LEFT_TO_RIGHT : RIGHT_TO_LEFT), Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
				'shownHealth', 0, 2);
			healthBar.scrollFactor.set();
			healthBar.visible = !ClientPrefs.hideHud;
			healthBar.alpha = ClientPrefs.healthBarAlpha;
			healthBar.numDivisions = 600;
			add(healthBar);
			healthBarBG.sprTracker = healthBar;

			if (bfGroupFile != null) {
				iconP1 = new HealthIcon(bfGroupFile.healthicon, true);
			} else {
				iconP1 = new HealthIcon(boyfriend.healthIcon, true);
			}
			iconP1.y = healthBar.y - 75;
			iconP1.visible = !ClientPrefs.hideHud;
			iconP1.alpha = ClientPrefs.healthBarAlpha;
			add(iconP1);

			if (dadGroupFile != null) {
				iconP2 = new HealthIcon(dadGroupFile.healthicon);
			} else {
				iconP2 = new HealthIcon(dad.healthIcon);
			}
			iconP2.y = healthBar.y - 75;
			iconP2.visible = !ClientPrefs.hideHud;
			iconP2.alpha = ClientPrefs.healthBarAlpha;
			add(iconP2);
			reloadHealthBarColors();
		}

		scoreTxt = new FlxText(0, FlxG.height * 0.89 + 36, FlxG.width - 20, "", 20);
		if (ClientPrefs.downScroll) scoreTxt.y = 0.11 * FlxG.height + 36;
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.hideHud && !cpuControlled;
		scoreTxt.screenCenter(X);
		add(scoreTxt);
		hideInDemoMode.push(scoreTxt);

		if (!inEditor) {
			botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
			botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			botplayTxt.scrollFactor.set();
			botplayTxt.borderSize = 1.25;
			botplayTxt.visible = cpuControlled;
			add(botplayTxt);
			if (ClientPrefs.downScroll) {
				botplayTxt.y = timeBarBG.y - 78;
			}
			hideInDemoMode.push(botplayTxt);

			practiceFailedTxt = new FlxText(400, timeBarBG.y + 105, FlxG.width - 800, "Failed!", 32);
			practiceFailedTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			practiceFailedTxt.scrollFactor.set();
			practiceFailedTxt.borderSize = 1.25;
			practiceFailedTxt.visible = practiceMode;
			practiceFailedTxt.alpha = 0;
			add(practiceFailedTxt);
			if (ClientPrefs.downScroll) {
				practiceFailedTxt.y = timeBarBG.y - 128;
			}
			hideInDemoMode.push(practiceFailedTxt);
		} else {
			sectionTxt = new FlxText(10, 580, FlxG.width - 20, "Section: 0", 20);
			sectionTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			sectionTxt.scrollFactor.set();
			sectionTxt.borderSize = 1.25;
			add(sectionTxt);

			beatTxt = new FlxText(10, sectionTxt.y + 30, FlxG.width - 20, "Beat: 0", 20);
			beatTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			beatTxt.scrollFactor.set();
			beatTxt.borderSize = 1.25;
			add(beatTxt);

			stepTxt = new FlxText(10, beatTxt.y + 30, FlxG.width - 20, "Step: 0", 20);
			stepTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			stepTxt.scrollFactor.set();
			stepTxt.borderSize = 1.25;
			add(stepTxt);

			var tipText:FlxText = new FlxText(10, FlxG.height - 24, 0, 'Press ESC to Go Back to Chart Editor', 16);
			tipText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			tipText.borderSize = 2;
			tipText.scrollFactor.set();
			add(tipText);
		}

		ratingTxtGroup = new FlxTypedGroup<FlxText>();
		ratingTxtGroup.visible = !ClientPrefs.hideHud && ClientPrefs.showRatings;
		hideInDemoMode.push(ratingTxtGroup);
		for (i in 0...5) {
			var ratingTxt = new FlxText(20, FlxG.height * 0.5 - 8 + (16 * (i - 2)), FlxG.width, "", 16);
			ratingTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			ratingTxt.scrollFactor.set();
			ratingTxtGroup.add(ratingTxt);
		}
		add(ratingTxtGroup);

		if (!inEditor) {
			strumLineNotes.cameras = [camHUD];
			grpNoteSplashes.cameras = [camHUD];
			underlayPlayer.cameras = [camHUD];
			scoreTxt.cameras = [camHUD];
			ratingTxtGroup.cameras = [camHUD];
			healthBar.cameras = [camHUD];
			healthBarBG.cameras = [camHUD];
			iconP1.cameras = [camHUD];
			iconP2.cameras = [camHUD];
			botplayTxt.cameras = [camHUD];
			practiceFailedTxt.cameras = [camHUD];
			timeBar.cameras = [camHUD];
			timeBarBG.cameras = [camHUD];
			timeTxt.cameras = [camHUD];
			if (showSongText) songTxt.cameras = [camHUD];
			doof.cameras = [camHUD];
		}

		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		// SONG SPECIFIC SCRIPTS
		if (!inEditor) {
			#if sys
			var filesPushed:Array<String> = [];
			var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/$curSong/')];

			for (folder in foldersToCheck)
			{
				if (FileSystem.exists(folder))
				{
					for (file in FileSystem.readDirectory(folder))
					{
						#if LUA_ALLOWED
						if (file.endsWith('.lua') && !filesPushed.contains(file))
						{
							luaArray.push(new FunkinLua(folder + file));
							filesPushed.push(file);
						}
						#end

						#if HSCRIPT_ALLOWED
						if (file.endsWith('.hscript') && !filesPushed.contains(file))
						{
							addHscript(folder + file);
							filesPushed.push(file);
						}
						#end
					}
				}
			}
			#else
			if (OpenFlAssets.exists(Paths.getPreloadPath('data/$curSong/$curSong.hscript'))) {
				addHscript(Paths.getPreloadPath('data/$curSong/$curSong.hscript'));
			}
			#end
		}
		#end
		
		if (!inEditor && isStoryMode && !seenCutscene)
		{
			switch (curSong)
			{
				case "monster":
					var whiteScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.WHITE);
					add(whiteScreen);
					whiteScreen.scrollFactor.set();
					whiteScreen.blend = ADD;
					camHUD.visible = false;
					snapCamFollowToPos(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					inCutscene = true;
					camMove = false;

					FlxTween.tween(whiteScreen, {alpha: 0}, 1, {
						startDelay: 0.1,
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							camHUD.visible = true;
							remove(whiteScreen);
							startCountdown();
						}
					});
					FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
					for (gf in gfGroup) {
						if (gf.animOffsets.exists('scared'))
							gf.playAnim('scared', true);
					}
					for (boyfriend in boyfriendGroup) {
						if (boyfriend.animOffsets.exists('scared'))
							boyfriend.playAnim('scared', true);
					}

				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween) {
							remove(blackScreen);
						}
					});
					if (ClientPrefs.gameQuality != 'Crappy') {
						camHUD.visible = false;
						inCutscene = true;
						camMove = false;

						FlxG.sound.play(Paths.sound('Lights_Turn_On'));
						snapCamFollowToPos(400, -2050);
						FlxG.camera.focusOn(camFollow);
						FlxG.camera.zoom = 1.5;

						new FlxTimer().start(0.8, function(tmr:FlxTimer)
						{
							camHUD.visible = true;
							remove(blackScreen);
							FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
								ease: FlxEase.quadInOut,
								onComplete: function(twn:FlxTween)
								{
									startCountdown();
								}
							});
						});
					} else {
						startCountdown();
					}
				case 'senpai' | 'roses' | 'thorns':
					if (curSong == 'roses') FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);

				case 'ugh' | 'guns' | 'stress':
					tankIntro();
					
				default:
					startCountdown();
			}
			seenCutscene = true;
		} else {
			startCountdown();
		}
		recalculateRating();

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if(ClientPrefs.hitsoundVolume > 0) precacheList.set('hitsound', 'sound');
		precacheList.set('missnote1', 'sound');
		precacheList.set('missnote2', 'sound');
		precacheList.set('missnote3', 'sound');
		
		if (PauseSubState.songName != null) {
			precacheList.set(PauseSubState.songName, 'music');
		} else if(ClientPrefs.pauseMusic != 'None') {
			precacheList.set(Paths.formatToSongPath(ClientPrefs.pauseMusic), 'music');
		}

		#if DISCORD_ALLOWED
		if (!inEditor) {
			// Updating Discord Rich Presence.
			DiscordClient.changePresence(detailsText, '$curSongDisplayName ($storyDifficultyText)', iconP2.getCharacter());
		}
		#end

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000 * playbackRate;

		#if HSCRIPT_ALLOWED
		postSetHscript();
		#end
		callOnScripts('onCreatePost', []);

		//cache note splashes
		var textureMap:Map<String, Bool> = new Map();
		precacheList.set('noteskins/default/base/noteSplashes', 'image');
		textureMap.set('noteskins/default/base/noteSplashes', true);
		for (note in unspawnNotes) {
			if (note.noteSplashTexture != null && note.noteSplashTexture.length > 0 && !note.noteSplashDisabled && !textureMap.exists(note.noteSplashTexture)) {
				var skin = getNoteFile(note.noteSplashTexture);
				precacheList.set(skin, 'image');
				textureMap.set(skin, true);
			}
		}

		super.create();

		Paths.clearUnusedMemory();

		for (key => type in precacheList)
		{
			switch(type)
			{
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);
			}
		}

		if (!inEditor) {
			CustomFadeTransition.nextCamera = camOther;
		}
	}

	function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			for (strumLine in strumLineNotes) {
				for (note in strumLine.holdsGroup) note.resizeByRatio(ratio);
			}
			for (note in unspawnNotes) note.resizeByRatio(ratio);
		}
		songSpeed = value;
		setOnScripts('scrollSpeed', songSpeed);
		return value;
	}

	public function addTextToDebug(text:String, color:FlxColor = FlxColor.WHITE) {
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});

		if (luaDebugGroup.members.length > 34) {
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup, color));
		#end
	}

	public function reloadHealthBarColors() {
		var healthColors = [dad.healthColorArray, boyfriend.healthColorArray];
		if (dadGroupFile != null) {
			healthColors[0] = dadGroupFile.healthbar_colors;
		}
		if (bfGroupFile != null) {
			healthColors[1] = bfGroupFile.healthbar_colors;
		}
		if (!opponentChart) {
			healthBar.createFilledBar(FlxColor.fromRGB(healthColors[0][0], healthColors[0][1], healthColors[0][2]),
			FlxColor.fromRGB(healthColors[1][0], healthColors[1][1], healthColors[1][2]));
		} else {
			healthBar.createFilledBar(FlxColor.fromRGB(healthColors[1][0], healthColors[1][1], healthColors[1][2]),
			FlxColor.fromRGB(healthColors[0][0], healthColors[0][1], healthColors[0][2]));
		}
		healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int, ?index:Int = 0) {
		switch(type) {
			case 0:
				if (!boyfriendMap.exists(newCharacter)) {
					var xOffset = 0.0;
					var yOffset = 0.0;
					if (bfGroupFile != null) {
						xOffset = (bfGroupFile.characters[index] != null ? bfGroupFile.characters[index].position[0] : 0) + bfGroupFile.position[0];
						yOffset = (bfGroupFile.characters[index] != null ? bfGroupFile.characters[index].position[1] : 0) + bfGroupFile.position[1];
					}
					var newBoyfriend = addCharacter(newCharacter, index, true, !opponentChart, null, xOffset, yOffset);
					boyfriendMap.set(newCharacter, newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					add(newBoyfriend);
					startCharacterScripts(newCharacter);
				}

			case 1:
				if (!dadMap.exists(newCharacter)) {
					var xOffset = 0.0;
					var yOffset = 0.0;
					if (dadGroupFile != null) {
						xOffset = (dadGroupFile.characters[index] != null ? dadGroupFile.characters[index].position[0] : 0) + dadGroupFile.position[0];
						yOffset = (dadGroupFile.characters[index] != null ? dadGroupFile.characters[index].position[1] : 0) + dadGroupFile.position[1];
					}
					var newDad = addCharacter(newCharacter, index, false, opponentChart, null, xOffset, yOffset);
					dadMap.set(newCharacter, newDad);
					newDad.alpha = 0.00001;
					add(newDad);
					startCharacterScripts(newCharacter);
				}

			case 2:
				if (!gfMap.exists(newCharacter)) {
					var xOffset = 0.0;
					var yOffset = 0.0;
					if (gfGroupFile != null) {
						xOffset = (gfGroupFile.characters[index] != null ? gfGroupFile.characters[index].position[0] : 0) + gfGroupFile.position[0];
						yOffset = (gfGroupFile.characters[index] != null ? gfGroupFile.characters[index].position[1] : 0) + gfGroupFile.position[1];
					}
					var newGf = addCharacter(newCharacter, index, false, false, null, xOffset, yOffset, 0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					newGf.alpha = 0.00001;
					add(newGf);
					startCharacterScripts(newCharacter);
				}
		}
	}

	#if HSCRIPT_ALLOWED
	public var hscriptMap:Map<String, FunkinHscript> = new Map();
	public function addHscript(path:String) {
		var parser = new ParserEx();
		try {
			var program = parser.parseString(Paths.getContent(path));
			var interp = new FunkinHscript(path);

			interp.execute(program);
			hscriptMap.set(path, interp);
			callHscript(path, 'onCreate', []);
		} catch (e) {
			trace(e);
			addTextToDebug('$e');
			addTextToDebug('Could not load script $path');
		}
	}

	function callHscript(name:String, func:String, args:Array<Dynamic>) {
		if (!hscriptMap.exists(name) || !hscriptMap.get(name).variables.exists(func)) {
			return FunkinLua.Function_Continue;
		}
		var hscript = hscriptMap.get(name);
		hscript.lastCalledFunction = func;
		var method = hscript.variables.get(func);
		var ret:Dynamic = null;
		switch(args.length) {
			default:
				ret = method();
			case 1:
				ret = method(args[0]);
			case 2:
				ret = method(args[0], args[1]);
			case 3:
				ret = method(args[0], args[1], args[2]);
			case 4:
				ret = method(args[0], args[1], args[2], args[3]);
			case 5:
				ret = method(args[0], args[1], args[2], args[3], args[4]);
			case 6:
				ret = method(args[0], args[1], args[2], args[3], args[4], args[5]);
			case 7:
				ret = method(args[0], args[1], args[2], args[3], args[4], args[5], args[6]);
		}
		if (ret != null && ret != FunkinLua.Function_Continue) {
			return ret;
		}
		return FunkinLua.Function_Continue;
	}

	function postSetHscript() {
		if (!inEditor) {
			setOnHscripts('boyfriend', boyfriend);
			setOnHscripts('dad', dad);
			setOnHscripts('gf', gf);
			setOnHscripts('strumLineNotes', strumLineNotes);
			setOnHscripts('dadStrums', strumLineNotes.members[0]);
			setOnHscripts('boyfriendStrums', strumLineNotes.members[1]);
			setOnHscripts('iconP1', iconP1);
			setOnHscripts('iconP2', iconP2);
			setOnHscripts('grpNoteSplashes', grpNoteSplashes);
			setOnHscripts('scoreTxt', scoreTxt);
			setOnHscripts('ratingTxtGroup', ratingTxtGroup);
			setOnHscripts('healthBar', healthBar);
			setOnHscripts('healthBarBG', healthBarBG);
			setOnHscripts('botplayTxt', botplayTxt);
			setOnHscripts('practiceFailedTxt', practiceFailedTxt);
			setOnHscripts('timeBar', timeBar);
			setOnHscripts('timeBarBG', timeBarBG);
			setOnHscripts('timeTxt', timeTxt);
			setOnHscripts('boyfriendGroup', boyfriendGroup);
			setOnHscripts('dadGroup', dadGroup);
			setOnHscripts('gfGroup', gfGroup);
			setOnHscripts('underlayPlayer', underlayPlayer);
			setOnHscripts('camGame', camGame);
			setOnHscripts('camHUD', camHUD);
			setOnHscripts('camOther', camOther);
			setOnHscripts('camFollow', camFollow);
			setOnHscripts('camFollowPos', camFollowPos);
			setOnHscripts('strumLine', strumLine);
			setOnHscripts('unspawnNotes', unspawnNotes);
			setOnHscripts('eventNotes', eventNotes);
			setOnHscripts('vocals', vocals);
			setOnHscripts('vocalsDad', vocalsDad);
		}
	}
	#end

	function setOnHscripts(variable:String, arg:Dynamic) {
		#if HSCRIPT_ALLOWED
		for (i in hscriptMap.keys()) {
			hscriptMap.get(i).variables.set(variable, arg);
		}
		#end
	}

	function startCharacterScripts(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = Paths.getPreloadPath('characters/$name.lua');
		if (Paths.exists(luaFile, TEXT)) {
			doPush = true;
		}
		
		if (doPush)
		{
			for (script in luaArray)
			{
				if (script.scriptName == luaFile) return;
			}
			luaArray.push(new FunkinLua(luaFile));
		}
		#end

		#if HSCRIPT_ALLOWED
		var doPush:Bool = false;
		var hscriptFile:String = Paths.getPreloadPath('characters/$name.hscript');
		if (Paths.exists(hscriptFile, TEXT)) {
			doPush = true;
		}
		
		if (doPush && !hscriptMap.exists(hscriptFile))
		{
			addHscript(hscriptFile);
		}
		#end
	}

	public function getLuaObject(tag:String, text:Bool = true):FlxSprite {
		if(modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if(text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		return null;
	}
	
	function startCharacterPos(char:Character, gfCheck:Bool = false) {
		if (gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	function addCharacter(name:String, index:Int = 0, flipped:Bool = false, isPlayer:Bool = false, ?group:FlxTypedSpriteGroup<Character>, xOffset:Float = 0, yOffset:Float = 0, scrollX:Float = 1, scrollY:Float = 1):Character {
		var char = new Character(0, 0, name, flipped);
		char.isPlayer = isPlayer;
		startCharacterPos(char);
		char.x += xOffset;
		char.y += yOffset;
		char.scrollFactor.set(scrollX, scrollY);
		if (group != null) {
			group.add(char);
		}
		return char;
	}

	function checkPicoSpeaker(char:Character) {
		if(char.curCharacter == 'pico-speaker' && ClientPrefs.gameQuality == 'Normal')
		{
			var firstTank:TankmenBG = new TankmenBG(20, 500, true);
			firstTank.resetShit(20, 600, true);
			firstTank.strumTime = 10;
			stage.tankmanRun.add(firstTank);

			for (i in 0...char.animationNotes.length)
			{
				if(FlxG.random.bool(16)) {
					var tankBih = stage.tankmanRun.recycle(TankmenBG);
					tankBih.strumTime = char.animationNotes[i][0];
					tankBih.resetShit(500, 200 + FlxG.random.int(50, 100), char.animationNotes[i][1] < 2);
					stage.tankmanRun.add(tankBih);
				}
			}
		}
	}

	#if VIDEOS_ALLOWED
	public var video:MP4Handler;
	#end
	public function startVideo(name:String):Void {
		#if VIDEOS_ALLOWED
		inCutscene = true;
		camMove = false;

		var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
			-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
		blackShit.scrollFactor.set();
		add(blackShit);
		var lastVisible:Bool = camHUD.visible;
		camHUD.visible = false;

		var filepath:String = Paths.video(name);
		#if sys
		if(!FileSystem.exists(filepath))
		#else
		if(!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd();
			return;
		}

		FlxG.sound.music.stop();
		video = new MP4Handler(); //note: not actually limited to mp4s
		video.playVideo(filepath);
		video.finishCallback = function()
		{
			startAndEnd();
			remove(blackShit);
			blackShit.destroy();
			camHUD.visible = lastVisible;
			video = null;
			return;
		}
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return;
		#end
	}

	public function startAndEnd() {
		if (endingSong)
			endSong();
		else if (startingSong)
			startCountdown();
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if (psychDialogue != null) return;

		if (dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			camMove = false;
			precacheList.set('dialogue', 'sound');
			precacheList.set('dialogueClose', 'sound');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if (endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if (endingSong) {
				endSong();
			} else {
				startCountdown();
			}
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		inCutscene = true;
		camMove = false;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		if (curSong == 'roses' || curSong == 'thorns')
		{
			remove(black);

			if (curSong == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					if (curSong == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	function tankIntro()
	{
		var cutsceneHandler:CutsceneHandler = new CutsceneHandler();

		var songName:String = Paths.formatToSongPath(SONG.song);
		dadGroup.alpha = 0.00001;
		camHUD.visible = false;
		inCutscene = true;

		var tankman:FlxSprite = new FlxSprite(-20, 320);
		tankman.frames = Paths.getSparrowAtlas('cutscenes/' + songName);
		tankman.antialiasing = ClientPrefs.globalAntialiasing;
		addBehindDad(tankman);
		cutsceneHandler.push(tankman);

		var tankman2:FlxSprite = new FlxSprite(16, 312);
		tankman2.antialiasing = ClientPrefs.globalAntialiasing;
		tankman2.alpha = 0.000001;
		cutsceneHandler.push(tankman2);
		var gfDance:FlxSprite = new FlxSprite(gf.x - 107, gf.y + 140);
		gfDance.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(gfDance);
		var gfCutscene:FlxSprite = new FlxSprite(gf.x - 104, gf.y + 122);
		gfCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(gfCutscene);
		var picoCutscene:FlxSprite = new FlxSprite(gf.x - 849, gf.y - 264);
		picoCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(picoCutscene);
		var boyfriendCutscene:FlxSprite = new FlxSprite(boyfriend.x + 5, boyfriend.y + 20);
		boyfriendCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(boyfriendCutscene);

		cutsceneHandler.finishCallback = function()
		{
			var timeForStuff:Float = Conductor.normalizedCrochet / 1000 * 4.5;
			FlxG.sound.music.fadeOut(timeForStuff);
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, timeForStuff, {ease: FlxEase.quadInOut});
			moveCamera(true);
			startCountdown();

			dadGroup.alpha = 1;
			camHUD.visible = true;
			boyfriend.animation.finishCallback = null;
			gf.animation.finishCallback = null;
			gf.dance();
		};

		camFollow.set(dad.x + 280, dad.y + 170);
		switch(songName)
		{
			case 'ugh':
				cutsceneHandler.endTime = 12;
				cutsceneHandler.music = 'DISTORTO';
				precacheList.set('killYou', 'sound');
				precacheList.set('bfBeep', 'sound');

				var wellWellWell:FlxSound = new FlxSound().loadEmbedded(Paths.sound('wellWellWell'));
				FlxG.sound.list.add(wellWellWell);

				tankman.animation.addByPrefix('wellWell', 'TANK TALK 1 P1', 24, false);
				tankman.animation.addByPrefix('killYou', 'TANK TALK 1 P2', 24, false);
				tankman.animation.play('wellWell', true);
				FlxG.camera.zoom *= 1.2;

				// Well well well, what do we got here?
				cutsceneHandler.timer(0.1, function()
				{
					wellWellWell.play(true);
				});

				// Move camera to BF
				cutsceneHandler.timer(3, function()
				{
					camFollow.x += 750;
					camFollow.y += 100;
				});

				// Beep!
				cutsceneHandler.timer(4.5, function()
				{
					boyfriend.playAnim('singUP', true);
					boyfriend.specialAnim = true;
					FlxG.sound.play(Paths.sound('bfBeep'));
				});

				// Move camera to Tankman
				cutsceneHandler.timer(6, function()
				{
					camFollow.x -= 750;
					camFollow.y -= 100;

					// We should just kill you but... what the hell, it's been a boring day... let's see what you've got!
					tankman.animation.play('killYou', true);
					FlxG.sound.play(Paths.sound('killYou'));
				});

			case 'guns':
				cutsceneHandler.endTime = 11.5;
				cutsceneHandler.music = 'DISTORTO';
				tankman.x += 40;
				tankman.y += 10;

				var tightBars:FlxSound = new FlxSound().loadEmbedded(Paths.sound('tankSong2'));
				FlxG.sound.list.add(tightBars);

				tankman.animation.addByPrefix('tightBars', 'TANK TALK 2', 24, false);
				tankman.animation.play('tightBars', true);
				boyfriend.animation.curAnim.finish();

				cutsceneHandler.onStart = function()
				{
					tightBars.play(true);
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 4, {ease: FlxEase.quadInOut});
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2 * 1.2}, 0.5, {ease: FlxEase.quadInOut, startDelay: 4});
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 1, {ease: FlxEase.quadInOut, startDelay: 4.5});
				};

				cutsceneHandler.timer(4, function()
				{
					gf.playAnim('sad', true);
					gf.animation.finishCallback = function(name:String)
					{
						gf.playAnim('sad', true);
					};
				});

			case 'stress':
				cutsceneHandler.endTime = 35.5;
				tankman.x -= 54;
				tankman.y -= 14;
				gfGroup.alpha = 0.00001;
				boyfriendGroup.alpha = 0.00001;
				camFollow.set(dad.x + 400, dad.y + 170);
				FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});
				stage.foreground.forEach(function(spr:FlxBasic)
				{
					var sprite:Dynamic = spr;
					var sprite:BGSprite = sprite;
					sprite.y += 100;
				});

				tankman2.frames = Paths.getSparrowAtlas('cutscenes/stress2');
				addBehindDad(tankman2);

				if (ClientPrefs.gameQuality == 'Normal')
				{
					gfDance.frames = Paths.getSparrowAtlas('characters/gfTankmen');
					gfDance.animation.addByPrefix('dance', 'GF Dancing at Gunpoint', 24, true);
					gfDance.animation.play('dance', true);
					addBehindGF(gfDance);
				}

				gfCutscene.frames = Paths.getSparrowAtlas('cutscenes/stressGF');
				gfCutscene.animation.addByPrefix('dieBitch', 'GF STARTS TO TURN PART 1', 24, false);
				gfCutscene.animation.addByPrefix('getRektLmao', 'GF STARTS TO TURN PART 2', 24, false);
				gfCutscene.animation.play('dieBitch', true);
				gfCutscene.animation.pause();
				addBehindGF(gfCutscene);
				if (ClientPrefs.gameQuality == 'Normal')
				{
					gfCutscene.alpha = 0.00001;
				}

				picoCutscene.frames = AtlasFrameMaker.construct('cutscenes/stressPico');
				picoCutscene.animation.addByPrefix('anim', 'Pico Badass', 24, false);
				addBehindGF(picoCutscene);
				picoCutscene.alpha = 0.00001;

				boyfriendCutscene.frames = Paths.getSparrowAtlas('characters/BOYFRIEND');
				boyfriendCutscene.animation.addByPrefix('idle', 'BF idle dance', 24, false);
				boyfriendCutscene.animation.play('idle', true);
				boyfriendCutscene.animation.curAnim.finish();
				addBehindBF(boyfriendCutscene);

				var cutsceneSnd:FlxSound = new FlxSound().loadEmbedded(Paths.sound('stressCutscene'));
				FlxG.sound.list.add(cutsceneSnd);

				tankman.animation.addByPrefix('godEffingDamnIt', 'TANK TALK 3', 24, false);
				tankman.animation.play('godEffingDamnIt', true);

				var calledTimes:Int = 0;
				var zoomBack:Void->Void = function()
				{
					var camPosX:Float = 630;
					var camPosY:Float = 425;
					camFollow.set(camPosX, camPosY);
					camFollowPos.setPosition(camPosX, camPosY);
					FlxG.camera.zoom = 0.8;
					cameraSpeed = 1;

					calledTimes++;
					if (calledTimes > 1)
					{
						stage.foreground.forEach(function(spr:FlxBasic)
						{
							var sprite:Dynamic = spr;
							var sprite:BGSprite = sprite;
							sprite.y -= 100;
						});
					}
				}

				cutsceneHandler.onStart = function()
				{
					cutsceneSnd.play(true);
				};

				cutsceneHandler.timer(15.2, function()
				{
					FlxTween.tween(camFollow, {x: 650, y: 300}, 1, {ease: FlxEase.sineOut});
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 2.25, {ease: FlxEase.quadInOut});

					gfDance.visible = false;
					gfCutscene.alpha = 1;
					gfCutscene.animation.play('dieBitch', true);
					gfCutscene.animation.finishCallback = function(name:String)
					{
						if(name == 'dieBitch') //Next part
						{
							gfCutscene.animation.play('getRektLmao', true);
							gfCutscene.offset.set(224, 445);
						}
						else
						{
							gfCutscene.visible = false;
							picoCutscene.alpha = 1;
							picoCutscene.animation.play('anim', true);

							boyfriendGroup.alpha = 1;
							boyfriendCutscene.visible = false;
							boyfriend.playAnim('bfCatch', true);
							boyfriend.animation.finishCallback = function(name:String)
							{
								if(name != 'idle')
								{
									boyfriend.playAnim('idle', true);
									boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
								}
							};

							picoCutscene.animation.finishCallback = function(name:String)
							{
								picoCutscene.visible = false;
								gfGroup.alpha = 1;
								picoCutscene.animation.finishCallback = null;
							};
							gfCutscene.animation.finishCallback = null;
						}
					};
				});

				cutsceneHandler.timer(17.5, function()
				{
					zoomBack();
				});

				cutsceneHandler.timer(19.5, function()
				{
					tankman2.animation.addByPrefix('lookWhoItIs', 'TANK TALK 3', 24, false);
					tankman2.animation.play('lookWhoItIs', true);
					tankman2.alpha = 1;
					tankman.visible = false;
				});

				cutsceneHandler.timer(20, function()
				{
					camFollow.set(dad.x + 500, dad.y + 170);
				});

				cutsceneHandler.timer(31.2, function()
				{
					boyfriend.playAnim('singUPmiss', true);
					boyfriend.animation.finishCallback = function(name:String)
					{
						if (name == 'singUPmiss')
						{
							boyfriend.playAnim('idle', true);
							boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
						}
					};

					camFollow.set(boyfriend.x + 280, boyfriend.y + 200);
					cameraSpeed = 12;
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 0.25, {ease: FlxEase.elasticOut});
				});

				cutsceneHandler.timer(32.2, function()
				{
					zoomBack();
				});
		}
	}

	var startTimer:FlxTimer;
	var endingTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;
	public var introSoundsSuffix = '';

	public function startCountdown():Void
	{
		if (startedCountdown) {
			callOnScripts('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		camMove = true;
		var ret:Dynamic = callOnScripts('onStartCountdown', [], false);
		if (ret != FunkinLua.Function_Stop) {
			FlxG.timeScale = playbackRate;
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			switchKeys(0, SONG.dadKeyAmount, false);
			switchKeys(1, SONG.boyfriendKeyAmount, true);

			startedCountdown = true;
			if (inEditor) return;

			Conductor.songPosition = 0;
			Conductor.songPosition -= Conductor.normalizedCrochet * 5;
			setOnScripts('startedCountdown', true);
			callOnScripts('onCountdownStarted', []);

			var swagCounter:Int = 0;

			if(startOnTime < 0) startOnTime = 0;

			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - noteKillOffset);
				return;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return;
			}
			startTimer = new FlxTimer().start(Conductor.normalizedCrochet / 1000, function(tmr:FlxTimer)
			{
				if (!inEditor) {
					if (swagCounter < 4) {
						var chars = [boyfriendGroup, dadGroup];
						for (group in chars) {
							for (char in group) {
								if (char.danceEveryNumBeats > 0 && tmr.loopsLeft % Math.round(char.danceEveryNumBeats) == 0 && char.animation.curAnim != null && !char.animation.curAnim.name.startsWith("sing") && !char.specialAnim)
								{
									char.dance();
								}
							}
						}

						stage.onCountdownTick();
					}
				}

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3$introSoundsSuffix'), 0.6);
					case 1:
						countdownReady = new FlxSprite().loadGraphic(Paths.image(getUIFile('ready')));
						if (!inEditor) countdownReady.cameras = [camHUD];
						countdownReady.scrollFactor.set();
						countdownReady.updateHitbox();

						if (SONG.skinModifier.endsWith('pixel'))
							countdownReady.setGraphicSize(Std.int(countdownReady.width * daPixelZoom));

						countdownReady.screenCenter();
						countdownReady.antialiasing = ClientPrefs.globalAntialiasing && !SONG.skinModifier.endsWith('pixel');
						insert(members.indexOf(strumLineNotes), countdownReady);
						FlxTween.tween(countdownReady, {alpha: 0}, Conductor.normalizedCrochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownReady);
								countdownReady.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro2$introSoundsSuffix'), 0.6);
					case 2:
						countdownSet = new FlxSprite().loadGraphic(Paths.image(getUIFile('set')));
						if (!inEditor) countdownSet.cameras = [camHUD];
						countdownSet.scrollFactor.set();

						if (SONG.skinModifier.endsWith('pixel'))
							countdownSet.setGraphicSize(Std.int(countdownSet.width * daPixelZoom));

						countdownSet.screenCenter();
						countdownSet.antialiasing = ClientPrefs.globalAntialiasing && !SONG.skinModifier.endsWith('pixel');
						insert(members.indexOf(strumLineNotes), countdownSet);
						FlxTween.tween(countdownSet, {alpha: 0}, Conductor.normalizedCrochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownSet);
								countdownSet.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro1$introSoundsSuffix'), 0.6);
					case 3:
						countdownGo = new FlxSprite().loadGraphic(Paths.image(getUIFile('go')));
						if (!inEditor) countdownGo.cameras = [camHUD];
						countdownGo.scrollFactor.set();

						if (SONG.skinModifier.endsWith('pixel'))
							countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));

						countdownGo.updateHitbox();

						countdownGo.screenCenter();
						countdownGo.antialiasing = ClientPrefs.globalAntialiasing && !SONG.skinModifier.endsWith('pixel');
						insert(members.indexOf(strumLineNotes), countdownGo);
						FlxTween.tween(countdownGo, {alpha: 0}, Conductor.normalizedCrochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownGo);
								countdownGo.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('introGo$introSoundsSuffix'), 0.6);
				}

				callOnScripts('onCountdownTick', [swagCounter]);

				swagCounter += 1;
			}, 5);
		}
	}

	public function addBehindGF(obj:FlxObject)
	{
		stage.background.add(obj);
	}
	public function addBehindBF(obj:FlxObject)
	{
		stage.overDad.add(obj);
	}
	public function addBehindDad(obj:FlxObject)
	{
		stage.overGF.add(obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - noteKillOffset < time)
			{
				if (daNote.isOpponent && !daNote.ignoreNote) {
					camZooming = true;
					camBop = true;
				}
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		for (strumLine in strumLineNotes) {
			i = strumLine.allNotes.length - 1;
			while (i >= 0) {
				var daNote:Note = strumLine.allNotes.members[i];
				if(daNote.strumTime - noteKillOffset < time)
				{
					if (daNote.isOpponent && !daNote.ignoreNote) {
						camZooming = true;
						camBop = true;
					}
					daNote.active = false;
					daNote.visible = false;
					daNote.ignoreNote = true;

					daNote.kill();
					strumLine.allNotes.remove(daNote, true);
					var daGroup = (daNote.isSustainNote ? strumLine.holdsGroup : strumLine.notesGroup);
					daGroup.remove(daNote, true);
					daNote.destroy();
				}
				--i;
			}
		}
	}

	public function updateScore(miss:Bool = false)
	{
		if (ClientPrefs.showRatings) {
			scoreTxt.text = 'Score: ' + songScore + ' | Rating: ' + ratingName;
		} else {
			scoreTxt.text = 'Score: ' + songScore + ' | Fails: ' + songMisses + ' | Rating: ' + ratingName;
		}
		if(ratingName != '?')
			scoreTxt.text += ' (' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%)' + ' - ' + ratingFC;

		if (inEditor)
			scoreTxt.text = 'Hits: $songHits';

		if(ClientPrefs.scoreZoom && !miss && !cpuControlled)
		{
			if(scoreTxtTween != null) {
				scoreTxtTween.cancel();
			}
			scoreTxt.scale.x = 1.075;
			scoreTxt.scale.y = 1.075;
			scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween) {
					scoreTxtTween = null;
				}
			});
		}
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();
		vocalsDad.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.play();

		if (time <= vocals.length)
		{
			vocals.time = time;
			vocals.play();
		}
		if (time <= vocalsDad.length)
		{
			vocalsDad.time = time;
			vocalsDad.play();
		}
		setSongPitch();
		Conductor.songPosition = time;

		updateCurStep();
		Conductor.getLastBPM(SONG, curStep);
	}

	function startNextDialogue() {
		dialogueCount++;
		callOnScripts('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue() {
		callOnScripts('onSkipDialogue', [dialogueCount]);
	}

	function startSong():Void
	{
		startingSong = false;

		FlxG.sound.playMusic(Paths.inst(curSong, CoolUtil.getDifficultyFilePath()), 1, false);
		if (inEditor) FlxG.sound.music.time = startPos;
		if (playbackRate == 1) FlxG.sound.music.onComplete = onSongComplete;
		vocals.play();
		if (inEditor) vocals.time = startPos;
		vocalsDad.play();
		if (inEditor) vocalsDad.time = startPos;

		if(startOnTime > 0)
		{
			setSongTime(startOnTime - noteKillOffset);
		}
		startOnTime = 0;

		setSongPitch();

		if (paused) {
			FlxG.sound.music.pause();
			vocals.pause();
			vocalsDad.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		if (!inEditor) {
			FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
			if (showSongText) {
				FlxTween.tween(songTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut, onComplete: function(twn:FlxTween) {
					FlxTween.tween(songTxt, {alpha: 0}, 0.5, {ease: FlxEase.circOut, startDelay: 3});
					FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut, startDelay: 3});
				}});
			} else {
				FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
			}
		
			#if DISCORD_ALLOWED
			// Updating Discord Rich Presence (with Time Left)
			DiscordClient.changePresence(detailsText, '$curSongDisplayName ($storyDifficultyText)', iconP2.getCharacter(), true, songLength / playbackRate);
			#end
		}
		setOnScripts('songLength', songLength);
		callOnScripts('onSongStart', []);
	}

	private var noteTypeMap:Map<String, Bool> = new Map();
	private var eventPushedMap:Map<String, Bool> = new Map();
	private function generateSong():Void
	{
		if (!inEditor) {
			songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

			switch(songSpeedType)
			{
				case "multiplicative":
					songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) / playbackRate;
				case "constant":
					songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
			}
		} else {
			songSpeed = SONG.speed;
		}
		songSpeed = CoolUtil.boundTo(songSpeed, 0.1, 10);

		if (SONG.needsVoices) {
			vocals = new FlxSound().loadEmbedded(Paths.voices(curSong, CoolUtil.getDifficultyFilePath()));

			vocalsDad = new FlxSound();
			var file = Paths.voicesDad(SONG.song, CoolUtil.getDifficultyFilePath());
			if (file != null) {
				foundDadVocals = true;
				vocalsDad.loadEmbedded(file);
			}
		} else {
			vocals = new FlxSound();
			vocalsDad = new FlxSound();
		}

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(vocalsDad);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(curSong, CoolUtil.getDifficultyFilePath())));

		unspawnNotes = Song.generateNotes(SONG, strumLineNotes.members[0], strumLineNotes.members[1]);

		for (swagNote in unspawnNotes) {
			if (!noteTypeMap.exists(swagNote.noteType)) {
				noteTypeMap.set(swagNote.noteType, true);
			}
		}

		eventNotes = Song.generateEventNotes(SONG, eventPushed, eventNoteEarlyTrigger);

		if (unspawnNotes.length > 1) {
			unspawnNotes.sort(sortByShit);
		}
		if (eventNotes.length > 1) {
			eventNotes.sort(sortByTime);
			checkEventNote();
		}
		generatedMusic = true;
	}

	function eventPushed(event:EventNote) {
		switch(event.event) {
			case 'Change Character':
				if (inEditor) return;
				var charData:Array<String> = event.value1.split(',');
				var charType:Int = 0;
				var index = 0;
				switch(charData[0].toLowerCase()) {
					case 'gf' | 'girlfriend' | '2':
						charType = 2;
					case 'dad' | 'opponent' | '1':
						charType = 1;
				}
				if (charData[1] != null) index = Std.parseInt(charData[1]);

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType, index);

			case 'Dadbattle Spotlight':
				if (inEditor) return;
				dadbattleBlack = new BGSprite(null, -800, -400, 0, 0);
				dadbattleBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				dadbattleBlack.alpha = 0.25;
				dadbattleBlack.visible = false;
				stage.foreground.add(dadbattleBlack);

				dadbattleLight = new BGSprite('spotlight', 400, -400);
				dadbattleLight.alpha = 0.375;
				dadbattleLight.blend = ADD;
				dadbattleLight.visible = false;

				dadbattleSmokes = new FlxSpriteGroup();
				dadbattleSmokes.alpha = 0.7;
				dadbattleSmokes.blend = ADD;
				dadbattleSmokes.visible = false;
				stage.foreground.add(dadbattleLight);
				stage.foreground.add(dadbattleSmokes);

				var offsetX = 200;
				var smoke:BGSprite = new BGSprite('smoke', -1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(15, 22);
				smoke.active = true;
				dadbattleSmokes.add(smoke);
				var smoke:BGSprite = new BGSprite('smoke', 1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(-15, -22);
				smoke.active = true;
				smoke.flipX = true;
				dadbattleSmokes.add(smoke);

			case 'Philly Glow':
				if (inEditor) return;
				if (curStage == 'philly' && ClientPrefs.gameQuality != 'Crappy') {
					blammedLightsBlack = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					blammedLightsBlack.visible = false;
					stage.background.insert(stage.background.members.indexOf(stage.phillyStreet), blammedLightsBlack);

					phillyWindowEvent = new BGSprite('philly/window', stage.phillyWindow.x, stage.phillyWindow.y, 0.3, 0.3);
					phillyWindowEvent.setGraphicSize(Std.int(phillyWindowEvent.width * 0.85));
					phillyWindowEvent.updateHitbox();
					phillyWindowEvent.visible = false;
					stage.background.insert(stage.background.members.indexOf(blammedLightsBlack) + 1, phillyWindowEvent);

					phillyGlowGradient = new PhillyGlow.PhillyGlowGradient(-400, 225); //This shit was refusing to properly load FlxGradient so fuck it
					phillyGlowGradient.visible = false;
					stage.background.insert(stage.background.members.indexOf(blammedLightsBlack) + 1, phillyGlowGradient);
					if(!ClientPrefs.flashing) phillyGlowGradient.intendedAlpha = 0.7;

					precacheList.set('philly/particle', 'image'); //precache particle image
					phillyGlowParticles = new FlxTypedGroup<PhillyGlow.PhillyGlowParticle>();
					phillyGlowParticles.visible = false;
					stage.background.insert(stage.background.members.indexOf(phillyGlowGradient) + 1, phillyGlowParticles);
				}
		}

		if (!eventPushedMap.exists(event.event)) {
			eventPushedMap.set(event.event, true);
		}

		callOnScripts('eventPushed', [event.event, event.strumTime, event.value1, event.value2]);
	}

	function eventNoteEarlyTrigger(event:EventNote):Float {
		var returnedValue:Dynamic = callOnScripts('eventEarlyTrigger', [event.event]);
		if (returnedValue != 0) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(id:Int = 0, keys:Int = 4, isBoyfriend:Bool = false):Void
	{
		while (id >= strumMaps.length) {
			strumMaps.push(new Map());
		}
		var isPlayer = ((id == 0 && opponentChart) || (id == 1 && !opponentChart));
		var strumX:Float = ClientPrefs.middleScroll ? -320 : 0;
		if ((isBoyfriend && !ClientPrefs.middleScroll) || (ClientPrefs.middleScroll && isBoyfriend == !opponentChart))
			strumX += FlxG.width / 2;

		var strumGroup = new StrumLine(strumX, strumLine.y, keys, isPlayer, (!isStoryMode && !inEditor && !skipArrowStartTween), true);
		strumGroup.botPlay = (cpuControlled || !isPlayer);
		strumGroup.isBoyfriend = isBoyfriend;

		strumMaps[id].set(keys, strumGroup);

		trace('generated arrows: $id, $keys, $isBoyfriend');
	}

	var keybindTweenGroup:Map<FlxSprite, FlxTween> = new Map();
	function showKeybindReminders() {
		if (ClientPrefs.keybindReminders && !cpuControlled) {
			for (obj in keybindGroup) {
				obj.kill();
				keybindGroup.remove(obj);
				obj.destroy();
			}
			for (i in 0...playerKeys) {
				var keybinds = keysArray[i];
				for (j in 0...keybinds.length) {
					var daStrum = playerStrums.receptors.members[i];
					var txt = new AttachedFlxText(daStrum.x, daStrum.y, daStrum.width, InputFormatter.getKeyName(keybinds[j]), Std.int(72 * daStrum.noteSize));
					txt.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
					txt.borderSize = 1;
					txt.yAdd = daStrum.height + (72 * daStrum.noteSize * j);
					txt.copyAlpha = false;
					if (!inEditor) txt.cameras = [camHUD];
					keybindGroup.add(txt);
					txt.sprTracker = daStrum;

					var offset = Conductor.songPosition < 0 ? Conductor.normalizedCrochet * Conductor.timeSignature[0] * 0.001 : 0;
					keybindTweenGroup.set(txt, FlxTween.tween(txt, {alpha: 0}, 0.5, {startDelay: (offset + 3) * playbackRate, onComplete: function(twn) {
						keybindTweenGroup.remove(txt);
						txt.kill();
						keybindGroup.remove(txt);
						txt.destroy();
					}}));
				}
			}
		}
	}

	function resetUnderlay(underlay:FlxSprite, strums:FlxTypedSpriteGroup<StrumNote>) {
		if (ClientPrefs.underlayFull) {
			underlay.makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
			underlay.screenCenter();
		} else {
			underlay.makeGraphic(Std.int(strums.width), FlxG.height * 2, FlxColor.BLACK);
			underlay.x = strums.members[0].x;
		}
		underlay.visible = true;
	}

	function setKeysArray(keys:Int = 4) {
		keysArray = [];
		for (i in 0...keys) {
			keysArray.push(ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note${keys}_$i')));
		}

		// For the "Just the Two of Us" achievement
		keysPressed = [];
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			FlxG.timeScale = 1;

			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				vocalsDad.pause();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (endingTimer != null && !endingTimer.finished)
				endingTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			for (txt in keybindGroup) {
				keybindTweenGroup.get(txt).active = false;
			}

			stage.onOpenSubState();

			var chars = [boyfriendGroup, gfGroup, dadGroup];
			for (i in 0...chars.length) {
				for (char in chars[i]) {
					if (char.colorTween != null) {
						char.colorTween.active = false;
					}
				}
			}

			for (tween in modchartTweens) {
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			FlxG.timeScale = playbackRate;

			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			if (endingTimer != null && !endingTimer.finished)
				endingTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;

			for (txt in keybindGroup) {
				keybindTweenGroup.get(txt).active = true;
			}
			
			stage.onCloseSubState();

			var chars = [boyfriendGroup, gfGroup, dadGroup];
			for (i in 0...chars.length) {
				for (char in chars[i]) {
					if (char.colorTween != null) {
						char.colorTween.active = true;
					}
				}
			}
			
			for (tween in modchartTweens) {
				tween.active = true;
			}
			for (timer in modchartTimers) {
				timer.active = true;
			}
			paused = false;
			persistentUpdate = true;
			callOnScripts('onResume', []);

			#if DISCORD_ALLOWED
			if (startTimer != null && startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, '$curSongDisplayName ($storyDifficultyText)', iconP2.getCharacter(), true, (songLength - Conductor.songPosition) / playbackRate - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, '$curSongDisplayName ($storyDifficultyText)', iconP2.getCharacter());
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		if (!isDead && !paused)
		{
			if (FlxG.sound.music != null && !startingSong && !endingSong)
			{
				resyncVocals();
			}
			#if DISCORD_ALLOWED
			if (!inEditor) {
				if (Conductor.songPosition > 0.0)
				{
					DiscordClient.changePresence(detailsText, '$curSongDisplayName ($storyDifficultyText)', iconP2.getCharacter(), true, (songLength - Conductor.songPosition) / playbackRate - ClientPrefs.noteOffset);
				}
				else
				{
					DiscordClient.changePresence(detailsText, '$curSongDisplayName ($storyDifficultyText)', iconP2.getCharacter());
				}
			}
			#end
		}

		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		if (ClientPrefs.focusLostPause && !isDead && !paused && !inEditor && startedCountdown && canPause) {
			openPauseMenu(false);
			FlxG.sound.music.pause();
			vocals.pause();
			vocalsDad.pause();
		}

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if (FlxG.sound.music == null || vocals == null || startingSong || endingSong || endingTimer != null) return;

		if (playbackRate < 1) FlxG.sound.music.pause();
		vocals.pause();
		vocalsDad.pause();

		if (playbackRate >= 1) {
			FlxG.sound.music.play();
			Conductor.songPosition = FlxG.sound.music.time;
		} else {
			FlxG.sound.music.time = Conductor.songPosition;
			FlxG.sound.music.play();
		}
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			vocals.play();
		}
		if (Conductor.songPosition <= vocalsDad.length)
		{
			vocalsDad.time = Conductor.songPosition;
			vocalsDad.play();
		}

		setSongPitch();
	}

	function setSongPitch() {
		#if cpp
		if (playbackRate != 1 && !startingSong && !endingSong && !transitioning) {
			@:privateAccess
			{
				var audio = [FlxG.sound.music, vocals, vocalsDad];
				for (sound in modchartSounds) {
					audio.push(sound);
				}
				for (i in audio) {
					if (i != null && i.playing && i._channel != null && i._channel.__source != null && i._channel.__source.__backend != null && i._channel.__source.__backend.handle != null) {
						AL.sourcef(i._channel.__source.__backend.handle, AL.PITCH, playbackRate);
					}
				}
			}
		}
		#end
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	override public function update(elapsed:Float)
	{
		callOnScripts('onUpdate', [elapsed]);

		if (!inEditor) {
			if (FlxG.sound.music != null && FlxG.sound.music.playing) {
				setSongPitch();
			}
			
			if (playbackRate != 1 && generatedMusic && startedCountdown && !endingSong && !transitioning && FlxG.sound.music != null && FlxG.sound.music.length - Conductor.songPosition <= 20)
			{
				Conductor.songPosition = FlxG.sound.music.length;
				onSongComplete();
			}

			if (FlxG.keys.justPressed.NINE)
			{
				iconP1.swapOldIcon();
			}

			stage.onUpdate();

			if(phillyGlowParticles != null)
			{
				var i:Int = phillyGlowParticles.members.length-1;
				while (i > 0)
				{
					var particle = phillyGlowParticles.members[i];
					if(particle.alpha < 0)
					{
						particle.kill();
						phillyGlowParticles.remove(particle, true);
						particle.destroy();
					}
					--i;
				}
			}

			if (camMove) {
				var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
				camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			}
			if (!inCutscene) {
				if (!startingSong && !endingSong && boyfriend.animation.curAnim != null && (boyfriend.animation.curAnim.name.startsWith('idle') || boyfriend.animation.curAnim.name.startsWith('dance'))) {
					boyfriendIdleTime += elapsed;
					if (boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
						boyfriendIdled = true;
					}
				} else {
					boyfriendIdleTime = 0;
				}
			}
		} else {
			if (FlxG.keys.justPressed.ESCAPE)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				vocalsDad.pause();
				LoadingState.loadAndSwitchState(new editors.ChartingState());
			}
		}

		super.update(elapsed);

		setOnScripts('curDecStep', curDecStep);
		setOnScripts('curDecBeat', curDecBeat);

		if (!inEditor) {
			if (startedCountdown && generatedMusic && SONG.notes[curSection] != null && !endingSong && !isCameraOnForcedPos)
			{
				moveCameraSection();
			}

			if (botplayTxt.visible) {
				botplaySine += 180 * elapsed;
				botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
			}

			if (controls.PAUSE && startedCountdown && canPause)
			{
				var ret:Dynamic = callOnScripts('onPause', [], false);
				if (ret != FunkinLua.Function_Stop) {
					openPauseMenu();
				}
			}

			if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
			{
				var ret:Dynamic = callOnScripts('onOpenChartEditor', [], false);
				if (ret != FunkinLua.Function_Stop) {
					openChartEditor();
				}
			}

			if (ClientPrefs.smoothHealth) {
				shownHealth = FlxMath.lerp(shownHealth, health, CoolUtil.boundTo(elapsed * 7, 0, 1));
			} else {
				shownHealth = health;
			}

			var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
			iconP1.scale.set(mult, mult);
			iconP1.updateHitbox();

			var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
			iconP2.scale.set(mult, mult);
			iconP2.updateHitbox();

			var iconOffset:Int = 26;
			var division:Float = 1 / healthBar.numDivisions;

			if (!opponentChart) {
				iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, healthBar.numDivisions, 0) * division)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
				iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, healthBar.numDivisions, 0) * division)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
			} else {
				iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 0, healthBar.numDivisions) * division)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
				iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 0, healthBar.numDivisions) * division)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
			}

			if (health > 2)
				health = 2;
			else if (health < 0)
				health = 0;

			var stupidIcons:Array<HealthIcon> = [iconP1, iconP2];
			if (opponentChart) stupidIcons = [iconP2, iconP1];
			if (healthBar.percent < 20) {
				stupidIcons[0].animation.play('losing');
				stupidIcons[1].animation.play('winning');
			} else if (healthBar.percent > 80) {
				stupidIcons[0].animation.play('winning');
				stupidIcons[1].animation.play('losing');
			} else {
				stupidIcons[0].animation.play('normal');
				stupidIcons[1].animation.play('normal');
			}

			#if desktop
			if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene) {
				var ret:Dynamic = callOnScripts('onOpenCharacterEditor', [], false);
				if (ret != FunkinLua.Function_Stop) {
					FlxG.timeScale = 1;
					persistentUpdate = false;
					paused = true;
					cancelMusicFadeTween();
					SONG = originalSong;
					MusicBeatState.switchState(new CharacterEditorState(dad.curCharacter));
				}
			}
			#end
		}

		if (startingSong)
		{
			if (!inEditor) {
				if (startedCountdown)
				{
					Conductor.songPosition += FlxG.elapsed * 1000;
					if (Conductor.songPosition >= 0) {
						startSong();
					}
				}
			} else {
				timerToStart -= elapsed * 1000;
				Conductor.songPosition = startPos - timerToStart;
				if(timerToStart < 0) {
					startSong();
				}
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused && !inEditor)
			{
				if (updateTime) {
					var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
					if(curTime < 0) curTime = 0;
					songPercent = (curTime / songLength);

					if(ClientPrefs.timeBarType == 'Percentage Passed') { //geometry dash moment
						timeTxt.text = Math.floor(songPercent * 100) + '%';
					} else if (ClientPrefs.timeBarType != 'Song Name') {
						var songCalc:Float = (songLength - curTime) / playbackRate;
						if(ClientPrefs.timeBarType == 'Time Elapsed') songCalc = curTime / playbackRate;

						var secondsTotal:Int = Math.floor(songCalc / 1000);
						if (secondsTotal < 0) secondsTotal = 0;

						timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
					}
				}
			}
		}

		if (!inEditor) {
			if (camZooming)
			{
				FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay), 0, 1));
				camHUD.zoom = FlxMath.lerp(defaultCamHudZoom, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay), 0, 1));
			}

			FlxG.watch.addQuick("secShit", curSection);
			FlxG.watch.addQuick("beatShit", curBeat);
			FlxG.watch.addQuick("stepShit", curStep);

			// RESET = Quick Game Over Screen
			if (!ClientPrefs.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
			{
				health = 0;
				trace("RESET = True");
			}
			doDeathCheck();
		}

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;
			if(!inEditor) time /= camHUD.zoom;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];

				//Change the selected strumline here!
				var strumID = (dunceNote.isOpponent ? 0 : 1);

				strumLineNotes.members[strumID].push(dunceNote);
				dunceNote.spawned = true;

				callOnScripts('onSpawnNote', [strumLineNotes.members[strumID].allNotes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote, dunceNote.characters]);

				unspawnNotes.splice(unspawnNotes.indexOf(dunceNote), 1);
			}
		}

		if (generatedMusic)
		{
			if (!inCutscene) {
				if (!inEditor && controls.gamepadsAdded.length < 1) {
					for (char in playerChar) {
						var keyPressed:Bool = FlxG.keys.anyPressed(char.keysPressed);
						if (!keyPressed && char.holdTimer > Conductor.normalizedStepCrochet * 0.0011 * char.singDuration && char.animation.curAnim != null && char.animation.curAnim.name.startsWith('sing') && !char.animation.curAnim.name.endsWith('miss')) {
							char.dance();
						}
					}
				}
			}
			
			noteFunctions();
		}
		
		for (i in 0...ratingTxtGroup.members.length) {
			var rating = ratingTxtGroup.members[i];
			if (i < ratingsData.length) {
				rating.text = '${ratingsData[i].displayName}: ${Reflect.field(this, ratingsData[i].counter)}';
			} else {
				rating.text = 'Fails: $songMisses';
			}
		}

		if (inEditor) {
			scoreTxt.text = 'Hits: $songHits';
			sectionTxt.text = 'Section: $curSection';
			beatTxt.text = 'Beat: $curBeat';
			stepTxt.text = 'Step: $curStep';
		} else {
			if (practiceFailed) {
				practiceFailedSine += 180 * elapsed;
				practiceFailedTxt.alpha = 1 - Math.sin((Math.PI * practiceFailedSine) / 180);
			} else {
				practiceFailedTxt.alpha = 0;
			}
		}

		if (!ClientPrefs.underlayFull) {
			if (playerStrums.length > 0) underlayPlayer.x = playerStrums.receptors.members[0].x;
		}
		
		#if debug
		if (!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE && !inEditor) {
				killNotes();
				if (FlxG.sound.music.onComplete != null) FlxG.sound.music.onComplete();
				else onSongComplete();
			}
			if (FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000 * playbackRate);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		if (!inEditor) {
			setOnScripts('cameraX', camFollowPos.x);
			setOnScripts('cameraY', camFollowPos.y);
			setOnScripts('botPlay', cpuControlled);
		}
		
		callOnScripts('onUpdatePost', [elapsed]);

		//doing this after every update cause scripts might force them to be visible
		if (demoMode) {
			for (i in hideInDemoMode) {
				i.visible = false;
			}
		}
	}

	function noteFunctions() {
		for (i in 0...strumLineNotes.length) {
			strumLineNotes.members[i].allNotes.forEachAlive(function(daNote:Note)
			{
				var strumLine = strumLineNotes.members[i];
				if (daNote.keyAmount != strumLine.keys) {
					strumLine = strumMaps[i].get(daNote.keyAmount);
				}
				if (strumLine != null && strumLine.receptors.members[daNote.noteData] != null) {
					var daStrum = strumLine.receptors.members[daNote.noteData];
					var strumX:Float = daStrum.x;
					var strumY:Float = daStrum.y;
					var strumAngle:Float = daStrum.angle;
					var strumDirection:Float = daStrum.direction;
					var strumAlpha:Float = daStrum.alpha;
					var strumScroll:Bool = daStrum.downScroll;
					var strumHeight:Float = daStrum.height;
					var noteSpeed = songSpeed * daNote.multSpeed;
	
					strumX += daNote.offsetX;
					strumY += daNote.offsetY;
					strumAngle += daNote.offsetAngle;
					strumAlpha *= daNote.multAlpha;
					if (Conductor.songPosition < 0) {
						strumAlpha = daNote.multAlpha;
						if(ClientPrefs.middleScroll && !daNote.mustPress)
							strumAlpha *= 0.35;
					}
					if (daNote.tooLate)
						strumAlpha *= 0.3;
					
					if (strumScroll) //Downscroll
					{
						daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * noteSpeed);
					}
					else //Upscroll
					{
						daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * noteSpeed);
					}
	
					var angleDir = strumDirection * Math.PI / 180;
					if (daNote.copyAngle)
						daNote.angle = strumDirection - 90 + strumAngle;
	
					if (daNote.copyAlpha)
						daNote.alpha = strumAlpha;
	
					if (daNote.copyScale) {
						daNote.scale.x = daStrum.scale.x;
						if (!daNote.isSustainNote) {
							daNote.scale.y = daStrum.scale.y;
						}
					}
					
					if (daNote.copyX)
						daNote.x = strumX + Math.cos(angleDir) * daNote.distance;
	
					if (daNote.copyY) {
						daNote.y = strumY + Math.sin(angleDir) * daNote.distance;
	
						if (daNote.isSustainNote && strumScroll) {
							if (daNote.animation.curAnim.name.endsWith('end')) {
								daNote.y += 10.5 * (daNote.stepCrochet * 4 / 400) * 1.5 * noteSpeed + (46 * (noteSpeed - 1));
								daNote.y -= 46 * (1 - (daNote.stepCrochet * 4 / 600)) * noteSpeed;
								if(SONG.skinModifier.endsWith('pixel')) {
									daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * daPixelZoom;
								} else {
									daNote.y -= 19;
								}
							}
							
							daNote.y += (strumHeight / 2) - (60.5 * (noteSpeed - 1));
							daNote.y += 27.5 * ((daNote.bpm / 100) - 1) * (noteSpeed - 1);
						}
					}
	
					if (!daNote.mustPress && strumLine.botPlay && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
					{
						goodNoteHit(daNote, strumLine, false);
					}

					if(!daNote.blockHit && daNote.mustPress && strumLine.botPlay && daNote.canBeHit) {
						if(daNote.strumTime <= Conductor.songPosition || daNote.isSustainNote) {
							goodNoteHit(daNote, strumLine, true);
						}
					}

	
					if (strumDirection == 90 && daStrum.sustainReduce && daNote.isSustainNote && (daNote.mustPress || !daNote.ignoreNote) &&
						(!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
					{
						var center:Float = strumY + strumHeight / 2;
						if (strumScroll)
						{
							if (daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
							{
								var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
								swagRect.height = (center - daNote.y) / daNote.scale.y;
								swagRect.y = daNote.frameHeight - swagRect.height;
	
								daNote.clipRect = swagRect;
							}
						}
						else
						{
							if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
							{
								var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
								swagRect.y = (center - daNote.y) / daNote.scale.y;
								swagRect.height -= swagRect.y;
	
								daNote.clipRect = swagRect;
							}
						}
					}
	
					// Kill extremely late notes and cause misses
					if (Conductor.songPosition > (noteKillOffset / noteSpeed) + daNote.strumTime)
					{
						if (daNote.mustPress && !strumLine.botPlay && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
							noteMiss(daNote);
						}
	
						daNote.active = false;
						daNote.visible = false;
	
						daNote.kill();
						strumLine.allNotes.remove(daNote, true);
						var daGroup = (daNote.isSustainNote ? strumLine.holdsGroup : strumLine.notesGroup);
						daGroup.remove(daNote, true);
						daNote.destroy();
					}
				}
			});
		}
		keyShit();
		checkEventNote();
	}

	public function openPauseMenu(playSound:Bool = true) {
		persistentUpdate = false;
		paused = true;

		if (FlxG.sound.music != null) {
			FlxG.sound.music.pause();
			vocals.pause();
			vocalsDad.pause();
			@:privateAccess { //This is so hiding the debugger doesn't play the music again
				FlxG.sound.music._alreadyPaused = true;
				vocals._alreadyPaused = true;
				vocalsDad._alreadyPaused = true;
			}
		}
		openSubState(new PauseSubState());

		#if DISCORD_ALLOWED
		DiscordClient.changePresence(detailsPausedText, '$curSongDisplayName ($storyDifficultyText)', iconP2.getCharacter());
		#end
	}

	function openChartEditor()
	{
		FlxG.timeScale = 1;
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		SONG = originalSong;
		MusicBeatState.switchState(new ChartingState(false));
		chartingMode = true;

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(skipHealthCheck:Bool = false) {
		if (!cpuControlled && ((skipHealthCheck && instakillOnMiss) || health <= 0)) practiceFailed = true;
		else return false;
		if (!practiceMode && !isDead)
		{
			var ret:Dynamic = callOnScripts('onGameOver', [], false);
			if (ret != FunkinLua.Function_Stop) {
				for (i in playerChar.members) {
					i.stunned = true;
				}
				deathCounter++;

				paused = true;

				vocals.stop();
				vocalsDad.stop();
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}
				SONG = originalSong;
				if (ClientPrefs.instantRestart || opponentChart) {
					var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
						-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
					blackShit.scrollFactor.set();
					add(blackShit);
					camHUD.visible = false;
					FlxG.sound.play(Paths.sound(GameOverSubstate.deathSoundName));
					MusicBeatState.resetState();
				} else {
					openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1]));
				}
				
				#if DISCORD_ALLOWED
				DiscordClient.changePresence(detailsGameOverText, '$curSongDisplayName ($storyDifficultyText)', iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if (Conductor.songPosition < leStrumTime) {
				break;
			}

			var value1:String = '';
			if (eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if (eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	public function controlJustPressed(key:String) {
		var pressed:Bool = FlxG.keys.anyJustPressed(ClientPrefs.copyKey(ClientPrefs.keyBinds.get(key)));
		return pressed;
	}

	public function controlPressed(key:String) {
		var pressed:Bool = FlxG.keys.anyPressed(ClientPrefs.copyKey(ClientPrefs.keyBinds.get(key)));
		return pressed;
	}

	public function controlReleased(key:String) {
		var pressed:Bool = FlxG.keys.anyJustReleased(ClientPrefs.copyKey(ClientPrefs.keyBinds.get(key)));
		return pressed;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch(eventName) {
			case 'Dadbattle Spotlight':
				if (inEditor) return;
				var val:Null<Int> = Std.parseInt(value1);
				if(val == null) val = 0;

				switch(Std.parseInt(value1))
				{
					case 1, 2, 3: //enable and target dad
						if(val == 1) //enable
						{
							dadbattleBlack.visible = true;
							dadbattleLight.visible = true;
							dadbattleSmokes.visible = true;
							defaultCamZoom += 0.12;
						}

						var who:Character = dad;
						if(val > 2) who = boyfriend;
						//2 only targets dad
						dadbattleLight.alpha = 0;
						new FlxTimer().start(0.12, function(tmr:FlxTimer) {
							dadbattleLight.alpha = 0.375;
						});
						dadbattleLight.setPosition(who.getGraphicMidpoint().x - dadbattleLight.width / 2, who.y + who.height - dadbattleLight.height + 50);

					default:
						dadbattleBlack.visible = false;
						dadbattleLight.visible = false;
						defaultCamZoom -= 0.12;
						FlxTween.tween(dadbattleSmokes, {alpha: 0}, 1, {onComplete: function(twn:FlxTween)
						{
							dadbattleSmokes.visible = false;
						}});
				}
			
			case 'Hey!':
				if (inEditor) return;
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if (Math.isNaN(time) || time <= 0) time = 0.6;

				if (value != 0) {
					for (dad in dadGroup) {
						if (dad.curCharacter.startsWith('gf') && dad.animOffsets.exists('cheer')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
							dad.playAnim('cheer', true);
							dad.specialAnim = true;
							dad.heyTimer = time;
						}
					}

					for (gf in gfGroup) {
						if (gf.animOffsets.exists('cheer')) {
							gf.playAnim('cheer', true);
							gf.specialAnim = true;
							gf.heyTimer = time;
						}
					}
				}
				if (value != 1) {
					for (boyfriend in boyfriendGroup) {
						if (boyfriend.animOffsets.exists('hey')) {
							boyfriend.playAnim('hey', true);
							boyfriend.specialAnim = true;
							boyfriend.heyTimer = time;
						}
					}
				}

			case 'Set GF Speed':
				if (inEditor) return;
				var value:Int = Std.parseInt(value1);
				if (Math.isNaN(value)) value = 1;
				if (value < 0) value = 0;
				for (gf in gfGroup) {
					gf.danceEveryNumBeats = value;
				}

			case 'Philly Glow':
				if (inEditor) return;
				if (curStage == 'philly' && ClientPrefs.gameQuality != 'Crappy') {
					var lightId:Int = Std.parseInt(value1);
					if (Math.isNaN(lightId)) lightId = 0;

					var doFlash:Void->Void = function() {
						var color:FlxColor = FlxColor.WHITE;
						if(!ClientPrefs.flashing) color.alphaFloat = 0.5;
	
						FlxG.camera.flash(color, 0.15, null, true);
					};

					var chars = [boyfriendGroup, gfGroup, dadGroup];
					switch(lightId)
					{
						case 0:
							if(phillyGlowGradient.visible)
							{
								doFlash();
								if(ClientPrefs.camZooms)
								{
									FlxG.camera.zoom += 0.5;
									camHUD.zoom += 0.1;
								}

								blammedLightsBlack.visible = false;
								phillyWindowEvent.visible = false;
								phillyGlowGradient.visible = false;
								phillyGlowParticles.visible = false;
								curLightEvent = -1;

								for (charGroup in chars) {
									for (who in charGroup) {
										who.color = FlxColor.WHITE;
									}
								}
								stage.phillyStreet.color = FlxColor.WHITE;
							}

						case 1: //turn on
							curLightEvent = FlxG.random.int(0, stage.phillyLightsColors.length-1, [curLightEvent]);
							var color:FlxColor = stage.phillyLightsColors[curLightEvent];

							if(!phillyGlowGradient.visible)
							{
								doFlash();
								if(ClientPrefs.camZooms)
								{
									FlxG.camera.zoom += 0.5;
									camHUD.zoom += 0.1;
								}

								blammedLightsBlack.visible = true;
								blammedLightsBlack.alpha = 1;
								phillyWindowEvent.visible = true;
								phillyGlowGradient.visible = true;
								phillyGlowParticles.visible = true;
							}
							else if(ClientPrefs.flashing)
							{
								var colorButLower:FlxColor = color;
								colorButLower.alphaFloat = 0.25;
								FlxG.camera.flash(colorButLower, 0.5, null, true);
							}

							var charColor:FlxColor = color;
							if(!ClientPrefs.flashing) charColor.saturation *= 0.5;
							else charColor.saturation *= 0.75;

							for (charGroup in chars) {
								for (who in charGroup)
								{
									who.color = charColor;
								}
							}
							phillyGlowParticles.forEachAlive(function(particle:PhillyGlow.PhillyGlowParticle)
							{
								particle.color = color;
							});
							phillyGlowGradient.color = color;
							phillyWindowEvent.color = color;

							color.brightness *= 0.5;
							stage.phillyStreet.color = color;
		
						case 2: // spawn particles
							if(ClientPrefs.gameQuality == 'Normal')
							{
								var particlesNum:Int = FlxG.random.int(8, 12);
								var width:Float = (2000 / particlesNum);
								var color:FlxColor = stage.phillyLightsColors[curLightEvent];
								for (j in 0...3)
								{
									for (i in 0...particlesNum)
									{
										var particle:PhillyGlow.PhillyGlowParticle = new PhillyGlow.PhillyGlowParticle(-400 + width * i + FlxG.random.float(-width / 5, width / 5), phillyGlowGradient.originalY + 200 + (FlxG.random.float(0, 125) + j * 40), color);
										phillyGlowParticles.add(particle);
									}
								}
							}
							phillyGlowGradient.bop();
					}
				}

			case 'Kill Henchmen':
				if (inEditor) return;
				stage.killHenchmen();

			case 'Add Camera Zoom':
				if (inEditor) return;
				if (ClientPrefs.camZooms && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if (Math.isNaN(camZoom)) camZoom = 0.015;
					if (Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Play Animation':
				if (inEditor) return;
				var charGroup = dadGroup;
				var index = 0;
				var charData = value2.split(',');
				switch(charData[0].toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '1':
						charGroup = boyfriendGroup;
					case 'gf' | 'girlfriend' | '2':
						charGroup = gfGroup;
				}
				if (charData[1] != null) index = Std.parseInt(charData[1]);
				if (charGroup.members[index % charGroup.length] != null && charGroup.members[index % charGroup.length].animOffsets.exists(value1)) {
					charGroup.members[index % charGroup.length].playAnim(value1, true);
					charGroup.members[index % charGroup.length].specialAnim = true;
				}

			case 'Camera Follow Pos':
				if (inEditor) return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1)) val1 = 0;
				if (Math.isNaN(val2)) val2 = 0;

				isCameraOnForcedPos = false;
				if (!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}

			case 'Alt Idle Animation':
				if (inEditor) return;
				var charGroup = dadGroup;
				var index = 0;
				var charData = value1.split(',');
				switch(charData[0].toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '1':
						charGroup = boyfriendGroup;
					case 'gf' | 'girlfriend' | '2':
						charGroup = gfGroup;
				}
				if (charData[1] != null) index = Std.parseInt(charData[1]);
				if (charGroup.members[index % charGroup.length] != null) {
					charGroup.members[index % charGroup.length].idleSuffix = value2;
					charGroup.members[index % charGroup.length].recalculateDanceIdle();
				}

			case 'Screen Shake':
				if (inEditor) return;
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if (split[0] != null) duration = Std.parseFloat(split[0].trim());
					if (split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if (Math.isNaN(duration)) duration = 0;
					if (Math.isNaN(intensity)) intensity = 0;

					if (duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}


			case 'Change Character':
				if (inEditor) return;
				var charType:Int = 0;
				var index = 0;
				var charData = value1.split(',');
				switch(charData[0].toLowerCase().trim()) {
					case 'gf' | 'girlfriend' | '2':
						charType = 2;
					case 'dad' | 'opponent' | '1':
						charType = 1;
				}
				if (charData[1] != null) index = Std.parseInt(charData[1]);

				switch(charType) {
					case 0:
						index %= boyfriendGroup.length;
						if (boyfriendGroup.members[index].curCharacter != value2) {
							if (!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType, index);
							}

							var lastAlpha:Float = boyfriendGroup.members[index].alpha;
							boyfriendGroup.members[index].alpha = 0.00001;
							boyfriendGroup.remove(boyfriendGroup.members[index], true);
							boyfriendGroup.insert(index, boyfriendMap.get(value2));
							boyfriendGroup.members[index].alpha = lastAlpha;
							if (boyfriendGroup.members.length == 1) {
								iconP1.changeIcon(boyfriend.healthIcon);
							}
							setOnScripts('boyfriendName', boyfriend.curCharacter);
							setOnHscripts('boyfriend', boyfriend);
							reloadHealthBarColors();
						}

					case 1:
						index %= dadGroup.length;
						if (dadGroup.members[index].curCharacter != value2) {
							if (!dadMap.exists(value2)) {
								addCharacterToList(value2, charType, index);
							}

							var wasGf:Bool = dadGroup.members[index].curCharacter.startsWith('gf');
							var lastAlpha:Float = dadGroup.members[index].alpha;
							dadGroup.members[index].alpha = 0.00001;
							dadGroup.remove(dadGroup.members[index], true);
							dadGroup.insert(index, dadMap.get(value2));
							if (gf != null) {
								if (!dadGroup.members[index].curCharacter.startsWith('gf')) {
									if (wasGf) {
										gf.visible = true;
									}
								} else {
									gf.visible = false;
								}
							}
							dadGroup.members[index].alpha = lastAlpha;
							if (dadGroup.members.length == 1) {
								iconP2.changeIcon(dad.healthIcon);
							}
							setOnScripts('dadName', dad.curCharacter);
							setOnHscripts('dad', dad);
							reloadHealthBarColors();
						}

					case 2:
						if (gf != null) {
							index %= gfGroup.length;
							if (gfGroup.members[index].curCharacter != value2) {
								if (!gfMap.exists(value2)) {
									addCharacterToList(value2, charType, index);
								}

								var lastAlpha:Float = gfGroup.members[index].alpha;
								gfGroup.members[index].alpha = 0.00001;
								gfGroup.remove(gfGroup.members[index], true);
								gfGroup.insert(index, gfMap.get(value2));
								gfGroup.members[index].alpha = lastAlpha;
								setOnScripts('gfName', gf.curCharacter);
								setOnHscripts('gf', gf);
							}
						}
				}
			
			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1)) val1 = 1;
				if (Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1 / playbackRate;
				newValue = CoolUtil.boundTo(newValue, 0.1, 10);

				if (val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}

			case 'Set Property':
				var killMe:Array<String> = value1.split('.');
				if(killMe.length > 1) {
					FunkinLua.setVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe, true, true), killMe[killMe.length-1], value2);
				} else {
					FunkinLua.setVarInArray(this, value1, value2);
				}
		}
		stage.onEvent(eventName, value1, value2);
		callOnScripts('onEvent', [eventName, value1, value2]);
	}

	function moveCameraSection():Void {
		if (SONG.notes[curSection] == null) return;

		if (gf != null && SONG.notes[curSection].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			if (gfGroupFile != null) {
				camFollow.x += gfGroupFile.camera_position[0] + girlfriendCameraOffset[0];
				camFollow.y += gfGroupFile.camera_position[1] + girlfriendCameraOffset[1];
			} else {
				camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
				camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			}
			tweenCamIn();
			callOnScripts('onMoveCamera', ['gf']);
			return;
		}

		if (!SONG.notes[curSection].mustHitSection)
		{
			moveCamera(true);
			callOnScripts('onMoveCamera', ['dad']);
		}
		else
		{
			moveCamera(false);
			callOnScripts('onMoveCamera', ['boyfriend']);
		}
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		if (isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);

			if (dadGroupFile != null) {
				camFollow.x += dadGroupFile.camera_position[0] + opponentCameraOffset[0];
				camFollow.y += dadGroupFile.camera_position[1] + opponentCameraOffset[1];
			} else {
				camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
				camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			}
			tweenCamIn();
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);

			if (bfGroupFile != null) {
				camFollow.x -= bfGroupFile.camera_position[0] - boyfriendCameraOffset[0];
				camFollow.y += bfGroupFile.camera_position[1] + boyfriendCameraOffset[1];
			} else {
				camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
				camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];
			}

			if (curSong == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.normalizedCrochet / 1000), {ease: FlxEase.elasticInOut, onComplete:
					function (twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
	}

	function tweenCamIn() {
		if (curSong == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.normalizedCrochet / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	private function onSongComplete()
	{
		finishSong(false);
	}
	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		vocalsDad.volume = 0;
		vocalsDad.pause();
		if (ClientPrefs.noteOffset <= 0 || ignoreNoteOffset) {
			finishCallback();
		} else {
			endingTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}

	public var transitioning = false;
	public function endSong():Void
	{
		if (inEditor) {
			LoadingState.loadAndSwitchState(new editors.ChartingState());
			return;
		}
		//Should kill you if you tried to cheat
		if (!startingSong) {
			playerStrums.allNotes.forEach(function(daNote:Note) {
				if (daNote.mustPress && daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes) {
				if (daNote.mustPress && daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}

			if (doDeathCheck()) {
				return;
			}
		}

		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		if (showSongText) songTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		camBop = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		FlxG.timeScale = 1;

		#if ACHIEVEMENTS_ALLOWED
		if (achievementObj != null) {
			return;
		} else {
			var achieve:String = checkForAchievement(['week1_nomiss', 'week2_nomiss', 'week3_nomiss', 'week4_nomiss',
				'week5_nomiss', 'week6_nomiss', 'week7_nomiss', 'ur_bad',
				'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);

			if (achieve != null) {
				startAchievement(achieve);
				return;
			}
		}
		#end
		
		var ret:Dynamic = callOnScripts('onEndSong', [], false);
		if (ret != FunkinLua.Function_Stop && !transitioning) {
			if (chartingMode)
			{
				openChartEditor();
				return;
			}
			
			if (SONG.validScore)
			{
				#if HIGHSCORE_ALLOWED
				var percent:Float = ratingPercent;
				if (Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(curSong, songScore, storyDifficulty, percent);
				#end
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					CoolUtil.playMenuMusic();
					#if cpp
					@:privateAccess
					AL.sourcef(FlxG.sound.music._channel.__source.__backend.handle, AL.PITCH, 1);
					#end

					cancelMusicFadeTween();
					if (FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
					MusicBeatState.switchState(new StoryMenuState());

					if (SONG.validScore) {
						Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);

						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);
						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = CoolUtil.getDifficultyFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(storyPlaylist[0]) + difficulty);

					var winterHorrorlandNext = (curSong == "eggnog");
					if (winterHorrorlandNext)
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
							-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;

						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					SONG = Song.loadFromJson(storyPlaylist[0] + difficulty, storyPlaylist[0]);
					FlxG.sound.music.stop();

					if (winterHorrorlandNext) {
						new FlxTimer().start(1.5, function(tmr:FlxTimer) {
							cancelMusicFadeTween();
							LoadingState.loadAndResetState();
						});
					} else {
						cancelMusicFadeTween();
						LoadingState.loadAndResetState();
					}

					var metadata = new SongMetadata(storyPlaylist[0], storyWeek, 'face', 0);
					for (i in FreeplayState.lastPlayed) {
						if (i.songName == metadata.songName) {
							FreeplayState.lastPlayed.remove(i);
							break;
						}
					}
					FreeplayState.lastPlayed.unshift(metadata);
					FlxG.save.data.lastPlayed = FreeplayState.lastPlayed;
					FlxG.save.flush();
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				cancelMusicFadeTween();
				if (FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				SONG = originalSong;
				MusicBeatState.switchState(new FreeplayState());
				CoolUtil.playMenuMusic();
				#if cpp
				@:privateAccess
				AL.sourcef(FlxG.sound.music._channel.__source.__backend.handle, AL.PITCH, 1);
				#end
				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;
	function startAchievement(achieve:String) {
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement $achieve');
	}
	function achievementEnd():Void
	{
		achievementObj = null;
		if (endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

	public function killNotes() {
		for (strumLine in strumLineNotes) {
			while(strumLine.allNotes.length > 0) {
				var daNote:Note = strumLine.allNotes.members[0];
				daNote.active = false;
				daNote.visible = false;
	
				daNote.kill();
				strumLine.allNotes.remove(daNote, true);
				var daGroup = (daNote.isSustainNote ? strumLine.holdsGroup : strumLine.notesGroup);
				daGroup.remove(daNote, true);
				daNote.destroy();
			}
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		if (opponentChart) coolText.x = FlxG.width * 0.55;

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(note, noteDiff);
		var ratingNum = ratingsData.indexOf(daRating);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.increase();
		note.rating = daRating.name;
		score = daRating.score;

		if(daRating.noteSplash && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note, playerStrums);
		}

		if (!daRating.causesMiss) {
			health += note.hitHealth * healthGain;
			if (!practiceMode && !cpuControlled) {
				songScore += score;
				if(!note.ratingDisabled) {
					songHits++;
					totalPlayed++;
					recalculateRating();
					doRatingTween(ratingNum);
				}
			}
		} else {
			noteMissPress(note.noteData);
		}

		rating.loadGraphic(Paths.image(getUIFile(daRating.image)));
		if (!inEditor) rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.visible = !ClientPrefs.hideHud && showRating && !demoMode;
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(getUIFile('combo')));
		if (!inEditor) comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = coolText.x + 80;
		comboSpr.y += 60;
		comboSpr.acceleration.y = FlxG.random.int(200, 300);
		comboSpr.velocity.y -= FlxG.random.int(140, 160);
		comboSpr.visible = !ClientPrefs.hideHud && !demoMode;
		comboSpr.x += ClientPrefs.comboOffset[0];
		comboSpr.y -= ClientPrefs.comboOffset[1];
		comboSpr.y += 60;
		comboSpr.velocity.x += FlxG.random.int(1, 10);

		insert(members.indexOf(strumLineNotes), rating);

		if (!SONG.skinModifier.endsWith('pixel'))
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if (combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		var xThing:Float = 0;
		if (showCombo)
		{
			insert(members.indexOf(strumLineNotes), comboSpr);
		}
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(getUIFile('num$i')));
			if (!inEditor) numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];

			if (!SONG.skinModifier.endsWith('pixel'))
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.visible = !ClientPrefs.hideHud && !demoMode;

			if(showComboNum)
				insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.normalizedCrochet * 0.002
			});

			daLoop++;
			if(numScore.x > xThing) xThing = numScore.x;
		}
		comboSpr.x = xThing + 50;

		coolText.text = Std.string(seperatedScore);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.normalizedCrochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.normalizedCrochet * 0.002
		});
	}

	function doRatingTween(ind:Int = 0) {
		if (ClientPrefs.scoreZoom)
		{
			if (ratingTxtTweens[ind] != null) {
				ratingTxtTweens[ind].cancel();
			}
			ratingTxtGroup.members[ind].scale.x = 1.02;
			ratingTxtGroup.members[ind].scale.y = 1.02;
			ratingTxtTweens[ind] = FlxTween.tween(ratingTxtGroup.members[ind].scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween) {
					ratingTxtTweens[ind] = null;
				}
			});
		}
	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		if (!cpuControlled && startedCountdown && !paused) {
			var eventKey:FlxKey = event.keyCode;
			var key:Int = getKeyFromEvent(eventKey);

			if (key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || controls.gamepadsAdded.length > 0))
			{
				if ((inEditor || !playerChar.members[0].stunned) && generatedMusic && !endingSong)
				{
					var lastTime:Float = Conductor.songPosition;
					//more accurate hit time for the ratings?
					Conductor.songPosition = FlxG.sound.music.time;

					var canMiss:Bool = !ClientPrefs.ghostTapping;

					// heavily based on my own code LOL if it aint broke dont fix it
					var pressNotes:Array<Note> = [];
					var notesStopped:Bool = false;

					var sortedNotesList:Array<Note> = [];
					playerStrums.allNotes.forEachAlive(function(daNote:Note)
					{
						if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote && !daNote.blockHit)
						{
							if (daNote.noteData == key)
							{
								sortedNotesList.push(daNote);
							}
							canMiss = true;
						}
					});
					sortedNotesList.sort(sortHitNotes);

					if (sortedNotesList.length > 0) {
						for (epicNote in sortedNotesList)
						{
							for (doubleNote in pressNotes) {
								if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
									doubleNote.kill();
									playerStrums.allNotes.remove(doubleNote, true);
									var daGroup = (doubleNote.isSustainNote ? playerStrums.holdsGroup : playerStrums.notesGroup);
									daGroup.remove(doubleNote, true);
									doubleNote.destroy();
								} else
									notesStopped = true;
							}
								
							// eee jack detection before was not super good
							if (!notesStopped) {
								goodNoteHit(epicNote, playerStrums, true, [eventKey]);
								pressNotes.push(epicNote);
							}

						}
					}
					else{
						callOnScripts('onGhostTap', [key]);
						if (canMiss) {
							noteMissPress(key);
						}
					}

					// I dunno what you need this for but here you go
					//									- Shubs

					// Shubs, this is for the "Just the Two of Us" achievement lol
					//									- Shadow Mario
					keysPressed[key] = true;

					//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
					Conductor.songPosition = lastTime;
				}

				var spr:StrumNote = playerStrums.receptors.members[key];
				if (spr != null && spr.animation.curAnim.name != 'confirm')
				{
					spr.playAnim('pressed');
					spr.resetAnim = 0;
				}
				callOnScripts('onKeyPress', [key]);
			}
		}
	}

	function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}
	
	private function onKeyRelease(event:KeyboardEvent):Void
	{
		if (!cpuControlled && startedCountdown && !paused) {
			var eventKey:FlxKey = event.keyCode;
			var key:Int = getKeyFromEvent(eventKey);
			if (key > -1)
			{
				var spr:StrumNote = playerStrums.receptors.members[key];
				if (spr != null)
				{
					spr.playAnim('static');
					spr.resetAnim = 0;
				}
				callOnScripts('onKeyRelease', [key]);
			}
		}
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if (key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	// Hold notes + controller input
	private function keyShit():Void
	{
		// HOLDING
		var controlHoldArray:Array<Bool> = [];
		for (i in keysArray) {
			controlHoldArray.push(FlxG.keys.anyPressed(i));
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(controls.gamepadsAdded.length > 0 && playerStrums.keys == 4)
		{
			controlHoldArray = [controls.NOTE_LEFT, controls.NOTE_DOWN, controls.NOTE_UP, controls.NOTE_RIGHT];
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_P, controls.NOTE_DOWN_P, controls.NOTE_UP_P, controls.NOTE_RIGHT_P];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		if (startedCountdown && (inEditor || !playerChar.members[0].stunned) && generatedMusic)
		{
			// rewritten inputs???
			playerStrums.allNotes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit 
				&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) {
					goodNoteHit(daNote, playerStrums, true, keysArray[daNote.noteData]);
				}
			});

			if (controlHoldArray.contains(true) && !endingSong) {
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null) {
					startAchievement(achieve);
				}
				#end
			} else {
				for (char in playerChar) {
					if (char.holdTimer > Conductor.normalizedStepCrochet * 0.0011 * char.singDuration && char.animation.curAnim != null && char.animation.curAnim.name.startsWith('sing') && !char.animation.curAnim.name.endsWith('miss')) {
						char.dance();
					}
				}
			}
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(controls.gamepadsAdded.length > 0 && playerStrums.keys == 4)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_R, controls.NOTE_DOWN_R, controls.NOTE_UP_R, controls.NOTE_RIGHT_R];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		playerStrums.allNotes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				playerStrums.allNotes.remove(daNote, true);
				var daGroup = (daNote.isSustainNote ? playerStrums.holdsGroup : playerStrums.notesGroup);
				daGroup.remove(daNote, true);
				note.destroy();
			}
		});
		combo = 0;
		health -= daNote.missHealth * healthLoss;

		if (opponentChart && foundDadVocals)
			vocalsDad.volume = 0;
		else
			vocals.volume = 0;

		if (instakillOnMiss)
		{
			doDeathCheck(true);
		}

		songMisses++;
		if (!practiceMode) songScore -= 10;
		
		totalPlayed++;
		recalculateRating(true);
		doRatingTween(ratingTxtGroup.members.length - 1);

		if (!inEditor) {
			var charGroup = playerChar;
			if (daNote.gfNote) {
				charGroup = gfGroup;
			}

			var characters = daNote.characters.copy();
			if (characters.length < 1) {
				for (i in 0...boyfriendGroup.length) {
					characters.push(i);
				}
			}
			for (char in characters) {
				if (char < charGroup.members.length && charGroup.members[char] != null && !daNote.noMissAnimation && charGroup.members[char].hasMissAnimations)
				{
					var animToPlay:String = '${playerStrums.animations[daNote.noteData]}miss${daNote.animSuffix}';
					if (charGroup.members[char].animOffsets.exists(animToPlay)) {
						charGroup.members[char].playAnim(animToPlay, true);
					}
				}
			}
		}

		callOnScripts('noteMiss', [playerStrums.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote, daNote.characters]);
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if(ClientPrefs.ghostTapping) return; //fuck it

		if (inEditor || !playerChar.members[0].stunned)
		{
			health -= 0.05 * healthLoss;

			if (opponentChart && foundDadVocals)
				vocalsDad.volume = 0;
			else
				vocals.volume = 0;

			if (instakillOnMiss)
			{
				doDeathCheck(true);
			}

			if (combo > 5 && !inEditor)
			{
				for (gf in gfGroup) {
					if (gf.animOffsets.exists('sad')) {
						gf.playAnim('sad');
					}
				}
			}
			combo = 0;

			if (!practiceMode) songScore -= 10;
			if (!endingSong) {
				songMisses++;
			}
			totalPlayed++;
			recalculateRating(true);
			doRatingTween(ratingTxtGroup.members.length - 1);

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

			if (!inEditor) {
				var animToPlay = '${playerStrums.animations[direction]}miss';
				for (char in playerChar) {
					if (char.hasMissAnimations && char.animOffsets.exists(animToPlay)) {
						char.playAnim(animToPlay, true);
					}
				}
			}
		}

		callOnScripts('noteMissPress', [direction]);
	}

	function goodNoteHit(note:Note, strumGroup:StrumLine, isPlayer:Bool = true, ?keys:Array<FlxKey>):Void
	{
		if (keys == null) keys = [];
		if (!note.mustPress || !note.wasGoodHit)
		{
			if (strumGroup.botPlay && (note.ignoreNote || note.hitCausesMiss)) return;
			if (isPlayer && ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled && !demoMode)
			{
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
			}

			if (!isPlayer && curSong != 'tutorial') {
				camZooming = true;
				camBop = true;
			}

			var charGroup = note.isOpponent ? dadGroup : boyfriendGroup;
			if (note.gfNote) charGroup = gfGroup;

			var characters = note.characters.copy();
			if (characters.length < 1) {
				for (i in 0...charGroup.length) {
					characters.push(i);
				}
			}

			if (isPlayer) {
				if (!strumGroup.botPlay) {
					var spr = strumGroup.receptors.members[note.noteData];
					if(spr != null) {
						spr.playAnim('confirm', true);
					}
				}

				if (note.hitCausesMiss) {
					noteMiss(note);
					if (!note.noteSplashDisabled && !note.isSustainNote) {
						spawnNoteSplashOnNote(note, strumGroup);
					}

					if (!note.noMissAnimation && !inEditor) {
						switch(note.noteType) {
							case 'Hurt Note': //Hurt note
								for (i in characters) {
									if (i < charGroup.members.length) {
										if (charGroup.members[i] != null && charGroup.members[i].animOffsets.exists('hurt')) {
											charGroup.members[i].playAnim('hurt', true);
											charGroup.members[i].specialAnim = true;
										}
									}
								}
						}
					}
					
					note.wasGoodHit = true;
					if (strumGroup.receptors.members[note.noteData].direction != 90 || !note.isSustainNote)
					{
						note.kill();
						strumGroup.allNotes.remove(note, true);
						var daGroup = (note.isSustainNote ? strumGroup.holdsGroup : strumGroup.notesGroup);
						daGroup.remove(note, true);
						note.destroy();
					}
					return;
				}

				if (!note.isSustainNote)
				{
					combo += 1;
					if (combo > 9999) combo = 9999;
					popUpScore(note);
				}
				else
				{
					health += note.hitHealth * healthGain;
				}
			}

			if (!note.noAnimation && !inEditor) {
				var altAnim:String = note.animSuffix;

				if (note.isOpponent && SONG.notes[curSection] != null && SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection) {
					altAnim = '-alt';
				}

				for (i in characters) {
					if (i < charGroup.members.length && charGroup.members[i] != null) {
						var animToPlay:String = strumGroup.animations[note.noteData] + altAnim;
						if (!charGroup.members[i].animOffsets.exists(animToPlay))
							animToPlay = strumGroup.animations[note.noteData];
						if (charGroup.members[i].animOffsets.exists(animToPlay)) {
							if (!note.isSustainNote || charGroup.members[i].repeatHoldAnimation) charGroup.members[i].playAnim(animToPlay, true);
							charGroup.members[i].holdTimer = 0;
							if (keys != null) charGroup.members[i].keysPressed = keys;
						}
					}
				}

				if (note.noteType == 'Hey!') {
					for (i in characters) {
						if (i < charGroup.members.length && charGroup.members[i] != null && charGroup.members[i].animOffsets.exists('hey')) {
							if (!note.isSustainNote || charGroup.members[i].repeatHoldAnimation) charGroup.members[i].playAnim('hey', true);
							charGroup.members[i].specialAnim = true;
							charGroup.members[i].heyTimer = 0.6;
						}
					}
	
					for (gf in gfGroup) {
						if (gf.animOffsets.exists('cheer')) {
							if (!note.isSustainNote || gf.repeatHoldAnimation) gf.playAnim('cheer', true);
							gf.specialAnim = true;
							gf.heyTimer = 0.6;
						}
					}
				}
			}

			if (strumGroup.botPlay) {
				var time:Float = 0.15;
				if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}

				var spr = strumGroup.receptors.members[note.noteData];
				if (spr != null) {
					spr.playAnim('confirm', true);
					spr.resetAnim = time;
				}

				if (!note.noteSplashDisabled && !note.isSustainNote) {
					spawnNoteSplashOnNote(note, strumGroup);
				}
			}
			note.wasGoodHit = true;
			if (!strumGroup.isBoyfriend && foundDadVocals)
				vocalsDad.volume = 1;
			else
				vocals.volume = 1;

			if (!note.mustPress) note.hitByOpponent = true;

			callOnScripts('onNoteHit', [strumGroup.allNotes.members.indexOf(note), note.noteData, note.noteType, note.isSustainNote, note.characters, strumLineNotes.members.indexOf(strumGroup), isPlayer]);

			if (strumGroup.receptors.members[note.noteData].direction != 90 || !note.isSustainNote)
			{
				note.kill();
				strumGroup.allNotes.remove(note, true);
				var daGroup = (note.isSustainNote ? strumGroup.holdsGroup : strumGroup.notesGroup);
				daGroup.remove(note, true);
				note.destroy();
			}
		}
	}

	function spawnNoteSplashOnNote(note:Note, strumGroup:StrumLine) {
		if (note != null && ClientPrefs.noteSplashes) {
			var strum:StrumNote = strumGroup.receptors.members[note.noteData];
			if (strum != null) {
				spawnNoteSplash(strum.x, strum.y, note, strumGroup);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, note:Note, strumGroup:StrumLine) {
		var skin:String = 'noteSplashes';
		var keys = strumGroup.keys;
		
		var hue:Float = 0;
		var sat:Float = 0;
		var brt:Float = 0;
		if (note.noteData > -1 && note.noteData < ClientPrefs.arrowHSV[keys - 1].length)
		{
			hue = ClientPrefs.arrowHSV[keys - 1][note.noteData][0] / 360;
			sat = ClientPrefs.arrowHSV[keys - 1][note.noteData][1] / 100;
			brt = ClientPrefs.arrowHSV[keys - 1][note.noteData][2] / 100;
			if (note != null) {
				skin = note.noteSplashTexture;
				hue = note.noteSplashHue;
				sat = note.noteSplashSat;
				brt = note.noteSplashBrt;
			}
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, note, skin, hue, sat, brt, keys);
		grpNoteSplashes.add(splash);
	}

	override function destroy() {
		FlxG.timeScale = 1;
		Conductor.playbackRate = 1;
		for (lua in luaArray) {
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = [];
		#if HSCRIPT_ALLOWED
		for (i in hscriptMap.keys()) {
			callHscript(i, 'onDestroy', []);
			var hscript = hscriptMap.get(i);
			hscriptMap.remove(i);
			hscript = null;
		}
		hscriptMap.clear();
		#end

		if (inEditor)
			FlxG.sound.music.stop();
		vocals.stop();
		vocals.destroy();
		vocalsDad.stop();
		vocalsDad.destroy();

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		#if hscript
		FunkinLua.haxeInterp = null;
		#end

		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		//reset window to before lua messed with it
		Application.current.window.title = lastTitle;
		CoolUtil.setWindowIcon();
		#end

		super.destroy();

		instance = null;
	}

	public static function cancelMusicFadeTween() {
		if (FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();
		if (generatedMusic && (Math.abs(FlxG.sound.music.time - Conductor.songPosition) > 20 * playbackRate
			|| (SONG.needsVoices && ((Math.abs(vocals.time - Conductor.songPosition) > 20 * playbackRate) 
			|| (foundDadVocals && Math.abs(vocalsDad.time - Conductor.songPosition) > 20 * playbackRate)))))
		{
			resyncVocals();
		}

		if (curStep == lastStepHit) {
			return;
		}

		if (!inEditor && ClientPrefs.gameQuality != 'Crappy' && curBeat >= 0)
			stage.onStepHit();

		lastStepHit = curStep;
		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit', []);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	var lastBeatHit:Int = -1;
	
	override function beatHit()
	{
		super.beatHit();

		if (lastBeatHit >= curBeat) {
			return;
		}

		var curNumeratorBeat = Conductor.getCurNumeratorBeat(SONG, curBeat);

		if (!inEditor) {
			if (iconBopSpeed > 0 && curBeat % Math.round((iconBopSpeed * (Conductor.timeSignature[1] / 4))) == 0) {
				iconP1.scale.set(1.2, 1.2);
				iconP2.scale.set(1.2, 1.2);
				iconP1.updateHitbox();
				iconP2.updateHitbox();
			}

			if (curBeat >= 0) {
				var chars = [boyfriendGroup, dadGroup, gfGroup];
				for (group in chars) {
					for (char in group) {
						if (char.danceEveryNumBeats > 0 && curNumeratorBeat % (Math.round(char.danceEveryNumBeats * (Conductor.timeSignature[1] / 4))) == 0 && !char.stunned && char.animation.curAnim != null && !char.animation.curAnim.name.startsWith("sing"))
						{
							char.dance();
						}
					}
				}
			}

			if (ClientPrefs.gameQuality != 'Crappy' && curBeat >= 0)
				stage.onBeatHit();
		}
		lastBeatHit = curBeat;

		setOnScripts('curBeat', curBeat);//DAWGG?????
		setOnScripts('curNumeratorBeat', curNumeratorBeat);
		setOnScripts('curSection', curSection);
		callOnScripts('onBeatHit', []);
	}

	override function sectionHit() {
		super.sectionHit();
		
		var songSection = SONG.notes[curSection];
		if (songSection != null)
		{
			if (!inEditor && ClientPrefs.camZooms && camZooming && camBop && FlxG.camera.zoom < 1.35)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
			}

			if (songSection.changeBPM && songSection.bpm != Conductor.bpm)
			{
				Conductor.changeBPM(songSection.bpm);
				setOnScripts('curBpm', Conductor.bpm);
				setOnScripts('crochet', Conductor.crochet);
				setOnScripts('normalizedCrochet', Conductor.normalizedCrochet);
				setOnScripts('stepCrochet', Conductor.stepCrochet);
				callOnScripts('onBPMChange', []);
			}
			if (songSection.changeSignature && (songSection.timeSignature[0] != Conductor.timeSignature[0] || songSection.timeSignature[1] != Conductor.timeSignature[1]))
			{
				Conductor.changeSignature(songSection.timeSignature);
				setOnScripts('signatureNumerator', Conductor.timeSignature[0]);
				setOnScripts('signatureDenominator', Conductor.timeSignature[1]);
				setOnScripts('crochet', Conductor.crochet);
				setOnScripts('normalizedCrochet', Conductor.normalizedCrochet);
				setOnScripts('stepCrochet', Conductor.stepCrochet);
				callOnScripts('onSignatureChange', []);
			}
			for (i in 0...strumLineNotes.length) {
				var strumLine = strumLineNotes.members[i];
				var curEvent:KeyChangeEvent = null;
				for (event in strumLine.keyChangeMap) {
					if (event.section <= curSection) {
						curEvent = event;
					}
				}
				if (curEvent != null && strumLine.keys != curEvent.keys) {
					switchKeys(i, curEvent.keys, strumLine.isBoyfriend);
					callOnScripts('onKeyChange', [i, curEvent.keys]);
				}
			}
			setOnScripts('mustHitSection', songSection.mustHitSection);
			setOnScripts('altAnim', songSection.altAnim);
			setOnScripts('gfSection', songSection.gfSection);
			setOnScripts('lengthInSteps', songSection.lengthInSteps);
			setOnScripts('changeBPM', songSection.changeBPM);
			setOnScripts('changeSignature', songSection.changeSignature);
			setOnScripts('changeKeys', songSection.changeKeys);
		}
	}

	var keysInit:Bool = true;
	function switchKeys(strumID:Int, keys:Int, isBoyfriend:Bool = false) {
		if (strumLineNotes.members[strumID].keys == keys && !keysInit) return;

		if (!strumMaps[strumID].exists(keys)) {
			generateStaticArrows(strumID, keys, isBoyfriend);
		}
		var lastStrum = strumMaps[strumID].get(strumLineNotes.members[strumID].keys);
		strumLineNotes.members[strumID] = strumMaps[strumID].get(keys);
		strumLineNotes.members[strumID].takeNotesFrom(lastStrum);
		if (strumLineNotes.members[strumID] == playerStrums) {
			setKeysArray(keys);
			resetUnderlay(underlayPlayer, strumLineNotes.members[strumID].receptors);
			showKeybindReminders();
		}

		if (strumID == 0) {
			setOnScripts('dadKeyAmount', keys);
			for (i in 0...strumLineNotes.members[strumID].length) {
				setOnScripts('defaultDadStrumX$i', strumLineNotes.members[strumID].receptors.members[i].x);
				setOnScripts('defaultDadStrumY$i', strumLineNotes.members[strumID].receptors.members[i].y);
			}
			setOnHscripts('dadStrums', strumLineNotes.members[0]);
		} else if (strumID == 1) {
			setOnScripts('boyfriendKeyAmount', keys);
			for (i in 0...strumLineNotes.members[strumID].length) {
				setOnScripts('defaultBoyfriendStrumX$i', strumLineNotes.members[strumID].receptors.members[i].x);
				setOnScripts('defaultBoyfriendStrumY$i', strumLineNotes.members[strumID].receptors.members[i].y);
			}
			setOnHscripts('boyfriendStrums', strumLineNotes.members[1]);
		}
		keysInit = true;
	}

	function getUIFile(file:String) {
		return SkinData.getUIFile(file, SONG.skinModifier);
	}
	
	function getNoteFile(file:String) {
		return SkinData.getNoteFile(file, SONG.skinModifier);
	}

	public function callOnScripts(event:String, args:Array<Dynamic>, ignoreStops = true, ?exclusions:Array<String> = null):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		if (!inEditor) {
			if(exclusions == null) exclusions = [];
			#if LUA_ALLOWED
			for (script in luaArray) {
				if(exclusions.contains(script.scriptName))
					continue;

				var ret:Dynamic = script.call(event, args);
				if(ret == FunkinLua.Function_StopLua && !ignoreStops)
					break;

				if(ret != FunkinLua.Function_Continue && ret != true && ret != false)
					returnVal = ret;
			}
			#end

			#if HSCRIPT_ALLOWED
			for (script in hscriptMap.keys()) {
				var hscript = hscriptMap.get(script);
				if(hscript.closed || exclusions.contains(hscript.scriptName))
					continue;

				var ret:Dynamic = callHscript(script, event, args);
				if(ret == FunkinLua.Function_StopLua && !ignoreStops)
					break;

				if (ret != FunkinLua.Function_Continue)
					returnVal = ret;
			}
			#end
		}
		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic) {
		if (!inEditor) {
			#if LUA_ALLOWED
			for (i in 0...luaArray.length) {
				luaArray[i].set(variable, arg);
			}
			#end

			#if HSCRIPT_ALLOWED
			setOnHscripts(variable, arg);
			#end
		}
	}

	function strumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function recalculateRating(badHit:Bool = false) {
		setOnScripts('score', songScore);
		setOnScripts('misses', songMisses);
		setOnScripts('hits', songHits);

		if (badHit)
			updateScore(true); // miss notes shouldn't make the scoretxt bounce -Ghost
		else
			updateScore(false);

		var ret:Dynamic = callOnScripts('onRecalculateRating', [], false);
		if (ret != FunkinLua.Function_Stop)
		{
			if (totalPlayed < 1) //Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));

				// Rating Name
				if (ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length - 1][0]; //Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length - 1)
					{
						if (ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = "";
			if (sicks > 0) ratingFC = "SFC";
			if (goods > 0) ratingFC = "GFC";
			if (bads > 0 || shits > 0) ratingFC = "FC";
			if (songMisses > 0 && songMisses < 10) ratingFC = "SDCB";
			else if (songMisses >= 10) ratingFC = "Clear";
		}
		setOnScripts('rating', ratingPercent);
		setOnScripts('ratingName', ratingName);
		setOnScripts('ratingFC', ratingFC);
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String
	{
		if (inEditor || chartingMode || cpuControlled) return null;

		var usedPractice:Bool = practiceMode;
		for (i in 0...achievesToCheck.length) {
			var achievementName:String = achievesToCheck[i];
			if(!Achievements.isAchievementUnlocked(achievementName)) {
				var unlock:Bool = false;
				switch(achievementName)
				{
					case 'week1_nomiss' | 'week2_nomiss' | 'week3_nomiss' | 'week4_nomiss' | 'week5_nomiss' | 'week6_nomiss' | 'week7_nomiss':
						if(isStoryMode && campaignMisses + songMisses < 1 && CoolUtil.difficultyString() == 'HARD' && storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						{
							var weekName:String = WeekData.getWeekFileName();
							switch(weekName) //I know this is a lot of duplicated code, but it's easier readable and you can add weeks with different names than the achievement tag
							{
								case 'week1':
									if(achievementName == 'week1_nomiss') unlock = true;
								case 'week2':
									if(achievementName == 'week2_nomiss') unlock = true;
								case 'week3':
									if(achievementName == 'week3_nomiss') unlock = true;
								case 'week4':
									if(achievementName == 'week4_nomiss') unlock = true;
								case 'week5':
									if(achievementName == 'week5_nomiss') unlock = true;
								case 'week6':
									if(achievementName == 'week6_nomiss') unlock = true;
								case 'week7':
									if(achievementName == 'week7_nomiss') unlock = true;
							}
						}
					case 'ur_bad':
						if (totalPlayed > 0 && ratingPercent < 0.2 && !usedPractice) {
							unlock = true;
						}
					case 'ur_good':
						if (totalPlayed > 0 && ratingPercent >= 1 && !usedPractice) {
							unlock = true;
						}
					case 'roadkill_enthusiast':
						if (Achievements.henchmenDeath >= 100) {
							unlock = true;
						}
					case 'oversinging':
						if (playerChar.members[0].holdTimer >= 10 && !usedPractice) {
							unlock = true;
						}
					case 'hype':
						if (!boyfriendIdled && !usedPractice) {
							unlock = true;
						}
					case 'two_keys':
						if (!usedPractice) {
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length) {
								if (keysPressed[j]) howManyPresses++;
							}

							if (howManyPresses <= 2) {
								unlock = true;
							}
						}
					case 'toastie':
						if (ClientPrefs.gameQuality != 'Normal' && !ClientPrefs.globalAntialiasing) {
							unlock = true;
						}
					case 'debugger':
						if (curSong == 'test' && !usedPractice) {
							unlock = true;
						}
				}

				if (unlock) {
					Achievements.unlockAchievement(achievementName);
					return achievementName;
				}
			}
		}
		return null;
	}
	#end
	var traced:Bool = false;
}