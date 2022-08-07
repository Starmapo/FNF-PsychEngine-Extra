package pvp;

import Conductor.Rating;
import openfl.filters.ShaderFilter;
import lime.media.openal.AL;
import flixel.addons.effects.FlxTrail;
import flixel.math.FlxRect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxStringUtil;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import openfl.events.KeyboardEvent;
#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end
import flixel.tweens.FlxEase;
import flixel.util.FlxSort;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import StageData.StageFile;
import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import Character.CharacterGroupFile;
import flixel.group.FlxSpriteGroup;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import StrumNote.StrumLine;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.FlxSprite;
import Note.EventNote;
import flixel.system.FlxSound;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.tweens.FlxTween;

using StringTools;

//yea no not gonna bother trying to implement this in the normal playstate
//DOES NOT SUPPORT: other key amounts than 4k
class PvPPlayState extends MusicBeatState {
    //event variables
	private var isCameraOnForcedPos:Bool = false;
	public var boyfriendMap:Map<String, Character> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();

	public var stage:Stage;
    public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

    public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;

    public var boyfriendGroup:FlxTypedSpriteGroup<Character>;
	public var dadGroup:FlxTypedSpriteGroup<Character>;
	public var gfGroup:FlxTypedSpriteGroup<Character>;
	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;

	public var noteKillOffset:Float = 350;
	public var spawnTime:Float = 2000;

	public var vocals:FlxSound;
	public var vocalsDad:FlxSound;
	var foundDadVocals:Bool = false;

	public var dad(get, never):Character;
	public var gf(get, never):Character;
	public var boyfriend(get, never):Character;

	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	private var strumLine:FlxSprite;

	//Handles the new epic mega sexy cam code that i've done
	public var camFollow:Array<FlxPoint> = [];
	public var camFollowPos:Array<FlxObject> = [];

	public var strumLineNotes:FlxTypedGroup<StrumLine>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	public var grpRatings:FlxTypedGroup<FlxSprite>;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	public var camBop:Bool = false;
	public var curSong:String = "";
	public var curSongDisplayName:String = "";

	public var health:Float = 1;
	public var shownHealth:Float = 1;
	public var combo:Array<Int> = [0, 0];

	private var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;
	private var songPercent:Float = 0;
	
	public var ratingsData:Array<Rating> = [];
	public var sicks:Array<Int> = [0, 0];
	public var goods:Array<Int> = [0, 0];
	public var bads:Array<Int> = [0, 0];
	public var shits:Array<Int> = [0, 0];
	
	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = true;
	private var updateTime:Bool = true;

	//Gameplay settings
	public var playbackRate:Float = 1;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camHUD2:FlxCamera;
	public var camGames:Array<FlxCamera> = [];
	public var camBorder:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;
	public var iconBopSpeed:Int = 1;

	var dadbattleBlack:BGSprite;
	var dadbattleLight:BGSprite;
	var dadbattleSmokes:FlxSpriteGroup;

	var blammedLightsBlack:FlxSprite;
	var phillyWindowEvent:BGSprite;
	var phillyGlowGradient:PhillyGlow.PhillyGlowGradient;
	var phillyGlowParticles:FlxTypedGroup<PhillyGlow.PhillyGlowParticle>;
	var curLightEvent:Int = -1;

	public var songScore:Array<Float> = [0, 0];
	public var songMisses:Array<Int> = [0, 0];
	public var scoreTxt:Array<FlxText> = [];
	var timeTxt:FlxText;
	var scoreTxtTween:Array<FlxTween> = [null, null];

	public var ratingTxtGroup:Array<FlxTypedGroup<FlxText>> = [];
	public var ratingTxtTweens:Array<Array<FlxTween>> = [[], []];

	public var defaultCamZoom:Float = 1.05;
	public var defaultCamHudZoom:Float = 1;

	public var camMove:Bool = true;
	public var skipCountdown:Bool = false;
	public var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if DISCORD_ALLOWED
	// Discord RPC variables
	public var storyDifficultyText:String = "";
	public var detailsText:String = "";
	public var detailsPausedText:String = "";
	#end

	// Lua shit
	public static var instance:PvPPlayState;
	
	// Less laggy controls
	private var keysArray:Array<Array<FlxKey>>;

	var bfGroupFile:CharacterGroupFile = null;
	var dadGroupFile:CharacterGroupFile = null;
	var gfGroupFile:CharacterGroupFile = null;

	public var strumMaps:Array<Map<Int, StrumLine>> = [];

	var startTimer:FlxTimer;
	var endingTimer:FlxTimer = null;

	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public var introSoundsSuffix = '';

	var precacheList:Map<String, String> = new Map<String, String>();

	public var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	public var totalPlayed:Array<Int> = [0, 0];
	public var totalNotesHit:Array<Float> = [0.0, 0.0];

	public var showRating:Bool = true;

	public var ratingName:Array<String> = ['?', '?'];
	public var ratingPercent:Array<Float> = [0, 0];
	public var ratingFC:Array<String> = ['', ''];
	public var transitioning = false;

	public static var boyfriendMatch:Bool = false;
	public static var dadMatch:Bool = false;
	public static var intendedBoyfriendLength:Int = 1;
	public static var intendedDadLength:Int = 1;
	public static var skipStage:Bool = false;

	var boyfriendScoreMult:Float = 1;
	var dadScoreMult:Float = 1;
	var dadCamX:Float = 0;
	var dadCamY:Float = 0;
	var boyfriendCamX:Float = 0;
	var boyfriendCamY:Float = 0;

	var winTxt:FlxText;

	var pshaggyLegs:Map<Character, FlxSprite> = new Map();
	var pshaggyLegT:Map<Character, FlxTrail> = new Map();

	private var shakeCam2:Array<Bool> = [false, false, false];
	var healthDrain:Array<Float> = [0, 0];
	var floatY:Float = 0;

	//var creditsMap:Map<String, String> = new Map();
	var songDetails:String = '';

	public static var dadSwitch:String = '';
	public static var boyfriendSwitch:String = '';

	function get_boyfriend() {
		return boyfriendGroup.members[0];
	}

	function get_dad() {
		return dadGroup.members[0];
	}

	function get_gf() {
		return gfGroup.members[0];
	}

    function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			for (strumLine in strumLineNotes) {
				for (note in strumLine.holdsGroup)
					note.resizeByRatio(ratio);
			}
			for (note in unspawnNotes)
				note.resizeByRatio(ratio);
		}
		songSpeed = value;
		return value;
	}

    override public function create() {
		for (i in 0...2)
			camGames[i] = new FlxCamera(Std.int((FlxG.width / 2) * i), 0, Std.int(FlxG.width / 2));
		camBorder = new FlxCamera(480 - 2, 0 - 2, 320 + 4, 320 + 4);
		camGames[2] = new FlxCamera(480, 0, 320, 320);
		camHUD = new FlxCamera();
		camHUD2 = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camHUD2.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;
		
		CustomFadeTransition.nextCamera = camOther;
		super.create();
		CustomFadeTransition.nextCamera = camOther;

		FlxG.timeScale = 1;

		instance = this;

		PvPPauseSubState.songName = null; //Reset to default

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		playbackRate = ClientPrefs.getGameplaySetting('songspeed', 1);
		Conductor.playbackRate = playbackRate;

		updateTime = (ClientPrefs.timeBarType != 'Disabled');

		FlxG.cameras.reset(camGames[0]);
		for (i in 1...camGames.length) {
			if (i == 2)
				FlxG.cameras.add(camBorder, false);
			FlxG.cameras.add(camGames[i], true);
		}
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camHUD2, false);
		FlxG.cameras.add(camOther, false);

		persistentUpdate = true;

		if (PlayState.SONG == null)
			PlayState.SONG = Song.loadFromJson('test', 'test');

		if (skipStage)
			PlayState.SONG.stage = 'stage';
		PlayState.SONG.arrowSkin = PlayState.SONG.splashSkin = '';
		PlayState.SONG.skinModifier = 'base';

		/*var creditPaths = [Paths.getPreloadPath()];
		#if MODS_ALLOWED
		creditPaths.push(Paths.mods());
		#end
		for (path in creditPaths) {
			var creditsPath = path + 'data/pvpCredits.txt';
			var daCredits = CoolUtil.coolTextFile(creditsPath);
			for (credit in daCredits) {
				var splitCredit = credit.split('::');
				creditsMap.set(splitCredit[0], splitCredit[1]);
			}
		}*/

		curSong = Paths.formatToSongPath(PlayState.SONG.song);
		curSongDisplayName = Song.getDisplayName(PlayState.SONG.song);

		//songDetails = '$curSongDisplayName\n' + (creditsMap.exists(WeekData.getWeekFileName()) ? creditsMap.get(WeekData.getWeekFileName()) : creditsMap.get('default'));
		songDetails = '$curSongDisplayName\n' + WeekData.getCurrentWeek().weekName;

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

		for (arr in 0...ratingTxtTweens.length) {
			for (i in ratingsData) {
				ratingTxtTweens[arr].push(null);
			}
		}

		Conductor.mapBPMChanges(PlayState.SONG);
		Conductor.changeBPM(PlayState.SONG.bpm);
		Conductor.changeSignature(PlayState.SONG.timeSignature);

		if (PlayState.storyDifficulty > CoolUtil.difficulties.length - 1) {
			PlayState.storyDifficulty = CoolUtil.difficulties.indexOf('Normal');
			if (PlayState.storyDifficulty == -1) PlayState.storyDifficulty = 0;
		}

		#if DISCORD_ALLOWED
		storyDifficultyText = CoolUtil.difficulties[PlayState.storyDifficulty];
		detailsText = "PvP";
		detailsPausedText = 'Paused - $detailsText';
		#end

		curStage = PlayState.SONG.stage;
		if (curStage == null || curStage.length < 1) {
			curStage = StageData.getStageFromSong(curSong);
		}
		PlayState.SONG.stage = curStage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if (stageData == null) {
			curStage = 'stage';
			stageData = StageData.getStageFile(curStage);
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
		boyfriendGroup.cameras = [camGames[0], camGames[1]];
		dadGroup = new FlxTypedSpriteGroup(DAD_X, DAD_Y);
		dadGroup.cameras = [camGames[0], camGames[1]];
		gfGroup = new FlxTypedSpriteGroup(GF_X, GF_Y);

		stage = new Stage(curStage, this);
		add(stage.background);

		if(isPixelStage)
			introSoundsSuffix = '-pixel';

		add(gfGroup);
		add(stage.overGF);
		add(dadGroup);
		add(stage.overDad);
		add(boyfriendGroup);
		add(stage.foreground);

		var gfVersion:String = PlayState.SONG.gfVersion;
		if (gfVersion == null || gfVersion.length < 1) {
			gfVersion = Song.getGFVersion(curSong, curStage);
			PlayState.SONG.gfVersion = gfVersion; //Fix for the Chart Editor
		}

		if (stageData.hide_girlfriend == false)
		{
			gfGroupFile = Character.getFile(gfVersion);
			if (gfGroupFile != null && gfGroupFile.characters != null && gfGroupFile.characters.length > 0) {
				for (i in 0...gfGroupFile.characters.length) {
					addCharacter(gfGroupFile.characters[i].name, i, false, gfGroup, gfGroupFile.characters[i].position[0] + gfGroupFile.position[0], gfGroupFile.characters[i].position[1] + gfGroupFile.position[1], 0.95, 0.95);
					checkPicoSpeaker(gfGroup.members[i]);
				}
			} else {
				gfGroupFile = null;
				addCharacter(gfVersion, 0, false, gfGroup, 0, 0, 0.95, 0.95);
				checkPicoSpeaker(gfGroup.members[0]);
			}
		}

		dadGroupFile = Character.getFile(PlayState.SONG.player2);
		if (dadGroupFile != null && dadGroupFile.characters != null && dadGroupFile.characters.length > 0) {
			for (i in 0...dadGroupFile.characters.length) {
				addCharacter(dadGroupFile.characters[i].name, i, false, dadGroup, dadGroupFile.characters[i].position[0] + dadGroupFile.position[0], dadGroupFile.characters[i].position[1] + dadGroupFile.position[1]);
			}
		} else {
			dadGroupFile = null;
			addCharacter(PlayState.SONG.player2, 0, false, dadGroup);
			addCharacterToList(dad.curCharacter, 1);
		}

		bfGroupFile = Character.getFile(PlayState.SONG.player1);
		if (bfGroupFile != null && bfGroupFile.characters != null && bfGroupFile.characters.length > 0) {
			for (i in 0...bfGroupFile.characters.length) {
				addCharacter(bfGroupFile.characters[i].name, i, true, boyfriendGroup, bfGroupFile.characters[i].position[0] + bfGroupFile.position[0], bfGroupFile.characters[i].position[1] + bfGroupFile.position[1]);
			}
		} else {
			bfGroupFile = null;
			addCharacter(PlayState.SONG.player1, 0, true, boyfriendGroup);
			addCharacterToList(boyfriend.curCharacter, 0);
		}
		
		addCharacterToList(dadSwitch, 1);
		addCharacterToList(boyfriendSwitch, 0);

		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null) {
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		stage.onCharacterInit();

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		if (ClientPrefs.downScroll) strumLine.y = FlxG.height - 210;
		strumLine.scrollFactor.set();

		healthBarBG = new AttachedSprite(getUIFile('healthBar'));
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		add(healthBarBG);
		if (ClientPrefs.downScroll) healthBarBG.y = 0.11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
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

		grpRatings = new FlxTypedGroup();
		add(grpRatings);
		var dummyRating = new FlxSprite();
		dummyRating.kill();
		grpRatings.add(dummyRating);
		strumLineNotes = new FlxTypedGroup();
		add(strumLineNotes);
		grpNoteSplashes = new FlxTypedGroup();
		add(grpNoteSplashes);

		var splash:NoteSplash = new NoteSplash(100, 100, null);
		grpNoteSplashes.add(splash);
		splash.alphaMult = 0.00001;

		generateStaticArrows(0, PlayState.SONG.dadKeyAmount, false);
		generateStaticArrows(1, PlayState.SONG.boyfriendKeyAmount, true);
		strumLineNotes.add(strumMaps[0].get(PlayState.SONG.dadKeyAmount));
		strumLineNotes.add(strumMaps[1].get(PlayState.SONG.boyfriendKeyAmount));
		setKeysArray();

		generateSong();

		timeTxt = new FlxText(0, 2, 1270, songDetails, 16);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 1;
		if (ClientPrefs.downScroll) timeTxt.y = FlxG.height - 66;
		timeTxt.screenCenter(X);
		add(timeTxt);
		updateTimeTxt();

		for (i in 0...camGames.length) {
			var daCamFollow = new FlxPoint();
			var daCamFollowPos = new FlxObject(0, 0, 1, 1);
			camFollow.push(daCamFollow);
			camFollowPos.push(daCamFollowPos);

			snapCamFollowToPos(i, camPos.x, camPos.y);
			add(daCamFollowPos);

			camGames[i].follow(daCamFollowPos, LOCKON, 1);
			camGames[i].zoom = defaultCamZoom;
			camGames[i].focusOn(daCamFollow);
		}
		camHUD.zoom = defaultCamHudZoom;

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		updateCameras();

		for (player in 0...2) {
			var playerScoreTxt = new FlxText(FlxG.width / 2 * player, FlxG.height * 0.89 + 36, 640, "", 20);
			if (ClientPrefs.downScroll) playerScoreTxt.y = 0.11 * FlxG.height + 36;
			playerScoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			playerScoreTxt.scrollFactor.set();
			playerScoreTxt.borderSize = 1.25;
			playerScoreTxt.visible = !ClientPrefs.hideHud;
			playerScoreTxt.cameras = [camHUD];
			scoreTxt.push(playerScoreTxt);
			add(playerScoreTxt);

			var playerRatingTxtGroup = new FlxTypedGroup<FlxText>();
			playerRatingTxtGroup.visible = !ClientPrefs.hideHud && ClientPrefs.showRatings;
			for (i in 0...5) {
				var ratingTxt = new FlxText(20, FlxG.height * 0.5 - 8 + (16 * (i - 2)), FlxG.width, "", 16);
				if (player == 1) {
					ratingTxt.x = -20;
					ratingTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				} else {
					ratingTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				}
				ratingTxt.scrollFactor.set();
				playerRatingTxtGroup.add(ratingTxt);
			}
			playerRatingTxtGroup.cameras = [camHUD];
			ratingTxtGroup.push(playerRatingTxtGroup);
			add(playerRatingTxtGroup);
		}

		switch (curSong) {
			case 'sunshine':
				var vcr = new VCRDistortionShader();
				var daStatic:FlxSprite = new FlxSprite(0, 0);
				daStatic.frames = Paths.getSparrowAtlas('sonicexe/daSTAT');
				daStatic.setGraphicSize(FlxG.width, FlxG.height);
				daStatic.alpha = 0.05;
				daStatic.screenCenter();
				daStatic.cameras = [camHUD];
				daStatic.animation.addByPrefix('static', 'staticFLASH', 24, true);
				daStatic.animation.play('static');
				add(daStatic);
				for (camera in camGames)
					camera.setFilters([new ShaderFilter(vcr)]);
				camHUD.setFilters([new ShaderFilter(vcr)]);
		}

		winTxt = new FlxText(0, 0, 1270, "", 64);
		winTxt.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		winTxt.borderSize = 2;
		winTxt.scrollFactor.set();
		winTxt.visible = false;
		winTxt.cameras = [camOther];
		winTxt.screenCenter();
		add(winTxt);

		grpRatings.cameras = [camHUD];
		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		timeTxt.cameras = [camHUD];

		startCountdown();
		for (i in 0...2)
			recalculateRating(false, i);

		precacheList.set('missnote1', 'sound');
		precacheList.set('missnote2', 'sound');
		precacheList.set('missnote3', 'sound');

		if (PvPPauseSubState.songName != null)
			precacheList.set(PvPPauseSubState.songName, 'music');
		else if(ClientPrefs.pauseMusic != 'None')
			precacheList.set(Paths.formatToSongPath(ClientPrefs.pauseMusic), 'music');

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, '$curSongDisplayName ($storyDifficultyText)', iconP2.char);
		#end

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000 * playbackRate;

		windowNameSuffix = ' | PvP - ${WeekData.getCurrentWeek().weekName} | $curSongDisplayName [${CoolUtil.difficultyString()}]';

		cacheCountdown();
		cachePopUpScore();

		for (key => type in precacheList) {
			switch(type) {
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);
			}
		}
		Paths.clearUnusedMemory();
    }

	var sh_r:Float = 300;
	var rotInd:Float = 0;
	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		var pause = controls.PAUSE;
		var p2Switch = FlxG.keys.justPressed.ALT;
		var p1Switch = false;
		var gamepad = FlxG.gamepads.lastActive;
		if (gamepad != null) {
			if (gamepad.justPressed.START) pause = true;
			if (gamepad.justPressed.BACK) p1Switch = true;
		}

		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			setSongPitch();
		
		if (playbackRate != 1 && startedCountdown && !endingSong && !transitioning && FlxG.sound.music != null && FlxG.sound.music.length - Conductor.songPosition <= 20) {
			Conductor.songPosition = FlxG.sound.music.length;
			onSongComplete();
		}

		stage.onUpdate();

		if(phillyGlowParticles != null) {
			var i:Int = phillyGlowParticles.members.length-1;
			while (i > 0) {
				var particle = phillyGlowParticles.members[i];
				if(particle.alpha < 0) {
					particle.kill();
					phillyGlowParticles.remove(particle, true);
					particle.destroy();
				}
				--i;
			}
		}

		health += healthDrain[0];
		health -= healthDrain[1];

		for (i in 0...shakeCam2.length) {
			if (shakeCam2[i])
				camGames[i].shake(0.0025, 0.10);
		}

		if (camMove) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
			for (i in 0...camGames.length)
				camFollowPos[i].setPosition(FlxMath.lerp(camFollowPos[i].x, camFollow[i].x, lerpVal), FlxMath.lerp(camFollowPos[i].y, camFollow[i].y, lerpVal));
		}

		if (startedCountdown && !endingSong) {
			if (p1Switch) {
				if (dad.curCharacter == dadSwitch)
					triggerEventNote('Change Character', '1', PlayState.SONG.player2);
				else
					triggerEventNote('Change Character', '1', dadSwitch);
			}
			if (p2Switch) {
				if (boyfriend.curCharacter == boyfriendSwitch)
					triggerEventNote('Change Character', '0', PlayState.SONG.player1);
				else
					triggerEventNote('Change Character', '0', boyfriendSwitch);
			}
		}

		floatY += elapsed * 1.8;
		rotInd += elapsed * 60;

		var grps = [dadGroup, boyfriendGroup];
		var icons = [iconP2, iconP1];
		for (i in 0...grps.length) {
			var grp = grps[i];
			var mult = (i > 0 ? -1 : 1);
			for (char in grp) {
				switch (char.curCharacter) {
					case 'TDoll' | 'TDollAlt':
						char.addX += Math.cos(floatY) * 1.3 * mult;
						char.addY += Math.sin(floatY) * 1.3;
					case 'fleetway' | 'Sarah':
						char.addY += Math.sin(floatY) * 1.3;
					case 'pshaggy':
						var rotRateSh = (curStep / 9.5) * 1.2;
						var sh_tox = char.defaultX - (Math.cos(rotRateSh) * sh_r) * mult;
						var sh_toy = char.defaultY - Math.sin(rotRateSh * 2) * sh_r * 0.45;
						char.addX += (sh_tox - char.x) / 12;
						char.addY += (sh_toy - char.y) / 12;
						if (char.animation.name.startsWith('idle') || char.animation.name.startsWith('dance')) {
							var pene = 0.07;
							char.angle = Math.sin(rotRateSh) * sh_r * pene / 4;

							pshaggyLegs.get(char).alpha = 1;
							pshaggyLegs.get(char).angle = Math.sin(rotRateSh) * sh_r * pene;

							pshaggyLegs.get(char).x = char.x + 120 + Math.cos((pshaggyLegs.get(char).angle + 90) * (Math.PI/180)) * 150;
							pshaggyLegs.get(char).y = char.y + 300 + Math.sin((pshaggyLegs.get(char).angle + 90) * (Math.PI/180)) * 150;
						} else {
							char.angle = 0;
							pshaggyLegs.get(char).alpha = 0;
						}
						pshaggyLegT.get(char).visible = (pshaggyLegs.get(char).alpha > 0);
					case 'wbshaggy':
						var rot = rotInd / 6;
						char.addX = (Math.cos(rot / 3) * 20) * mult;
						char.addY = Math.cos(rot / 5) * 40;
					case 'guy':
						if ((i == 0 && healthBar.percent > 80) || (i == 1 && healthBar.percent < 20))
							icons[i].angle = FlxG.random.int(-5, 5);
						else
							icons[i].angle = 0;
				}
				char.x = char.defaultX + char.addX;
				char.y = char.defaultY + char.addY;
			}
		}

		if (startedCountdown && PlayState.SONG.notes[curSection] != null && !endingSong && !isCameraOnForcedPos)
			updateCameras();

		if (pause && startedCountdown && canPause)
			openPauseMenu();

		if (ClientPrefs.smoothHealth)
			shownHealth = FlxMath.lerp(shownHealth, health, CoolUtil.boundTo(elapsed * 7, 0, 1));
		else
			shownHealth = health;

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 1, 0))) + ((150 * iconP1.scale.x - 150) / 2);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 1, 0))) - 150 - ((150 * iconP2.scale.x - 150) / 2);

		if (health > 2)
			health = 2;
		else if (health < 0)
			health = 0;

		var stupidIcons:Array<HealthIcon> = [iconP1, iconP2];
		if (healthBar.percent < 20) {
			stupidIcons[0].playAnim('losing');
			stupidIcons[1].playAnim('winning');
		} else if (healthBar.percent > 80) {
			stupidIcons[0].playAnim('winning');
			stupidIcons[1].playAnim('losing');
		} else {
			stupidIcons[0].playAnim('normal');
			stupidIcons[1].playAnim('normal');
		}

		if (startingSong) {
			if (startedCountdown) {
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		} else {
			if (!endingSong)
				Conductor.songPosition += FlxG.elapsed * 1000;
		}

		if (!paused)
			updateTimeTxt();

		if (camZooming) {
			for (i in 0...camGames.length)
				camGames[i].zoom = FlxMath.lerp(defaultCamZoom, camGames[i].zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay), 0, 1));
			camHUD.zoom = FlxMath.lerp(defaultCamHudZoom, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay), 0, 1));
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		if (generatedMusic && unspawnNotes[0] != null) {
			var time:Float = spawnTime;
			if (songSpeed < 1) time /= songSpeed;
			if (unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;
			if (camHUD.zoom < 1) time /= camHUD.zoom;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time) {
				var dunceNote:Note = unspawnNotes[0];

				//Change the selected strumline here!
				var strumID = (dunceNote.isOpponent ? 0 : 1);

				dunceNote.characters = [];
				strumLineNotes.members[strumID].push(dunceNote);
				dunceNote.spawned = true;

				unspawnNotes.splice(unspawnNotes.indexOf(dunceNote), 1);

				if (unspawnNotes[0] != null) {
					time = spawnTime;
					if (songSpeed < 1) time /= songSpeed;
					if (unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;
					if (camHUD.zoom < 1) time /= camHUD.zoom;
				}
			}
		}

		if (!endingSong)
			noteFunctions();

		for (arr in 0...ratingTxtGroup.length) {
			for (i in 0...ratingTxtGroup[arr].members.length) {
				var rating = ratingTxtGroup[arr].members[i];
				if (i < ratingsData.length)
					rating.text = '${ratingsData[i].displayName}: ${Reflect.field(this, ratingsData[i].counter)[arr]}';
				else
					rating.text = 'Fails: ${songMisses[arr]}';
			}
		}

		#if debug
		if (!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				killNotes();
				FlxG.sound.music.onComplete();
			}
			if (FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000 * playbackRate);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end
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

			stage.onOpenSubState();

			var chars = [boyfriendGroup, gfGroup, dadGroup];
			for (i in 0...chars.length) {
				for (char in chars[i]) {
					if (char.colorTween != null) {
						char.colorTween.active = false;
					}
				}
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
			
			stage.onCloseSubState();

			var chars = [boyfriendGroup, gfGroup, dadGroup];
			for (i in 0...chars.length) {
				for (char in chars[i]) {
					if (char.colorTween != null) {
						char.colorTween.active = true;
					}
				}
			}
			
			paused = false;
			persistentUpdate = true;

			#if DISCORD_ALLOWED
			if (startTimer != null && startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, '$curSongDisplayName ($storyDifficultyText)', iconP2.char, true, (songLength - Conductor.songPosition) / playbackRate - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, '$curSongDisplayName ($storyDifficultyText)', iconP2.char);
			}
			#end

			Paths.clearUnusedMemory();
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		if (!paused) {
			if (FlxG.sound.music != null && !startingSong && !endingSong)
				resyncVocals();
			#if DISCORD_ALLOWED
			if (Conductor.songPosition > 0.0)
				DiscordClient.changePresence(detailsText, '$curSongDisplayName ($storyDifficultyText)', iconP2.char, true, (songLength - Conductor.songPosition) / playbackRate - ClientPrefs.noteOffset);
			else
				DiscordClient.changePresence(detailsText, '$curSongDisplayName ($storyDifficultyText)', iconP2.char);
			#end
		}

		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		if (ClientPrefs.focusLostPause && !paused && startedCountdown && canPause) {
			openPauseMenu();
			FlxG.sound.music.pause();
			vocals.pause();
			vocalsDad.pause();
		} else if (ClientPrefs.autoPause) {
			#if DISCORD_ALLOWED
			DiscordClient.changePresence(detailsPausedText, '$curSongDisplayName ($storyDifficultyText)', iconP2.char);
			#end
		}

		super.onFocusLost();
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();
		if (generatedMusic && (Math.abs(FlxG.sound.music.time - Conductor.songPosition) > 20 * playbackRate
			|| (PlayState.SONG.needsVoices && ((Math.abs(vocals.time - Conductor.songPosition) > 20 * playbackRate) 
			|| (foundDadVocals && Math.abs(vocalsDad.time - Conductor.songPosition) > 20 * playbackRate)))))
			resyncVocals();

		if (curStep == lastStepHit)
			return;

		var grps = [dadGroup, boyfriendGroup];
		var icons = [iconP2, iconP1];
		for (i in 0...grps.length) {
			var grp = grps[i];
			var mult = (i > 0 ? -1 : 1);
			for (char in grp) {
				switch (char.curCharacter) {
					case 'guy':
						if (curStep % 2 == 0 && (i == 0 && healthBar.percent > 80) || (i == 1 && healthBar.percent < 20)) {
							guyFlipped[i] = !guyFlipped[i];
							icons[i].flipX = guyFlipped[i];
						}
				}
			}
		}

		if (ClientPrefs.gameQuality != 'Crappy' && curStep >= 0)
			stage.onStepHit();

		lastStepHit = curStep;
	}

	var lastBeatHit:Int = -1;
	var guyFlipped:Array<Bool> = [true, true];
	var guyFlippedIdle:Array<Bool> = [false, true];
	override function beatHit()
	{
		super.beatHit();

		if (lastBeatHit >= curBeat)
			return;

		var curNumeratorBeat = Conductor.getCurNumeratorBeat(PlayState.SONG, curBeat);

		var grps = [dadGroup, boyfriendGroup];
		var icons = [iconP2, iconP1];
		for (i in 0...grps.length) {
			var grp = grps[i];
			var mult = (i > 0 ? -1 : 1);
			for (char in grp) {
				switch (char.curCharacter) {
					case 'guy':
						if (char.animation.name == 'idle') {
							guyFlippedIdle[i] = !guyFlippedIdle[i];
							char.flipX = guyFlippedIdle[i];
							char.addY = 20;
							FlxTween.tween(char, {addY: 0}, 0.15, {ease: FlxEase.cubeOut});
						}
				}
			}
		}

		if (ClientPrefs.camZooms && camZooming && camBop) {
			for (i in 0...camGames.length) {
				if (camGames[i].zoom < 1.35)
					camGames[i].zoom += 0.0075 * camZoomingMult;
			}
			camHUD.zoom += 0.0075 * camZoomingMult;
		}

		if (iconBopSpeed > 0 && curBeat % Math.round((iconBopSpeed * (Conductor.timeSignature[1] / 4))) == 0) {
			iconP1.scale.set(1.2, 1.2);
			iconP2.scale.set(1.2, 1.2);
			iconP1.updateHitbox();
			iconP2.updateHitbox();

			for (i in 0...grps.length) {
				var grp = grps[i];
				for (char in grp) {
					switch (char.curCharacter) {
						case 'guy':
							if ((i == 0 && healthBar.percent < 80) || (i == 1 && healthBar.percent > 20)) {
								guyFlipped[i] = !guyFlipped[i];
								icons[i].flipX = guyFlipped[i];
							}
					}
				}
			}
		}

		if (curBeat >= 0 && !endingSong) {
			var chars = [boyfriendGroup, dadGroup, gfGroup];
			for (group in chars) {
				for (char in group) {
					var notSinging = (!FlxG.keys.anyPressed(char.keysPressed) && char.holdTimer > Conductor.normalizedStepCrochet * 0.0011 * char.singDuration && char.animation.curAnim != null && char.animation.curAnim.name.startsWith('sing') && !char.animation.curAnim.name.endsWith('miss'));
					if (char.danceEveryNumBeats > 0 && curNumeratorBeat % (Math.round(char.danceEveryNumBeats * (Conductor.timeSignature[1] / 4))) == 0 && !char.stunned && char.animation.curAnim != null && (!char.animation.curAnim.name.startsWith("sing") || notSinging)) {
						char.dance(true);
						if (group == boyfriendGroup) {
							boyfriendCamX = 0;
							boyfriendCamY = 0;
						} else if (group == dadGroup) {
							dadCamX = 0;
							dadCamY = 0;
						}
					}
				}
			}
		}

		if (ClientPrefs.gameQuality != 'Crappy' && curBeat >= 0)
			stage.onBeatHit();

		lastBeatHit = curBeat;
	}

	override function sectionHit() {
		super.sectionHit();
		
		var songSection = PlayState.SONG.notes[curSection];
		if (songSection != null) {
			if (songSection.changeBPM && songSection.bpm != Conductor.bpm)
				Conductor.changeBPM(songSection.bpm);
			if (songSection.changeSignature && (songSection.timeSignature[0] != Conductor.timeSignature[0] || songSection.timeSignature[1] != Conductor.timeSignature[1]))
				Conductor.changeSignature(songSection.timeSignature);
		}
	}

	override function destroy() {
		FlxG.timeScale = 1;
		Conductor.playbackRate = 1;
		
		vocals.stop();
		vocals.destroy();
		vocalsDad.stop();
		vocalsDad.destroy();

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		super.destroy();

		instance = null;
	}

	public function killNotes() {
		for (strumLine in strumLineNotes) {
			while(strumLine.allNotes.length > 0) {
				var daNote:Note = strumLine.allNotes.members[0];
				daNote.active = false;
				daNote.visible = false;
	
				daNote.kill();
				strumLine.removeNote(daNote);
				daNote.destroy();
			}
		}
		unspawnNotes = [];
		eventNotes = [];
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
				if (!daNote.ignoreNote) {
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
					if (!daNote.ignoreNote) {
						camZooming = true;
						camBop = true;
					}
					daNote.active = false;
					daNote.visible = false;
					daNote.ignoreNote = true;

					daNote.kill();
					strumLine.removeNote(daNote);
					daNote.destroy();
				}
				--i;
			}
		}
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
				for (i in audio) {
					if (i != null && i.playing && i._channel != null && i._channel.__source != null && i._channel.__source.__backend != null && i._channel.__source.__backend.handle != null) {
						AL.sourcef(i._channel.__source.__backend.handle, AL.PITCH, playbackRate);
					}
				}
			}
		}
		#end
	}

	function noteFunctions() {
		if (generatedMusic) {
			for (i in 0...strumLineNotes.length) {
				strumLineNotes.members[i].allNotes.forEachAlive(function(daNote:Note)
				{
					var strumLine = strumLineNotes.members[i];
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

						if (daNote.isSustainNote && strumScroll)
							daNote.flipY = true;
		
						strumX += daNote.offsetX;
						strumY += daNote.offsetY;
						strumAngle += daNote.offsetAngle;
						strumAlpha *= daNote.multAlpha;
						if (Conductor.songPosition < 0)
							strumAlpha = daNote.multAlpha;
						if (daNote.tooLate)
							strumAlpha *= 0.3;
		
						if (strumScroll) //Downscroll
							daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * noteSpeed);
						else //Upscroll
							daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * noteSpeed);
		
						var angleDir = strumDirection * Math.PI / 180;
						if (daNote.copyAngle)
							daNote.angle = strumDirection - 90 + strumAngle;
		
						if (daNote.copyAlpha)
							daNote.alpha = strumAlpha;
						
						if (daNote.copyX)
							daNote.x = strumX + Math.cos(angleDir) * daNote.distance;
		
						if (daNote.copyY) {
							daNote.y = strumY + Math.sin(angleDir) * daNote.distance;
		
							if (daNote.isSustainNote && strumScroll) {
								if (daNote.animation.curAnim.name.endsWith('end')) {
									daNote.y += 10.5 * (daNote.stepCrochet * 4 / 400) * 1.5 * noteSpeed + (46 * (noteSpeed - 1));
									daNote.y -= 46 * (1 - (daNote.stepCrochet * 4 / 600)) * noteSpeed;
									if(PlayState.SONG.skinModifier.endsWith('pixel')) {
										daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * PlayState.daPixelZoom;
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
							goodNoteHit(daNote, i);
						}

						if(!daNote.blockHit && daNote.mustPress && strumLine.botPlay && daNote.canBeHit) {
							if(daNote.strumTime <= Conductor.songPosition || daNote.isSustainNote) {
								goodNoteHit(daNote, i);
							}
						}

		
						if (daStrum.sustainReduce && daNote.isSustainNote && (daNote.mustPress || !daNote.ignoreNote) &&
							(!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit)))) {
							var center:Float = strumY + strumHeight / 2;
							if (strumScroll) {
								if (daNote.y + daNote.height >= center) {
									if (daNote.clipRect != null)
										daNote.clipRect = null;
									var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
									swagRect.height = (center - daNote.y) / daNote.scale.y;
									swagRect.y = daNote.frameHeight - swagRect.height;
		
									daNote.clipRect = swagRect;
								}
							} else {
								if (daNote.y <= center) {
									if (daNote.clipRect != null)
										daNote.clipRect = null;
									var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
									swagRect.y = (center - daNote.y) / daNote.scale.y;
									swagRect.height -= swagRect.y;
		
									daNote.clipRect = swagRect;
								}
							}
						}
		
						// Kill extremely late notes and cause misses
						if (daNote.exists && Conductor.songPosition > daNote.strumTime + (noteKillOffset / noteSpeed) && (daNote.isSustainNote || !strumLine.botPlay)) {
							if (daNote.mustPress && !daNote.ignoreNote && (daNote.tooLate || !daNote.wasGoodHit))
								noteMiss(daNote, i);
		
							daNote.active = false;
							daNote.visible = false;
		
							daNote.kill();
							strumLine.removeNote(daNote);
							daNote.destroy();
						}
					}
				});
			}
			checkEventNote();
		}
		keyShit();
	}

	public function openPauseMenu() {
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
		openSubState(new PvPPauseSubState());

		#if DISCORD_ALLOWED
		DiscordClient.changePresence(detailsPausedText, '$curSongDisplayName ($storyDifficultyText)', iconP2.char);
		#end
	}

	function startSong():Void
	{
		startingSong = false;

		FlxG.sound.playMusic(Paths.inst(curSong, CoolUtil.getDifficultyFilePath()), 1, false);
		if (playbackRate == 1) FlxG.sound.music.onComplete = onSongComplete;
		vocals.play();
		vocalsDad.play();

		setSongPitch();

		if (paused) {
			FlxG.sound.music.pause();
			vocals.pause();
			vocalsDad.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
	
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, '$curSongDisplayName ($storyDifficultyText)', iconP2.char, true, songLength / playbackRate);
		#end
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

	public function endSong():Void
	{
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		camBop = false;
		updateTime = false;

		FlxG.timeScale = 1;

		isCameraOnForcedPos = true;
		for (i in 0...songScore.length) {
			songScore[i] = Math.round(songScore[i]);
		}
		var charGroup = boyfriendGroup;
		var gfAnim = 'cheer';
		if (songScore[1] > songScore[0]) {
			winTxt.text = "Player 1 wins!";
			tweenCamIn(1);
			camGames[0].fade(FlxColor.BLACK, 1);
		} else if (songScore[0] > songScore[1]) {
			winTxt.text = "Player 2 wins!";
			charGroup = dadGroup;
			tweenCamIn(0);
			camGames[1].fade(FlxColor.BLACK, 1);
			gfAnim = 'sad';
		} else {
			winTxt.text = "Tie!";
			charGroup = null;
		}
		winTxt.screenCenter();
		winTxt.visible = true;
		if (charGroup != null) {
			for (char in charGroup) {
				if (char.animation.exists('hey')) {
					char.playAnim('hey', true);
				} else {
					char.playAnim('singUP', true);
				}
			}
			for (char in gfGroup) {
				if (char.animation.exists(gfAnim)) {
					char.playAnim(gfAnim, true);
				}
			}
		}
		new FlxTimer().start(3, function(tmr) {
			exit();
		});
	}

	function exit() {
		cancelMusicFadeTween();
		if (FlxTransitionableState.skipNextTransIn)
			CustomFadeTransition.nextCamera = null;
		MusicBeatState.switchState(new PvPSongState());
		CoolUtil.playMenuMusic();
		transitioning = true;
	}

	public static function cancelMusicFadeTween() {
		if (FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	private function generateSong():Void
	{
		songSpeed = CoolUtil.boundTo(CoolUtil.scrollSpeedFromBPM(PlayState.SONG.bpm, PlayState.SONG.timeSignature[1]), 0.1, 3.5);

		if (PlayState.SONG.needsVoices) {
			vocals = new FlxSound().loadEmbedded(Paths.voices(curSong, CoolUtil.getDifficultyFilePath()));

			vocalsDad = new FlxSound();
			var file = Paths.voicesDad(PlayState.SONG.song, CoolUtil.getDifficultyFilePath());
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

		var inst = new FlxSound().loadEmbedded(Paths.inst(curSong, CoolUtil.getDifficultyFilePath()));
		FlxG.sound.list.add(inst);
		songLength = inst.length;

		trace('generated music');

		unspawnNotes = Song.generateNotes(PlayState.SONG, strumLineNotes.members[0], strumLineNotes.members[1], onNotePush, true);
		trace('generated notes');

		//eventNotes = Song.generateEventNotes(PlayState.SONG, eventPushed, eventNoteEarlyTrigger);
		eventNotes = [];
		for (i in eventNotes) {
			if (i.event == 'Change Scroll Speed' || i.event == 'Change Character')
				eventNotes.remove(i);
		}
		var curBPM = Conductor.bpm;
		var curDenominator = Conductor.timeSignature[1];
		for (i in 0...Conductor.bpmChangeMap.length) {
			var bpmChange = Conductor.bpmChangeMap[i];
			if (curBPM != bpmChange.bpm || curDenominator != bpmChange.timeSignature[1]) {
				var scrollSpeed = CoolUtil.boundTo(CoolUtil.scrollSpeedFromBPM(bpmChange.bpm, bpmChange.timeSignature[1]), 0.1, 3.5);
				var subEvent:EventNote = {
					strumTime: bpmChange.songTime,
					event: 'Change Scroll Speed',
					value1: '${scrollSpeed / songSpeed}',
					value2: '0.5'
				};
				eventNotes.push(subEvent);
				curBPM = bpmChange.bpm;
				curDenominator = bpmChange.timeSignature[1];
			}
		}
		trace('generated events');

		if (unspawnNotes.length > 1)
			unspawnNotes.sort(sortByShit);

		if (eventNotes.length > 1)
			eventNotes.sort(sortByTime);

		Paths.image(getNoteFile('noteSplashes'));
		if (boyfriendNotes > dadNotes && boyfriendNotes > 0) {
			boyfriendScoreMult = (dadNotes / boyfriendNotes);
		} else if (dadNotes > boyfriendNotes && dadNotes > 0) {
			dadScoreMult = (boyfriendNotes / dadNotes);
		}
		trace(dadNotes, boyfriendNotes);
		trace(dadScoreMult, boyfriendScoreMult);

		checkEventNote();
		generatedMusic = true;
	}

	var noteTypeMap:Map<String, Bool> = new Map();
	var boyfriendNotes:Int = 0;
	var dadNotes:Int = 0;
	function onNotePush(array:Array<Note>) {
		var note = array[array.length - 1];
		if (note.strumTime >= songLength) {
			note.kill();
			array.remove(note);
			note.destroy();
		}
		if (note.noteData > -1) {
			if (ClientPrefs.noteSplashes && note.noteSplashTexture != null && note.noteSplashTexture.length > 0 && !note.noteSplashDisabled && !precacheList.exists(getNoteFile(note.noteSplashTexture)))
				Paths.image(getNoteFile(note.noteSplashTexture));
			if (!note.isSustainNote && !note.ignoreNote && !note.hitCausesMiss) {
				if (note.isOpponent) dadNotes += 1;
				else boyfriendNotes += 1;
			}
			if (!noteTypeMap.exists(note.noteType)) {
				switch (note.noteType) {
					case 'Static Note':
						var dummyStatic = new FlxSprite();
						dummyStatic.frames = Paths.getSparrowAtlas('sonicexe/hitStatic');
						dummyStatic.animation.addByPrefix('static', 'staticANIMATION', 24, false);
						dummyStatic.animation.play('static');
						dummyStatic.alpha = 0.00001;
						dummyStatic.cameras = [camHUD2];
						add(dummyStatic);
						Paths.sound('sonicexe/hitStatic1');
				}
				noteTypeMap.set(note.noteType, true);
			}
		}
	}

	function cacheCountdown()
	{
		var introAlts:Array<String> = ['ready', 'set', 'go'];
		for (asset in introAlts)
			precacheList.set(getUIFile(asset), 'image');

		precacheList.set('intro3' + introSoundsSuffix, 'sound');
		precacheList.set('intro2' + introSoundsSuffix, 'sound');
		precacheList.set('intro1' + introSoundsSuffix, 'sound');
		precacheList.set('introGo' + introSoundsSuffix, 'sound');
	}

	public function startCountdown():Void
	{
		if (startedCountdown)
			return;

		FlxG.timeScale = playbackRate;
		if (skipCountdown) skipArrowStartTween = true;

		startedCountdown = true;

		Conductor.songPosition = 0;
		Conductor.songPosition -= 2500;

		var swagCounter:Int = 0;

		if (skipCountdown)
		{
			setSongTime(0);
			return;
		}
		startTimer = new FlxTimer().start(0.5, function(tmr:FlxTimer)
		{
			if (swagCounter < 4) {
				var chars = [boyfriendGroup, dadGroup];
				for (group in chars) {
					for (char in group) {
						if (char.danceEveryNumBeats > 0 && tmr.loopsLeft % Math.round(char.danceEveryNumBeats) == 0 && char.animation.curAnim != null && !char.animation.curAnim.name.startsWith("sing"))
							char.dance(true);
					}
				}

				stage.onCountdownTick();
			}

			switch (swagCounter)
			{
				case 0:
					FlxG.sound.play(Paths.sound('intro3$introSoundsSuffix'), 0.6);
				case 1:
					countdownReady = new FlxSprite().loadGraphic(Paths.image(getUIFile('ready')));
					countdownReady.cameras = [camHUD];
					countdownReady.scrollFactor.set();
					countdownReady.updateHitbox();

					if (PlayState.SONG.skinModifier.endsWith('pixel'))
						countdownReady.setGraphicSize(Std.int(countdownReady.width * PlayState.daPixelZoom));

					countdownReady.screenCenter();
					countdownReady.antialiasing = ClientPrefs.globalAntialiasing && !PlayState.SONG.skinModifier.endsWith('pixel');
					insert(members.indexOf(strumLineNotes), countdownReady);
					FlxTween.tween(countdownReady, {alpha: 0}, 0.5, {
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
					countdownSet.cameras = [camHUD];
					countdownSet.scrollFactor.set();

					if (PlayState.SONG.skinModifier.endsWith('pixel'))
						countdownSet.setGraphicSize(Std.int(countdownSet.width * PlayState.daPixelZoom));

					countdownSet.screenCenter();
					countdownSet.antialiasing = ClientPrefs.globalAntialiasing && !PlayState.SONG.skinModifier.endsWith('pixel');
					insert(members.indexOf(strumLineNotes), countdownSet);
					FlxTween.tween(countdownSet, {alpha: 0}, 0.5, {
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
					countdownGo.cameras = [camHUD];
					countdownGo.scrollFactor.set();

					if (PlayState.SONG.skinModifier.endsWith('pixel'))
						countdownGo.setGraphicSize(Std.int(countdownGo.width * PlayState.daPixelZoom));

					countdownGo.updateHitbox();

					countdownGo.screenCenter();
					countdownGo.antialiasing = ClientPrefs.globalAntialiasing && !PlayState.SONG.skinModifier.endsWith('pixel');
					insert(members.indexOf(strumLineNotes), countdownGo);
					FlxTween.tween(countdownGo, {alpha: 0}, 0.5, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							remove(countdownGo);
							countdownGo.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('introGo$introSoundsSuffix'), 0.6);
			}

			swagCounter += 1;
		}, 5);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE) {
			for (i in 0...keysArray.length) {
				for (j in 0...keysArray[i].length) {
					if (key == keysArray[i][j])
						return i;
				}
			}
		}
		return -1;
	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		if (!paused) {
			var eventKey:FlxKey = event.keyCode;
			var key:Int = getKeyFromEvent(eventKey);

			if (key > -1 && FlxG.keys.checkStatus(eventKey, JUST_PRESSED)) {
				if (!dadGroup.members[0].stunned && !endingSong)
					strumPressed(key, 1, [eventKey]);
			}
		}
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		if (!paused) {
			var eventKey:FlxKey = event.keyCode;
			var key:Int = getKeyFromEvent(eventKey);
			if (key > -1) {
				var spr:StrumNote = strumLineNotes.members[1].receptors.members[key];
				if (spr != null) {
					spr.playAnim('static');
					spr.resetAnim = 0;
				}
			}
		}
	}

	// Hold notes + controller input
	private function keyShit():Void
	{
		// HOLDING
		var controlHoldArray:Array<Bool> = [];
		for (i in keysArray) {
			controlHoldArray.push(FlxG.keys.anyPressed(i));
		}

		if (controlHoldArray.contains(true) && !boyfriendGroup.members[0].stunned && generatedMusic)
		{
			// rewritten inputs???
			strumLineNotes.members[1].allNotes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit 
				&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) {
					goodNoteHit(daNote, 1, keysArray[daNote.noteData]);
				}
			});
		}

		//ALL BOYFRIEND INPUTS HERE
		var gamepad = FlxG.gamepads.lastActive;
		if (gamepad != null && !boyfriendGroup.members[0].stunned) {
			var controlArray:Array<Bool> = [gamepad.justPressed.LEFT_TRIGGER, gamepad.justPressed.LEFT_SHOULDER, gamepad.justPressed.RIGHT_SHOULDER, gamepad.justPressed.RIGHT_TRIGGER];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						strumPressed(i, 0, null, true);
				}
			}

			controlHoldArray = [gamepad.pressed.LEFT_TRIGGER, gamepad.pressed.LEFT_SHOULDER, gamepad.pressed.RIGHT_SHOULDER, gamepad.pressed.RIGHT_TRIGGER];
			if (controlHoldArray.contains(true) && generatedMusic)
			{
				// rewritten inputs???
				strumLineNotes.members[0].allNotes.forEachAlive(function(daNote:Note)
				{
					// hold note functions
					if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit 
					&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) {
						goodNoteHit(daNote, 0, keysArray[daNote.noteData], true);
					}
				});
			}

			var controlReleaseArray:Array<Bool> = [gamepad.justReleased.LEFT_TRIGGER, gamepad.justReleased.LEFT_SHOULDER, gamepad.justReleased.RIGHT_SHOULDER, gamepad.justReleased.RIGHT_TRIGGER];
			if(controlReleaseArray.contains(true))
			{
				for (i in 0...controlReleaseArray.length)
				{
					if(controlReleaseArray[i]) {
						var spr:StrumNote = strumLineNotes.members[0].receptors.members[i];
						if (spr != null)
						{
							spr.playAnim('static');
							spr.resetAnim = 0;
						}
					}
				}
			}
		}
	}

	function strumPressed(key:Int = 0, player:Int = 0, ?eventKey:Array<FlxKey>, isGamepad:Bool = false) {
		var strumGroup = strumLineNotes.members[player];
		if (strumGroup.botPlay) return;
		var lastTime:Float = Conductor.songPosition;
		if (generatedMusic) {
			//more accurate hit time for the ratings?
			Conductor.songPosition = FlxG.sound.music.time;
		}

		// heavily based on my own code LOL if it aint broke dont fix it
		var pressNotes:Array<Note> = [];
		var notesStopped:Bool = false;
		var foundNote:Bool = false;

		var sortedNotesList:Array<Note> = [];
		strumGroup.allNotes.forEachAlive(function(daNote:Note) {
			if (daNote.noteData == key && daNote.canBeHit && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) {
				foundNote = true; //needed to detect sustain notes and not cause a misspress
				if (!daNote.isSustainNote)
					sortedNotesList.push(daNote);
			}
		});
		sortedNotesList.sort(sortHitNotes);

		if (sortedNotesList.length > 0) {
			for (epicNote in sortedNotesList) {
				for (doubleNote in pressNotes) {
					if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
						songScore[player] += ratingsData[0].score * (player == 0 ? dadScoreMult : boyfriendScoreMult);
						doubleNote.kill();
						strumGroup.removeNote(doubleNote);
						doubleNote.destroy();
					} else
						notesStopped = true;
				}
					
				// eee jack detection before was not super good
				if (!notesStopped) {
					goodNoteHit(epicNote, player, eventKey, isGamepad);
					pressNotes.push(epicNote);
				}

			}
		} else if (!foundNote) {
			noteMissPress(key, player, eventKey);
		}

		if (generatedMusic) {
			//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
			Conductor.songPosition = lastTime;
		}
		
		var spr:StrumNote = strumGroup.receptors.members[key];
		if (spr != null && spr.animation.curAnim.name != 'confirm') {
			spr.playAnim('pressed');
			spr.resetAnim = 0;
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

	function goodNoteHit(note:Note, player:Int = 0, ?keys:Array<FlxKey>, isGamepad:Bool = false):Void
	{
		if (keys == null) keys = [];
		if (!note.mustPress || !note.wasGoodHit)
		{
			var strumGroup = strumLineNotes.members[player];
			if (strumGroup.botPlay && (note.ignoreNote || note.hitCausesMiss)) return;

			var charGroup = note.isOpponent ? dadGroup : boyfriendGroup;
			if (note.gfNote) charGroup = gfGroup;

			var characters = note.characters.copy();
			if (characters.length < 1) {
				for (i in 0...charGroup.length) {
					characters.push(i);
				}
			}

			if (!strumGroup.botPlay) {
				var spr = strumGroup.receptors.members[note.noteData];
				if(spr != null) {
					spr.playAnim('confirm', true);
				}
			}

			if (note.hitCausesMiss) {
				noteMiss(note, player);
				if (!note.noteSplashDisabled && !note.isSustainNote) {
					spawnNoteSplashOnNote(note, strumGroup);
				}

				if (note.playAnim != null && note.playAnim.length > 0) {
					for (i in characters) {
						if (i < charGroup.members.length && charGroup.members[i] != null && charGroup.members[i].animation.exists(note.playAnim)) {
							charGroup.members[i].playAnim(note.playAnim, true);
							charGroup.members[i].specialAnim = true;
						}
					}
				}
				
				note.wasGoodHit = true;
				if (!strumGroup.receptors.members[note.noteData].sustainReduce || !note.isSustainNote)
				{
					note.kill();
					strumGroup.removeNote(note);
					note.destroy();
				}
				return;
			}

			camZooming = true;
			camBop = true;

			if (!note.isSustainNote)
			{
				combo[player] += 1;
				if (combo[player] > 9999) combo[player] = 9999;
				popUpScore(note, player);
			}
			else
			{
				health += note.hitHealth * (player == 0 ? -1 : 1) * 0.5;
			}

			var altAnim:String = note.animSuffix;

			var ogAnim:String = strumGroup.animations[note.noteData];
			var xAdd:Float = 0;
			var yAdd:Float = 0;
			switch (ogAnim) {
				case 'singLEFT':
					xAdd = -30;
				case 'singDOWN':
					yAdd = 30;
				case 'singUP':
					yAdd = -30;
				case 'singRIGHT':
					xAdd = 30;
			}
			if (!note.gfNote) {
				if (note.isOpponent) {
					dadCamX = xAdd;
					dadCamY = yAdd;
				} else {
					boyfriendCamX = xAdd;
					boyfriendCamY = yAdd;
				}
			}

			for (i in characters) {
				if (i < charGroup.members.length && charGroup.members[i] != null && !charGroup.members[i].skipSing) {
					var didSing = false;
					var char = charGroup.members[i];
					if (note.playAnim != null && note.playAnim.length > 0) {
						var animToPlay:String = note.playAnim + altAnim;
						if (!char.animation.exists(animToPlay))
							animToPlay = note.playAnim;
						if (char.animation.exists(animToPlay)) {
							char.playAnim(note.playAnim, true);
							char.specialAnim = true;
							didSing = true;
							switch (char.curCharacter) {
								case 'guy':
									char.addY = 0;
							}
						}
					} else {
						var animToPlay:String = ogAnim + altAnim;
						if (!char.animation.exists(animToPlay))
							animToPlay = ogAnim;
						if (char.animation.exists(animToPlay)) {
							if (!note.isSustainNote || char.repeatHoldAnimation) char.playAnim(animToPlay, true);
							char.holdTimer = 0;
							if (keys != null) char.keysPressed = keys;
							didSing = true;
							
						}
					}

					if (didSing) {
						switch (char.curCharacter) {
							case 'guy':
								char.addY = 0;
								char.y = char.defaultY;
								guyFlippedIdle[player] = char.flipped;
								char.flipX = char.flipped;
						}
					}
				}
			}

			if (note.noteType == 'Hey!') {
				for (i in characters) {
					if (i < charGroup.members.length && charGroup.members[i] != null && charGroup.members[i].animation.exists('hey')) {
						if (!note.isSustainNote || charGroup.members[i].repeatHoldAnimation) charGroup.members[i].playAnim('hey', true);
						charGroup.members[i].specialAnim = true;
						charGroup.members[i].heyTimer = 0.6;
					}
				}

				for (gf in gfGroup) {
					if (gf.animation.exists('cheer')) {
						if (!note.isSustainNote || gf.repeatHoldAnimation) gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
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

			if (!note.mustPress) note.hitByOpponent = true;

			if (!strumGroup.receptors.members[note.noteData].sustainReduce || !note.isSustainNote)
			{
				note.kill();
				strumGroup.removeNote(note);
				note.destroy();
			}
		}
	}

	function noteMiss(daNote:Note, player:Int = 0):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		var strumGroup = strumLineNotes.members[player];
		//Dupe note remove
		strumGroup.allNotes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				if (!note.isSustainNote) songScore[player] += ratingsData[0].score * (player == 0 ? dadScoreMult : boyfriendScoreMult);
				note.kill();
				strumGroup.removeNote(note);
				note.destroy();
			}
		});
		combo[player] = 0;
		health -= daNote.missHealth * (player == 0 ? -1 : 1);

		songMisses[player]++;
		switch (daNote.noteType) {
			case 'Static Note':
				songScore[player] -= 350;
			case 'Phantom Note':
				songScore[player] -= 100;
			default:
				songScore[player] -= daNote.missScore;
		}
		
		totalPlayed[player]++;
		recalculateRating(true, player);
		doRatingTween(ratingTxtGroup[player].members.length - 1, player);

		var charGroup = strumGroup.isBoyfriend ? boyfriendGroup : dadGroup;
		if (daNote.gfNote) {
			charGroup = gfGroup;
		}

		var characters = daNote.characters.copy();
		if (characters.length < 1) {
			for (i in 0...boyfriendGroup.length) {
				characters.push(i);
			}
		}
		for (i in characters) {
			if (i < charGroup.members.length && charGroup.members[i] != null && charGroup.members[i].hasMissAnimations && !charGroup.members[i].skipSing)
			{
				var animToPlay:String = '${strumGroup.animations[daNote.noteData]}miss${daNote.animSuffix}';
				if (charGroup.members[i].animation.exists(animToPlay)) {
					charGroup.members[i].playAnim(animToPlay, true);
				}
			}
		}

		camZooming = true;
		camBop = true;

		switch (daNote.noteType) {
			case 'Static Note':
				var daNoteStatic = new FlxSprite(0, 0);
				if (player == 1) daNoteStatic.x = FlxG.width / 2;
				daNoteStatic.frames = Paths.getSparrowAtlas('sonicexe/hitStatic');
				daNoteStatic.setGraphicSize(Std.int(FlxG.width / 2), FlxG.height);
				daNoteStatic.updateHitbox();
				daNoteStatic.screenCenter(Y);
				daNoteStatic.cameras = [camHUD2];
				daNoteStatic.animation.addByPrefix('static', 'staticANIMATION', 24, false);
				daNoteStatic.animation.play('static', true);
				shakeCam2[player] = true;

				new FlxTimer().start(0.8, function(tmr:FlxTimer)
				{
					shakeCam2[player] = false;
				});

				FlxG.sound.play(Paths.sound("sonicexe/hitStatic1"));

				add(daNoteStatic);

				new FlxTimer().start(.38, function(trol:FlxTimer) // fixed lmao
				{
					daNoteStatic.alpha = 0;
					remove(daNoteStatic);
				});
			
			case 'Phantom Note':
				var fuckyou:Int = 0;
				healthDrain[player] += 0.00025;
				if (healthDrain[player] == 0.00025)
				{
					new FlxTimer().start(0.1, function(sex:FlxTimer)
					{
						fuckyou += 1;

						if (fuckyou >= 100)
							healthDrain[player] = 0;

						if (!paused && fuckyou < 100)
							sex.reset();
					});
				}
				else
					fuckyou = 0;
		}
	}

	function noteMissPress(direction:Int = 1, player:Int = 0, ?eventKey:Array<FlxKey>):Void //You pressed a key when there was no notes to press for this key
	{
		var charGroup = player == 0 ? dadGroup : boyfriendGroup;
		var animToPlay = '${strumLineNotes.members[player].animations[direction]}miss';
		for (char in charGroup) {
			if (!char.specialAnim && !char.skipSing) {
				if (char.hasMissAnimations && char.animation.exists(animToPlay))
					char.playAnim(animToPlay, true);
				else {
					char.playAnim(strumLineNotes.members[player].animations[direction], true);
					char.holdTimer = 0;
					if (eventKey != null) char.keysPressed = eventKey;
				}
				switch (char.curCharacter) {
					case 'guy':
						char.addY = 0;
						char.y = char.defaultY;
						guyFlippedIdle[player] = char.flipped;
						char.flipX = char.flipped;
				}
			}
		}
		if(ClientPrefs.ghostTapping) return; //fuck it

		if (!charGroup.members[0].stunned)
		{
			health -= 0.05 * (player == 0 ? -1 : 1);

			if (combo[player] > 5)
			{
				for (gf in gfGroup) {
					if (gf.animation.exists('sad')) {
						gf.playAnim('sad');
					}
				}
			}
			combo[player] = 0;

			songScore[player] -= 10;
			songMisses[player]++;
			totalPlayed[player]++;
			recalculateRating(true, player);
			doRatingTween(ratingTxtGroup[player].members.length - 1);

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
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
		Conductor.getLastBPM(PlayState.SONG, curStep);
	}

	function startCharacterPos(char:Character, gfCheck:Bool = false) {
		if (gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	function addCharacter(name:String, index:Int = 0, flipped:Bool = false, ?group:FlxTypedSpriteGroup<Character>, xOffset:Float = 0, yOffset:Float = 0, scrollX:Float = 1, scrollY:Float = 1):Character {
		var char = new Character(0, 0, name, flipped);
		char.isPlayer = true;
		startCharacterPos(char);
		char.x += xOffset;
		char.y += yOffset;
		char.scrollFactor.set(scrollX, scrollY);
		if (group != null) {
			group.add(char);
			char.addedToGroup = true;
		}
		switch (char.curCharacter) {
			case 'spirit':
				var evilTrail = new FlxTrail(char, null, 4, 24, 0.3, 0.069); //nice
				evilTrail.scrollFactor.copyFrom(char.scrollFactor);
				addBehindChar(char, evilTrail);
				char.associatedSprites.push(evilTrail);

			case 'TDoll', 'TDollAlt':
				var ezTrail = new FlxTrail(char, null, 2, 5, 0.3, 0.04);
				ezTrail.scrollFactor.copyFrom(char.scrollFactor);
				addBehindChar(char, ezTrail);
				char.associatedSprites.push(ezTrail);

			case 'sshaggy':
				var shaggyT = new FlxTrail(char, null, 3, 6, 0.3, 0.002);
				shaggyT.scrollFactor.copyFrom(char.scrollFactor);
				addBehindChar(char, shaggyT);
				char.associatedSprites.push(shaggyT);

			case 'pshaggy':
				var legs = new FlxSprite();
				legs.frames = Paths.getSparrowAtlas('characters/pshaggy');
				legs.animation.addByPrefix('legs', "solo_legs", 30);
				legs.animation.play('legs');
				legs.antialiasing = ClientPrefs.globalAntialiasing;
				legs.updateHitbox();
				legs.offset.set(legs.frameWidth / 2, 10);
				if (flipped)
					legs.offset.x -= 25;
				legs.flipX = char.flipX;
				legs.scrollFactor.copyFrom(char.scrollFactor);
				pshaggyLegs.set(char, legs);
				char.associatedSprites.push(legs);

				var shaggyT = new FlxTrail(char, null, 5, 7, 0.3, 0.001);
				shaggyT.scrollFactor.copyFrom(char.scrollFactor);
				addBehindChar(char, shaggyT);
				char.associatedSprites.push(shaggyT);
				var legT = new FlxTrail(legs, null, 5, 7, 0.3, 0.001);
				legT.scrollFactor.copyFrom(char.scrollFactor);
				pshaggyLegT.set(char, legT);
				char.associatedSprites.push(legT);
				addBehindChar(char, legT);
				addBehindChar(char, legs);
		}
		if (group == null) {
			for (spr in char.associatedSprites) {
				if (Std.isOfType(spr, FlxTrail))
					spr.visible = false;
				else
					spr.alpha = 0.00001;
			}
		}
		char.defaultX = char.x;
		char.defaultY = char.y;
		if (flipped)
			boyfriendMap.set(name, char);
		else
			dadMap.set(name, char);
		return char;
	}

	function addBehindChar(char:Character, obj:FlxObject) {
		if (char.flipped)
			addBehindBF(obj);
		else
			addBehindDad(obj);
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

	function updateTimeTxt() {
		var txt = songDetails;
		if (updateTime) {
			var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
			if(curTime < 0) curTime = 0;
			songPercent = (curTime / songLength);

			if(ClientPrefs.timeBarType == 'Percentage Passed') { //geometry dash moment
				txt += '\n' + Math.floor(songPercent * 100) + '%';
			} else if (ClientPrefs.timeBarType != 'Song Name') {
				var songCalc:Float = (songLength - curTime) / playbackRate;
				if(ClientPrefs.timeBarType == 'Time Elapsed') songCalc = curTime / playbackRate;

				var secondsTotal:Int = Math.floor(songCalc / 1000);
				if (secondsTotal < 0) secondsTotal = 0;

				txt += '\n' + FlxStringUtil.formatTime(secondsTotal, false);
			}
		}
		timeTxt.text = txt;
	}

	function getUIFile(file:String) {
		return SkinData.getUIFile(file, PlayState.SONG.skinModifier);
	}
	
	function getNoteFile(file:String) {
		return SkinData.getNoteFile(file, PlayState.SONG.skinModifier);
	}

	function setKeysArray(keys:Int = 4) {
		keysArray = [];
		for (i in 0...keys) {
			keysArray.push(ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note${keys}_$i')));
		}
	}

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(id:Int = 0, keys:Int = 4, isBoyfriend:Bool = false):Void
	{
		while (id >= strumMaps.length) {
			strumMaps.push(new Map());
		}
		var strumX:Float = 0;
		if (isBoyfriend)
			strumX += FlxG.width / 2;

		var strumGroup = new StrumLine(strumX, strumLine.y, keys, true, !skipArrowStartTween, true);
		#if debug
		strumGroup.botPlay = !isBoyfriend;
		#else
		strumGroup.botPlay = false;
		#end
		strumGroup.isBoyfriend = isBoyfriend;

		strumMaps[id].set(keys, strumGroup);
	}

	public function reloadHealthBarColors() {
		var healthColors = [dad.healthColorArray, boyfriend.healthColorArray];
		if (dadGroupFile != null)
			healthColors[0] = dadGroupFile.healthbar_colors;
		if (bfGroupFile != null)
			healthColors[1] = bfGroupFile.healthbar_colors;
		var match = true;
		for (i in 0...healthColors[0].length) {
			if (healthColors[0][i] != healthColors[1][i]) {
				match = false;
				break;
			}
		}
		if (match)
			healthColors = [[255, 0, 0], [102, 255, 51]];
		healthBar.createFilledBar(FlxColor.fromRGB(healthColors[0][0], healthColors[0][1], healthColors[0][2]),
		FlxColor.fromRGB(healthColors[1][0], healthColors[1][1], healthColors[1][2]));
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
					var newBoyfriend = addCharacter(newCharacter, index, true, null, xOffset, yOffset);
					boyfriendMap.set(newCharacter, newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					add(newBoyfriend);
				}

			case 1:
				if (!dadMap.exists(newCharacter)) {
					var xOffset = 0.0;
					var yOffset = 0.0;
					if (dadGroupFile != null) {
						xOffset = (dadGroupFile.characters[index] != null ? dadGroupFile.characters[index].position[0] : 0) + dadGroupFile.position[0];
						yOffset = (dadGroupFile.characters[index] != null ? dadGroupFile.characters[index].position[1] : 0) + dadGroupFile.position[1];
					}
					var newDad = addCharacter(newCharacter, index, false, null, xOffset, yOffset);
					dadMap.set(newCharacter, newDad);
					newDad.alpha = 0.00001;
					add(newDad);
				}

			case 2:
				if (!gfMap.exists(newCharacter)) {
					var xOffset = 0.0;
					var yOffset = 0.0;
					if (gfGroupFile != null) {
						xOffset = (gfGroupFile.characters[index] != null ? gfGroupFile.characters[index].position[0] : 0) + gfGroupFile.position[0];
						yOffset = (gfGroupFile.characters[index] != null ? gfGroupFile.characters[index].position[1] : 0) + gfGroupFile.position[1];
					}
					var newGf = addCharacter(newCharacter, index, false, null, xOffset, yOffset, 0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					newGf.alpha = 0.00001;
					add(newGf);
				}
		}
	}

	function eventPushed(event:EventNote) {
		switch(event.event) {
			case 'Change Character':
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

			case 'Change Stage':
				var stage = event.value1;
				var stageData:StageFile = StageData.getStageFile(stage);
				var lastDirectory = Paths.currentLevel;
				if (stageData.directory != null && stageData.directory.length > 0) Paths.setCurrentLevel(stageData.directory);
				var dummyStage = new Stage(stage, this);
				var grps = [dummyStage.background, dummyStage.overGF, dummyStage.overDad, dummyStage.foreground];
				for (grp in grps) {
					for (obj in grp) {
						var sprite:Dynamic = obj;
						if ((sprite is FlxSprite)) {
							var sprite:FlxSprite = sprite;
							sprite.alpha = 0.00001;
							sprite.x = 0;
							sprite.y = 0;
							sprite.scrollFactor.set();
							sprite.cameras = [camHUD];
							add(obj);
						}
					}
				}
				Paths.setCurrentLevel(lastDirectory);

			case 'Dadbattle Spotlight':
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
	}

	function eventNoteEarlyTrigger(event:EventNote):Float {
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

	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch(eventName) {
			case 'Dadbattle Spotlight':
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
						if (dad.curCharacter.startsWith('gf') && dad.animation.exists('cheer')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
							dad.playAnim('cheer', true);
							dad.specialAnim = true;
							dad.heyTimer = time;
						}
					}

					for (gf in gfGroup) {
						if (gf.animation.exists('cheer')) {
							gf.playAnim('cheer', true);
							gf.specialAnim = true;
							gf.heyTimer = time;
						}
					}
				}
				if (value != 1) {
					for (boyfriend in boyfriendGroup) {
						if (boyfriend.animation.exists('hey')) {
							boyfriend.playAnim('hey', true);
							boyfriend.specialAnim = true;
							boyfriend.heyTimer = time;
						}
					}
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if (Math.isNaN(value)) value = 1;
				if (value < 0) value = 0;
				for (gf in gfGroup) {
					gf.danceEveryNumBeats = value;
				}

			case 'Philly Glow':
				if (curStage == 'philly' && ClientPrefs.gameQuality != 'Crappy') {
					var lightId:Int = Std.parseInt(value1);
					if (Math.isNaN(lightId)) lightId = 0;

					var doFlash:Void->Void = function() {
						var color:FlxColor = FlxColor.WHITE;
						if(!ClientPrefs.flashing) color.alphaFloat = 0.5;

						for (camera in camGames)
							camera.flash(color, 0.15, null, true);
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
									for (camera in camGames)
										camera.zoom += 0.5;
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
									for (camera in camGames)
										camera.zoom += 0.5;
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
								for (camera in camGames)
									camera.flash(colorButLower, 0.5, null, true);
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
				stage.killHenchmen();

			case 'Add Camera Zoom':
				if (ClientPrefs.camZooms) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if (Math.isNaN(camZoom)) camZoom = 0.015;
					if (Math.isNaN(hudZoom)) hudZoom = 0.03;

					for (camera in camGames) {
						if (camera.zoom < 1.35)
							camera.zoom += camZoom;
					}
					camHUD.zoom += hudZoom;
				}

			case 'Play Animation':
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
				if (charGroup.members[index % charGroup.length] != null && charGroup.members[index % charGroup.length].animation.exists(value1)) {
					charGroup.members[index % charGroup.length].playAnim(value1, true);
					charGroup.members[index % charGroup.length].specialAnim = true;
				}

			case 'Alt Idle Animation':
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
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [FlxG.camera, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if (split[0] != null) duration = Std.parseFloat(split[0].trim());
					if (split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if (Math.isNaN(duration)) duration = 0;
					if (Math.isNaN(intensity)) intensity = 0;

					if (duration > 0 && intensity != 0) {
						if (i == 0) {
							for (camera in camGames)
								camera.shake(intensity, duration);
						} else
							targetsArray[i].shake(intensity, duration);
					}
				}

			case 'Change Character':
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
							if (!boyfriendMap.exists(value2))
								addCharacterToList(value2, charType, index);

							var lastAlpha:Float = boyfriendGroup.members[index].alpha;
							boyfriendGroup.members[index].alpha = 0.00001;
							for (spr in boyfriendGroup.members[index].associatedSprites)
								spr.visible = false;
							boyfriendGroup.remove(boyfriendGroup.members[index], true);
							remove(boyfriendMap.get(value2));
							boyfriendGroup.insert(index, boyfriendMap.get(value2));
							if (boyfriendGroup.members[index].addedToGroup) {
								boyfriendGroup.members[index].x -= boyfriendGroup.x;
								boyfriendGroup.members[index].y -= boyfriendGroup.y;
							} else {
								boyfriendGroup.members[index].defaultX = boyfriendGroup.members[index].x;
								boyfriendGroup.members[index].defaultY = boyfriendGroup.members[index].y;
							}
							boyfriendGroup.members[index].addedToGroup = true;
							boyfriendGroup.members[index].alpha = lastAlpha;
							boyfriendGroup.members[index].dance();
							for (spr in boyfriendGroup.members[index].associatedSprites)
								spr.visible = true;
							if (boyfriendGroup.members.length == 1)
								iconP1.changeIcon(boyfriend.healthIcon);
							reloadHealthBarColors();
						}

					case 1:
						index %= dadGroup.length;
						if (dadGroup.members[index].curCharacter != value2) {
							if (!dadMap.exists(value2))
								addCharacterToList(value2, charType, index);

							var wasGf:Bool = dadGroup.members[index].curCharacter.startsWith('gf');
							var lastAlpha:Float = dadGroup.members[index].alpha;
							dadGroup.members[index].alpha = 0.00001;
							for (spr in dadGroup.members[index].associatedSprites)
								spr.visible = false;
							dadGroup.remove(dadGroup.members[index], true);
							remove(dadMap.get(value2));
							dadGroup.insert(index, dadMap.get(value2));
							if (dadGroup.members[index].addedToGroup) {
								dadGroup.members[index].x -= dadGroup.x;
								dadGroup.members[index].y -= dadGroup.y;
							} else {
								dadGroup.members[index].defaultX = dadGroup.members[index].x;
								dadGroup.members[index].defaultY = dadGroup.members[index].y;
							}
							dadGroup.members[index].addedToGroup = true;
							if (gf != null) {
								if (!dadGroup.members[index].curCharacter.startsWith('gf')) {
									if (wasGf)
										gf.visible = true;
								} else
									gf.visible = false;
							}
							dadGroup.members[index].alpha = lastAlpha;
							dadGroup.members[index].dance();
							for (spr in dadGroup.members[index].associatedSprites)
								spr.visible = true;
							if (dadGroup.members.length == 1)
								iconP2.changeIcon(dad.healthIcon);
							reloadHealthBarColors();
						}

					case 2:
						if (gf != null) {
							index %= gfGroup.length;
							if (gfGroup.members[index].curCharacter != value2) {
								if (!gfMap.exists(value2))
									addCharacterToList(value2, charType, index);

								var lastAlpha:Float = gfGroup.members[index].alpha;
								gfGroup.members[index].alpha = 0.00001;
								for (spr in dadGroup.members[index].associatedSprites)
									spr.visible = false;
								gfGroup.remove(gfGroup.members[index], true);
								remove(gfMap.get(value2));
								gfGroup.insert(index, gfMap.get(value2));
								if (gfGroup.members[index].addedToGroup) {
									gfGroup.members[index].x -= gfGroup.x;
									gfGroup.members[index].y -= gfGroup.y;
								} else {
									gfGroup.members[index].defaultX = dadGroup.members[index].x;
									gfGroup.members[index].defaultY = dadGroup.members[index].y;
								}
								gfGroup.members[index].addedToGroup = true;
								gfGroup.members[index].alpha = lastAlpha;
								gfGroup.members[index].dance();
								for (spr in gfGroup.members[index].associatedSprites)
									spr.visible = true;
							}
						}
				}

			case 'Change Stage':
				curStage = value1;
				
				var stageData:StageFile = StageData.getStageFile(curStage);
				Paths.setCurrentLevel(stageData.directory);
				defaultCamZoom = stageData.defaultZoom;
				isPixelStage = stageData.isPixelStage;
				BF_X = stageData.boyfriend[0];
				BF_Y = stageData.boyfriend[1];
				GF_X = stageData.girlfriend[0];
				GF_Y = stageData.girlfriend[1];
				DAD_X = stageData.opponent[0];
				DAD_Y = stageData.opponent[1];
				
				cameraSpeed = stageData.camera_speed;
		
				boyfriendCameraOffset = stageData.camera_boyfriend;
				opponentCameraOffset = stageData.camera_opponent;
				girlfriendCameraOffset = stageData.camera_girlfriend;

				for (gf in gfGroup) {
					gf.visible = (stageData.hide_girlfriend == false);
				}

				gfGroup.setPosition(GF_X, GF_Y);
				dadGroup.setPosition(DAD_X, DAD_Y);
				boyfriendGroup.setPosition(BF_X, BF_Y);

				stage.createStage(curStage);
				stage.onCharacterInit();
			
			case 'Change Scroll Speed':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1)) val1 = 1;
				if (Math.isNaN(val2)) val2 = 0;

				var newValue:Float = PlayState.SONG.speed * val1 / playbackRate;
				newValue = CoolUtil.boundTo(newValue, 0.1, 10);

				if (val2 <= 0)
					songSpeed = newValue;
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween) {
							songSpeedTween = null;
						}
					});
				}

			case 'Set Property':
				var killMe:Array<String> = value1.split('.');
				if(killMe.length > 1)
					FunkinLua.setVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe, true, true), killMe[killMe.length-1], value2);
				else
					FunkinLua.setVarInArray(this, value1, value2);

		}
		stage.onEvent(eventName, value1, value2);
	}

	function updateCameras():Void {
		camFollow[0].set(CoolUtil.getCamFollowCharacter(dad).x, CoolUtil.getCamFollowCharacter(dad).y);

		if (dadGroupFile != null) {
			camFollow[0].x += dadGroupFile.camera_position[0];
			camFollow[0].y += dadGroupFile.camera_position[1];
		} else {
			camFollow[0].x += dad.cameraPosition[0];
			camFollow[0].y += dad.cameraPosition[1];
		}

		camFollow[0].x += dadCamX;
		camFollow[0].y += dadCamY;

		camFollow[1].set(CoolUtil.getCamFollowCharacter(boyfriend).x, CoolUtil.getCamFollowCharacter(boyfriend).y);

		if (bfGroupFile != null) {
			camFollow[1].x += bfGroupFile.camera_position[0];
			camFollow[1].y += bfGroupFile.camera_position[1];
		} else {
			camFollow[1].x += boyfriend.cameraPosition[0];
			camFollow[1].y += boyfriend.cameraPosition[1];
		}

		camFollow[1].x += boyfriendCamX;
		camFollow[1].y += boyfriendCamY;

		if (gf != null && gf.visible) {
			camGames[2].visible = true;
			camBorder.visible = true;
			camFollow[2].set(CoolUtil.getCamFollowCharacter(gf).x, CoolUtil.getCamFollowCharacter(gf).y);
			if (gfGroupFile != null) {
				camFollow[2].x += gfGroupFile.camera_position[0];
				camFollow[2].y += gfGroupFile.camera_position[1];
			} else {
				camFollow[2].x += gf.cameraPosition[0];
				camFollow[2].y += gf.cameraPosition[1];
			}
		} else {
			camGames[2].visible = false;
			camBorder.visible = false;
		}
	}

	var cameraTwn:FlxTween;
	function tweenCamIn(id:Int = 0) {
		if (cameraTwn == null) {
			cameraTwn = FlxTween.tween(camGames[id], {zoom: 1.3}, (Conductor.normalizedCrochet / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(id:Int, x:Float, y:Float) {
		camFollow[id].set(x, y);
		camFollowPos[id].setPosition(x, y);
	}

	public function recalculateRating(badHit:Bool = false, player:Int = 0) {
		if (totalPlayed[player] < 1) //Prevent divide by 0
			ratingName[player] = '?';
		else
		{
			// Rating Percent
			ratingPercent[player] = Math.min(1, Math.max(0, totalNotesHit[player] / totalPlayed[player]));

			// Rating Name
			if (ratingPercent[player] >= 1)
			{
				ratingName[player] = PlayState.ratingStuff[PlayState.ratingStuff.length - 1][0]; //Uses last string
			}
			else
			{
				for (i in 0...PlayState.ratingStuff.length - 1)
				{
					if (ratingPercent[player] < PlayState.ratingStuff[i][1])
					{
						ratingName[player] = PlayState.ratingStuff[i][0];
						break;
					}
				}
			}
		}

		// Rating FC
		ratingFC[player] = "";
		if (sicks[player] > 0) ratingFC[player] = "SFC";
		if (goods[player] > 0) ratingFC[player] = "GFC";
		if (bads[player] > 0 || shits[player] > 0) ratingFC[player] = "FC";
		if (songMisses[player] > 0 && songMisses[player] < 10) ratingFC[player] = "SDCB";
		else if (songMisses[player] >= 10) ratingFC[player] = "Clear";
		updateScore(badHit, player); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce -Ghost
	}

	public function updateScore(miss:Bool = false, player:Int = 0)
	{
		var txt = '';
		if (ClientPrefs.showRatings)
			txt = 'Score: ' + Math.round(songScore[player]) + ' | Combo: ' + combo[player] + ' | Rating: ' + ratingName[player];
		else
			txt = 'Score: ' + Math.round(songScore[player]) + ' | Combo: ' + combo[player] + ' | Fails: ' + songMisses[player] + ' | Rating: ' + ratingName[player];

		if(ratingName[player] != '?')
			txt += ' [${Highscore.floorDecimal(ratingPercent[player] * 100, 2)}% | ${ratingFC[player]}]';

		if(ClientPrefs.scoreZoom && !miss) {
			if(scoreTxtTween[player] != null)
				scoreTxtTween[player].cancel();
			scoreTxt[player].scale.x = 1.01875;
			scoreTxt[player].scale.y = 1.01875;
			scoreTxtTween[player] = FlxTween.tween(scoreTxt[player].scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween) {
					scoreTxtTween[player] = null;
				}
			});
		}

		scoreTxt[player].text = txt;
	}

	private function cachePopUpScore()
	{
		for (rating in ratingsData)
			precacheList.set(getUIFile(rating.image), 'image');
	}

	private function popUpScore(note:Note = null, player:Int = 0):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);

		var strumGroup = strumLineNotes.members[player];
		var strum = strumGroup.receptors.members[strumGroup.keys - 1];

		var rating:FlxSprite = grpRatings.recycle(FlxSprite);
		rating.setPosition(strum.x + strum.width, strum.y);
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating = Conductor.judgeNote(note, noteDiff);
		if (strumLineNotes.members[player].botPlay)
			daRating = ratingsData[0];
		var ratingNum = ratingsData.indexOf(daRating);

		totalNotesHit[player] += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.increase(1, player);
		note.rating = daRating.name;
		score = daRating.score;

		if(daRating.noteSplash && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note, strumLineNotes.members[player]);
		}

		if (!daRating.causesMiss) {
			health += note.hitHealth * (player == 0 ? -1 : 1);
			songScore[player] += score * (player == 0 ? dadScoreMult : boyfriendScoreMult);
			if(!note.ratingDisabled) {
				totalPlayed[player]++;
				recalculateRating(false, player);
				doRatingTween(ratingNum, player);
			}
		} else {
			noteMissPress(note.noteData, player);
		}

		rating.scale.set(1, 1);
		rating.velocity.set(0, 0);
		rating.alpha = 1;
		rating.loadGraphic(Paths.image(getUIFile(daRating.image)));
		rating.cameras = [camHUD];
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.visible = !ClientPrefs.hideHud && showRating;

		grpRatings.add(rating);

		if (!PlayState.SONG.skinModifier.endsWith('pixel')) {
			rating.setGraphicSize(Std.int(rating.width * 0.21));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
			rating.setGraphicSize(Std.int(rating.width * PlayState.daPixelZoom * 0.255));
		rating.updateHitbox();

		if (rating.x > FlxG.width / 2) {
			strum = strumGroup.receptors.members[0];
			rating.x = strum.x - rating.width;
		}
		rating.y = strum.getMidpoint().y - (rating.height / 2);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				rating.kill();
			},
			startDelay: Conductor.normalizedCrochet * 0.001
		});
	}

	function doRatingTween(ind:Int = 0, player:Int = 0) {
		if (ClientPrefs.scoreZoom)
		{
			if (ratingTxtTweens[player][ind] != null) {
				ratingTxtTweens[player][ind].cancel();
			}
			ratingTxtGroup[player].members[ind].scale.x = 1.02;
			ratingTxtGroup[player].members[ind].scale.y = 1.02;
			ratingTxtTweens[player][ind] = FlxTween.tween(ratingTxtGroup[player].members[ind].scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween) {
					ratingTxtTweens[player][ind] = null;
				}
			});
		}
	}
}