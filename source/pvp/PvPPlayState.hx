package pvp;

import LoadingState.MultiCallback;
import flixel.addons.effects.FlxTrail;
import flixel.input.gamepad.FlxGamepadInputID;
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
	public var camFollow:FlxPoint;
	public var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumLine>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

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

	private var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;
	
	public var ratingsData:Array<Rating> = [];
	public var sicks:Array<Int> = [0, 0];
	public var goods:Array<Int> = [0, 0];
	public var bads:Array<Int> = [0, 0];
	public var shits:Array<Int> = [0, 0];
	
	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = true;
	private var updateTime:Bool = true;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
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

	var shaggyT:FlxTrail;

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

	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	public var ratingName:Array<String> = ['?', '?'];
	public var ratingPercent:Array<Float> = [0, 0];
	public var ratingFC:Array<String> = ['', ''];
	public var transitioning = false;

	public static var boyfriendMatch:Bool = false;
	public static var dadMatch:Bool = false;
	public static var skipStage:Bool = false;

	var boyfriendScoreMult:Float = 1;
	var dadScoreMult:Float = 1;

	var winTxt:FlxText;

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
				for (note in strumLine.holdsGroup) note.resizeByRatio(ratio);
			}
			for (note in unspawnNotes) note.resizeByRatio(ratio);
		}
		songSpeed = value;
		return value;
	}

    override public function create() {
		Paths.clearStoredMemory();

		instance = this;

		PvPPauseSubState.songName = null; //Reset to default

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);

		grpNoteSplashes = new FlxTypedGroup();

		CustomFadeTransition.nextCamera = camOther;
		persistentUpdate = true;

		if (PlayState.SONG == null)
			PlayState.SONG = Song.loadFromJson('test', 'test');

		if (skipStage) {
			PlayState.SONG.stage = 'stage';
		}

		curSong = Paths.formatToSongPath(PlayState.SONG.song);
		curSongDisplayName = Song.getDisplayName(PlayState.SONG.song);

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

		if(PlayState.SONG.skinModifier.endsWith('pixel')) {
			introSoundsSuffix = '-pixel';
		}

		add(gfGroup); //Needed for blammed lights
		add(stage.overGF);

		add(dadGroup);
		add(stage.overDad);
		add(boyfriendGroup);

		add(stage.foreground);

		var gfVersion:String = PlayState.SONG.gfVersion;
		if (gfVersion == null || gfVersion.length < 1)
		{
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
		}

		bfGroupFile = Character.getFile(PlayState.SONG.player1);
		if (bfGroupFile != null && bfGroupFile.characters != null && bfGroupFile.characters.length > 0) {
			for (i in 0...bfGroupFile.characters.length) {
				addCharacter(bfGroupFile.characters[i].name, i, true, boyfriendGroup, bfGroupFile.characters[i].position[0] + bfGroupFile.position[0], bfGroupFile.characters[i].position[1] + bfGroupFile.position[1]);
			}
		} else {
			bfGroupFile = null;
			addCharacter(PlayState.SONG.player1, 0, true, boyfriendGroup);
		}

		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		stage.onCharacterInit();

		switch (PlayState.SONG.player1) {
			case 'spirit':
				var evilTrail = new FlxTrail(boyfriend, null, 4, 24, 0.3, 0.069); //nice
                addBehindBF(evilTrail);
		}

		switch (PlayState.SONG.player2) {
			case 'spirit':
				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); //nice
                addBehindDad(evilTrail);
		}

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

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		if (ClientPrefs.downScroll) strumLine.y = FlxG.height - 210;
		strumLine.scrollFactor.set();

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
		updateTime = showTime;

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

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		add(timeBar);
		add(timeTxt);
		timeBarBG.sprTracker = timeBar;

		strumLineNotes = new FlxTypedGroup();
		add(strumLineNotes);
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

		winTxt = new FlxText(0, FlxG.height * 0.3, FlxG.width, "", 64);
		winTxt.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		winTxt.borderSize = 2;
		winTxt.scrollFactor.set();
		winTxt.visible = false;
		add(winTxt);

		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		winTxt.cameras = [camHUD];

		startCountdown();
		for (i in 0...2)
			recalculateRating(false, i);

		precacheList.set('missnote1', 'sound');
		precacheList.set('missnote2', 'sound');
		precacheList.set('missnote3', 'sound');

		if (PvPPauseSubState.songName != null) {
			precacheList.set(PvPPauseSubState.songName, 'music');
		} else if(ClientPrefs.pauseMusic != 'None') {
			precacheList.set(Paths.formatToSongPath(ClientPrefs.pauseMusic), 'music');
		}

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, '$curSongDisplayName ($storyDifficultyText)', iconP2.getCharacter());
		#end

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

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

		CustomFadeTransition.nextCamera = camOther;
    }

	override public function update(elapsed:Float)
	{
		var pause = controls.PAUSE;
		if (FlxG.gamepads.lastActive != null) {
			var gamepad = FlxG.gamepads.lastActive;
			if (gamepad.justPressed.START) pause = true;
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

		super.update(elapsed);

		if (startedCountdown && generatedMusic && PlayState.SONG.notes[curSection] != null && !endingSong && !isCameraOnForcedPos)
		{
			moveCameraSection();
		}

		if (pause && startedCountdown && canPause)
		{
			openPauseMenu();
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

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, healthBar.numDivisions, 0) * division)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, healthBar.numDivisions, 0) * division)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;

		if (health > 2)
			health = 2;
		else if (health < 0)
			health = 0;

		var stupidIcons:Array<HealthIcon> = [iconP1, iconP2];
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

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0) {
					startSong();
				}
			}
		}
		else
		{
			if (!endingSong)
				Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				if (updateTime) {
					var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
					if(curTime < 0) curTime = 0;
					songPercent = (curTime / songLength);

					if(ClientPrefs.timeBarType == 'Percentage Passed') { //geometry dash moment
						timeTxt.text = Math.floor(songPercent * 100) + '%';
					} else if (ClientPrefs.timeBarType != 'Song Name') {
						var songCalc:Float = (songLength - curTime);
						if(ClientPrefs.timeBarType == 'Time Elapsed') songCalc = curTime;

						var secondsTotal:Int = Math.floor(songCalc / 1000);
						if (secondsTotal < 0) secondsTotal = 0;

						timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
					}
				}
			}
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay), 0, 1));
			camHUD.zoom = FlxMath.lerp(defaultCamHudZoom, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay), 0, 1));
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;
			time /= camHUD.zoom;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];

				//Change the selected strumline here!
				var strumID = (dunceNote.isOpponent ? 0 : 1);

				strumLineNotes.members[strumID].push(dunceNote);
				dunceNote.spawned = true;

				unspawnNotes.splice(unspawnNotes.indexOf(dunceNote), 1);
			}
		}

		if (generatedMusic && !endingSong)
		{
			for (char in dadGroup) {
				var keyPressed:Bool = FlxG.keys.anyPressed(char.keysPressed);
				if (!keyPressed && char.holdTimer > Conductor.normalizedStepCrochet * 0.0011 * char.singDuration && char.animation.curAnim != null && char.animation.curAnim.name.startsWith('sing') && !char.animation.curAnim.name.endsWith('miss')) {
					char.dance();
				}
			}
			
			noteFunctions();
		}

		for (arr in 0...ratingTxtGroup.length) {
			for (i in 0...ratingTxtGroup[arr].members.length) {
				var rating = ratingTxtGroup[arr].members[i];
				if (i < ratingsData.length) {
					rating.text = '${ratingsData[i].displayName}: ${Reflect.field(this, ratingsData[i].counter)[arr]}';
				} else {
					rating.text = 'Fails: ${songMisses[arr]}';
				}
			}
		}

		#if debug
		if (!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				killNotes();
				FlxG.sound.music.onComplete();
			}
			if (FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
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
				DiscordClient.changePresence(detailsText, '$curSongDisplayName ($storyDifficultyText)', iconP2.getCharacter(), true, (songLength - Conductor.songPosition) - ClientPrefs.noteOffset);
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
		if (!paused)
		{
			if (FlxG.sound.music != null && !startingSong && !endingSong)
			{
				resyncVocals();
			}
			#if DISCORD_ALLOWED
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, '$curSongDisplayName ($storyDifficultyText)', iconP2.getCharacter(), true, (songLength - Conductor.songPosition) - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, '$curSongDisplayName ($storyDifficultyText)', iconP2.getCharacter());
			}
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
		}

		super.onFocusLost();
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();
		if (generatedMusic && (Math.abs(FlxG.sound.music.time - Conductor.songPosition) > 20
			|| (PlayState.SONG.needsVoices && ((Math.abs(vocals.time - Conductor.songPosition) > 20) 
			|| (foundDadVocals && Math.abs(vocalsDad.time - Conductor.songPosition) > 20)))))
		{
			resyncVocals();
		}

		if (curStep == lastStepHit) {
			return;
		}

		if (ClientPrefs.gameQuality != 'Crappy' && curStep >= 0) {
			stage.onStepHit();
		}

		lastStepHit = curStep;
	}

	var lastBeatHit:Int = -1;
	override function beatHit()
	{
		super.beatHit();

		if (lastBeatHit >= curBeat) {
			return;
		}

		var curNumeratorBeat = Conductor.getCurNumeratorBeat(PlayState.SONG, curBeat);

		if (iconBopSpeed > 0 && curBeat % Math.round((iconBopSpeed * (Conductor.timeSignature[1] / 4))) == 0) {
			iconP1.scale.set(1.2, 1.2);
			iconP2.scale.set(1.2, 1.2);
			iconP1.updateHitbox();
			iconP2.updateHitbox();
		}

		if (curBeat >= 0 && !endingSong) {
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

		if (ClientPrefs.gameQuality != 'Crappy' && curBeat >= 0) {
			stage.onBeatHit();
		}
		lastBeatHit = curBeat;
	}

	override function sectionHit() {
		super.sectionHit();
		
		var songSection = PlayState.SONG.notes[curSection];
		if (songSection != null)
		{
			if (ClientPrefs.camZooms && camZooming && camBop && FlxG.camera.zoom < 1.35)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
			}

			if (songSection.changeBPM && songSection.bpm != Conductor.bpm)
			{
				Conductor.changeBPM(songSection.bpm);
			}
			if (songSection.changeSignature && (songSection.timeSignature[0] != Conductor.timeSignature[0] || songSection.timeSignature[1] != Conductor.timeSignature[1]))
			{
				Conductor.changeSignature(songSection.timeSignature);
			}
		}
	}

	override function destroy() {
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
				strumLine.allNotes.remove(daNote, true);
				var daGroup = (daNote.isSustainNote ? strumLine.holdsGroup : strumLine.notesGroup);
				daGroup.remove(daNote, true);
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

	function resyncVocals():Void
	{
		if (FlxG.sound.music == null || vocals == null || startingSong || endingSong || endingTimer != null) return;

		vocals.pause();
		vocalsDad.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
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
					if (daNote.tooLate) strumAlpha *= 0.3;
	
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
							noteMiss(daNote, i);
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
		DiscordClient.changePresence(detailsPausedText, '$curSongDisplayName ($storyDifficultyText)', iconP2.getCharacter());
		#end
	}

	function startSong():Void
	{
		startingSong = false;

		FlxG.sound.playMusic(Paths.inst(curSong, CoolUtil.getDifficultyFilePath()), 1, false);
		FlxG.sound.music.onComplete = onSongComplete;
		vocals.play();
		vocalsDad.play();

		if (paused) {
			FlxG.sound.music.pause();
			vocals.pause();
			vocalsDad.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
	
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, '$curSongDisplayName ($storyDifficultyText)', iconP2.getCharacter(), true, songLength);
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
		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		camBop = false;
		updateTime = false;

		var charGroup = boyfriendGroup;
		if (songScore[1] > songScore[0]) {
			winTxt.text = "Player 1 wins!";
			moveCamera(false);
		} else if (songScore[0] > songScore[1]) {
			winTxt.text = "Player 2 wins!";
			moveCamera(true);
			charGroup = dadGroup;
		} else {
			winTxt.text = "Tie!";
			if (gf != null)
				camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			else
				camFollow.set(dadGroup.x + dadGroup.width + ((boyfriendGroup.x - dadGroup.x) / 2), dadGroup.y + ((boyfriendGroup.y - dadGroup.y) / 2));
			charGroup = null;
		}
		winTxt.visible = true;
		if (charGroup != null) {
			for (char in charGroup) {
				if (char.animOffsets.exists('hey')) {
					char.playAnim('hey', true);
				} else {
					char.playAnim('singUP', true);
				}
			}
			for (char in gfGroup) {
				if (char.animOffsets.exists('cheer')) {
					char.playAnim('cheer', true);
				}
			}
		}
		tweenCamIn();
		new FlxTimer().start(3, function(tmr) {
			exit();
		});
	}

	function exit() {
		cancelMusicFadeTween();
		if (FlxTransitionableState.skipNextTransIn) {
			CustomFadeTransition.nextCamera = null;
		}
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
		songSpeed = CoolUtil.boundTo(PlayState.SONG.speed, 0.1, 10);

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
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(curSong, CoolUtil.getDifficultyFilePath())));

		unspawnNotes = Song.generateNotes(PlayState.SONG, strumLineNotes.members[0], strumLineNotes.members[1], true);

		var boyfriendNotes:Int = 0;
		var dadNotes:Int = 0;
		for (note in unspawnNotes) {
			if (!note.ignoreNote && !note.isSustainNote) {
				if (note.isOpponent) dadNotes += 1;
				else boyfriendNotes += 1;
			}
			if ((!note.isOpponent && !boyfriendMatch) || (note.isOpponent && !dadMatch)) {
				note.characters = [];
			}
		}
		if (boyfriendNotes > dadNotes) {
			boyfriendScoreMult = (dadNotes / boyfriendNotes);
		} else if (dadNotes > boyfriendNotes) {
			dadScoreMult = (boyfriendNotes / dadNotes);
		}

		eventNotes = Song.generateEventNotes(PlayState.SONG, eventPushed, eventNoteEarlyTrigger);

		if (unspawnNotes.length > 1) {
			unspawnNotes.sort(sortByShit);
		}
		if (eventNotes.length > 1) {
			eventNotes.sort(sortByTime);
			checkEventNote();
		}
		generatedMusic = true;
	}

	public function startCountdown():Void
	{
		if (startedCountdown) {
			return;
		}

		if (skipCountdown) skipArrowStartTween = true;

		startedCountdown = true;

		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.normalizedCrochet * 5;

		var swagCounter:Int = 0;

		if (skipCountdown)
		{
			setSongTime(0);
			return;
		}
		startTimer = new FlxTimer().start(Conductor.normalizedCrochet / 1000, function(tmr:FlxTimer)
		{
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
					countdownSet.cameras = [camHUD];
					countdownSet.scrollFactor.set();

					if (PlayState.SONG.skinModifier.endsWith('pixel'))
						countdownSet.setGraphicSize(Std.int(countdownSet.width * PlayState.daPixelZoom));

					countdownSet.screenCenter();
					countdownSet.antialiasing = ClientPrefs.globalAntialiasing && !PlayState.SONG.skinModifier.endsWith('pixel');
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
					countdownGo.cameras = [camHUD];
					countdownGo.scrollFactor.set();

					if (PlayState.SONG.skinModifier.endsWith('pixel'))
						countdownGo.setGraphicSize(Std.int(countdownGo.width * PlayState.daPixelZoom));

					countdownGo.updateHitbox();

					countdownGo.screenCenter();
					countdownGo.antialiasing = ClientPrefs.globalAntialiasing && !PlayState.SONG.skinModifier.endsWith('pixel');
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

			for (strumLine in strumLineNotes) {
				strumLine.allNotes.forEachAlive(function(note:Note) {
					note.copyAlpha = false;
					note.alpha = note.multAlpha;
				});
			}

			swagCounter += 1;
		}, 5);
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

	private function onKeyPress(event:KeyboardEvent):Void
	{
		if (startedCountdown && !paused) {
			var eventKey:FlxKey = event.keyCode;
			var key:Int = getKeyFromEvent(eventKey);

			if (key > -1 && FlxG.keys.checkStatus(eventKey, JUST_PRESSED))
			{
				if (!boyfriendGroup.members[0].stunned && generatedMusic && !endingSong)
				{
					strumPressed(key, 0, [eventKey]);
				}
			}
		}
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		if (startedCountdown && !paused) {
			var eventKey:FlxKey = event.keyCode;
			var key:Int = getKeyFromEvent(eventKey);
			if (key > -1)
			{
				var spr:StrumNote = strumLineNotes.members[0].receptors.members[key];
				if (spr != null)
				{
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

		if (controlHoldArray.contains(true) && !dadGroup.members[0].stunned && startedCountdown && !endingSong)
		{
			// rewritten inputs???
			strumLineNotes.members[0].allNotes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit 
				&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) {
					goodNoteHit(daNote, 0, keysArray[daNote.noteData]);
				}
			});
		}

		//ALL BOYFRIEND INPUTS HERE
		var gamepad = FlxG.gamepads.lastActive;
		if (gamepad != null && !dadGroup.members[0].stunned && startedCountdown && !endingSong) {
			var controlArray:Array<Bool> = [gamepad.justPressed.LEFT_STICK_DIGITAL_LEFT, gamepad.justPressed.LEFT_STICK_DIGITAL_DOWN, gamepad.justPressed.RIGHT_STICK_DIGITAL_UP, gamepad.justPressed.RIGHT_STICK_DIGITAL_RIGHT];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						strumPressed(i, 1, null, true);
				}
			}

			controlHoldArray = [gamepad.pressed.LEFT_STICK_DIGITAL_LEFT, gamepad.pressed.LEFT_STICK_DIGITAL_DOWN, gamepad.pressed.RIGHT_STICK_DIGITAL_UP, gamepad.pressed.RIGHT_STICK_DIGITAL_RIGHT];
			if (controlHoldArray.contains(true))
			{
				// rewritten inputs???
				strumLineNotes.members[1].allNotes.forEachAlive(function(daNote:Note)
				{
					// hold note functions
					if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit 
					&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) {
						goodNoteHit(daNote, 1, keysArray[daNote.noteData], true);
					}
				});
			} else if (!endingSong) {
				for (char in boyfriendGroup) {
					if (char.holdTimer > Conductor.normalizedStepCrochet * 0.0011 * char.singDuration && char.animation.curAnim != null && char.animation.curAnim.name.startsWith('sing') && !char.animation.curAnim.name.endsWith('miss')) {
						char.dance();
					}
				}
			}

			var controlReleaseArray:Array<Bool> = [gamepad.justReleased.LEFT_STICK_DIGITAL_LEFT, gamepad.justReleased.LEFT_STICK_DIGITAL_DOWN, gamepad.justReleased.RIGHT_STICK_DIGITAL_UP, gamepad.justReleased.RIGHT_STICK_DIGITAL_RIGHT];
			if(controlReleaseArray.contains(true))
			{
				for (i in 0...controlReleaseArray.length)
				{
					if(controlReleaseArray[i]) {
						var spr:StrumNote = strumLineNotes.members[1].receptors.members[i];
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
		var lastTime:Float = Conductor.songPosition;
		//more accurate hit time for the ratings?
		Conductor.songPosition = FlxG.sound.music.time;

		// heavily based on my own code LOL if it aint broke dont fix it
		var pressNotes:Array<Note> = [];
		var notesStopped:Bool = false;

		var sortedNotesList:Array<Note> = [];
		strumGroup.allNotes.forEachAlive(function(daNote:Note)
		{
			if (daNote.canBeHit && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote && !daNote.blockHit)
			{
				if (daNote.noteData == key)
				{
					sortedNotesList.push(daNote);
				}
			}
		});
		sortedNotesList.sort(sortHitNotes);

		if (sortedNotesList.length > 0) {
			for (epicNote in sortedNotesList)
			{
				for (doubleNote in pressNotes) {
					if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
						doubleNote.kill();
						strumGroup.allNotes.remove(doubleNote, true);
						var daGroup = (doubleNote.isSustainNote ? strumGroup.holdsGroup : strumGroup.notesGroup);
						daGroup.remove(doubleNote, true);
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
		} else {
			noteMissPress(key, player);
		}

		//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
		Conductor.songPosition = lastTime;
		
		var spr:StrumNote = strumGroup.receptors.members[key];
		if (spr != null && spr.animation.curAnim.name != 'confirm')
		{
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
			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
			{
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
			}

			if (note.isOpponent) {
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

				if (!note.noMissAnimation) {
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
				combo[player] += 1;
				if (combo[player] > 9999) combo[player] = 9999;
				popUpScore(note, player);
			}
			else
			{
				health += note.hitHealth * (player == 0 ? -1 : 1);
			}

			if (!note.noAnimation) {
				var altAnim:String = note.animSuffix;

				if (note.isOpponent && PlayState.SONG.notes[curSection] != null && PlayState.SONG.notes[curSection].altAnim && !PlayState.SONG.notes[curSection].gfSection) {
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

			if (!note.mustPress) note.hitByOpponent = true;

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

	function noteMiss(daNote:Note, player:Int = 0):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		var strumGroup = strumLineNotes.members[player];
		//Dupe note remove
		strumGroup.allNotes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				strumGroup.allNotes.remove(daNote, true);
				var daGroup = (daNote.isSustainNote ? strumGroup.holdsGroup : strumGroup.notesGroup);
				daGroup.remove(daNote, true);
				note.destroy();
			}
		});
		combo[player] = 0;
		health -= daNote.missHealth * (player == 0 ? -1 : 1);

		songMisses[player]++;
		songScore[player] -= 10;
		
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
		for (char in characters) {
			if (char < charGroup.members.length && charGroup.members[char] != null && !daNote.noMissAnimation && charGroup.members[char].hasMissAnimations)
			{
				var animToPlay:String = '${strumGroup.animations[daNote.noteData]}miss${daNote.animSuffix}';
				if (charGroup.members[char].animOffsets.exists(animToPlay)) {
					charGroup.members[char].playAnim(animToPlay, true);
				}
			}
		}

		if (daNote.isOpponent) {
			camZooming = true;
			camBop = true;
		}
	}

	function noteMissPress(direction:Int = 1, player:Int = 0):Void //You pressed a key when there was no notes to press for this key
	{
		var charGroup = player == 0 ? dadGroup : boyfriendGroup;
		var animToPlay = '${strumLineNotes.members[player].animations[direction]}miss';
		for (char in charGroup) {
			if (char.hasMissAnimations && char.animOffsets.exists(animToPlay)) {
				char.playAnim(animToPlay, true);
			} else {
				char.playAnim(strumLineNotes.members[player].animations[direction], true);
				char.holdTimer = 0;
			}
		}
		if(ClientPrefs.ghostTapping) return; //fuck it

		if (!charGroup.members[0].stunned)
		{
			health -= 0.05 * (player == 0 ? -1 : 1);

			if (combo[player] > 5)
			{
				for (gf in gfGroup) {
					if (gf.animOffsets.exists('sad')) {
						gf.playAnim('sad');
					}
				}
			}
			combo[player] = 0;

			songScore[player] -= 10;
			if (!endingSong) {
				songMisses[player]++;
			}
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
		Conductor.songPosition = time;

		updateCurStep();
		Conductor.getLastBPM(PlayState.SONG, curStep);
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

	function addCharacter(name:String, index:Int = 0, flipped:Bool = false, ?group:FlxTypedSpriteGroup<Character>, xOffset:Float = 0, yOffset:Float = 0, scrollX:Float = 1, scrollY:Float = 1):Character {
		var char = new Character(0, 0, name, flipped);
		char.isPlayer = true;
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
		strumGroup.botPlay = false;
		strumGroup.isBoyfriend = isBoyfriend;

		strumMaps[id].set(keys, strumGroup);

		trace('generated arrows: $id, $keys, $isBoyfriend');
	}

	public function reloadHealthBarColors() {
		var healthColors = [dad.healthColorArray, boyfriend.healthColorArray];
		if (dadGroupFile != null) {
			healthColors[0] = dadGroupFile.healthbar_colors;
		}
		if (bfGroupFile != null) {
			healthColors[1] = bfGroupFile.healthbar_colors;
		}
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
				if ((charType == 0 && !boyfriendMatch) || (charType == 1 && !dadMatch)) return;
				if (charData[1] != null) index = Std.parseInt(charData[1]);

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType, index);

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

			case 'Shaggy trail alpha':
				if (!dadMatch) return;
				shaggyT = new FlxTrail(dad, null, 3, 6, 0.3, 0.002);
				shaggyT.visible = false;
				addBehindDad(shaggyT);
				if (PlayState.SONG.player2 == 'sshaggy')
				{
					cameraSpeed = 2;
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
				stage.killHenchmen();

			case 'Add Camera Zoom':
				if (ClientPrefs.camZooms && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if (Math.isNaN(camZoom)) camZoom = 0.015;
					if (Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
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
				if (charGroup.members[index % charGroup.length] != null && charGroup.members[index % charGroup.length].animOffsets.exists(value1)) {
					charGroup.members[index % charGroup.length].playAnim(value1, true);
					charGroup.members[index % charGroup.length].specialAnim = true;
				}

			case 'Camera Follow Pos':
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
				var charType:Int = 0;
				var index = 0;
				var charData = value1.split(',');
				switch(charData[0].toLowerCase().trim()) {
					case 'gf' | 'girlfriend' | '2':
						charType = 2;
					case 'dad' | 'opponent' | '1':
						charType = 1;
				}
				if ((charType == 0 && !boyfriendMatch) || (charType == 1 && !dadMatch)) return;
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
							}
						}
				}
			
			case 'Change Scroll Speed':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1)) val1 = 1;
				if (Math.isNaN(val2)) val2 = 0;

				var newValue:Float = PlayState.SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;
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

			case 'Shaggy trail alpha':
				if (!dadMatch) return;
				if (dad.curCharacter == 'rshaggy')
				{
					cameraSpeed = 2.5;
				}
				else
				{
					if (value1 == '1' || value1 == 'true')
						shaggyT.visible = false;
					else
						shaggyT.visible = true;
				}

		}
		stage.onEvent(eventName, value1, value2);
	}

	function moveCameraSection():Void {
		if (PlayState.SONG.notes[curSection] == null) return;

		if (gf != null && PlayState.SONG.notes[curSection].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			if (gfGroupFile != null) {
				camFollow.x += gfGroupFile.camera_position[0] + girlfriendCameraOffset[0];
				camFollow.y += gfGroupFile.camera_position[1] + girlfriendCameraOffset[1];
			} else {
				camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
				camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			}
			return;
		}

		moveCamera(!PlayState.SONG.notes[curSection].mustHitSection);
	}

	public function moveCamera(isDad:Bool)
	{
		if (isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			var mult = 1;
			if (dad.flipped != dad.originalFlipX) {
				mult = -1;
			}

			if (dadGroupFile != null) {
				camFollow.x += (dadGroupFile.camera_position[0] + opponentCameraOffset[0]) * mult;
				camFollow.y += dadGroupFile.camera_position[1] + opponentCameraOffset[1];
			} else {
				camFollow.x += (dad.cameraPosition[0] + opponentCameraOffset[0]) * mult;
				camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			}
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			var mult = -1;
			if (boyfriend.flipped != boyfriend.originalFlipX) {
				mult = 1;
			}

			if (bfGroupFile != null) {
				camFollow.x += (bfGroupFile.camera_position[0] - boyfriendCameraOffset[0]) * mult;
				camFollow.y += bfGroupFile.camera_position[1] + boyfriendCameraOffset[1];
			} else {
				camFollow.x += (boyfriend.cameraPosition[0] - boyfriendCameraOffset[0]) * mult;
				camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];
			}
		}
	}

	var cameraTwn:FlxTween;
	function tweenCamIn() {
		if (cameraTwn == null && FlxG.camera.zoom != 1.3) {
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

	public function recalculateRating(badHit:Bool = false, player:Int = 0) {
		if (badHit)
			updateScore(true, player); // miss notes shouldn't make the scoretxt bounce -Ghost
		else
			updateScore(false, player);

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
	}

	public function updateScore(miss:Bool = false, player:Int = 0)
	{
		if (ClientPrefs.showRatings) {
			scoreTxt[player].text = 'Score: ' + Math.round(songScore[player]) + ' | Rating: ' + ratingName[player];
		} else {
			scoreTxt[player].text = 'Score: ' + Math.round(songScore[player]) + ' | Fails: ' + songMisses[player] + ' | Rating: ' + ratingName[player];
		}
		if(ratingName[player] != '?')
			scoreTxt[player].text += ' (' + Highscore.floorDecimal(ratingPercent[player] * 100, 2) + '%)' + ' - ' + ratingFC[player];

		if(ClientPrefs.scoreZoom && !miss)
		{
			if(scoreTxtTween[player] != null) {
				scoreTxtTween[player].cancel();
			}
			scoreTxt[player].scale.x = 1.0375;
			scoreTxt[player].scale.y = 1.0375;
			scoreTxtTween[player] = FlxTween.tween(scoreTxt[player].scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween) {
					scoreTxtTween[player] = null;
				}
			});
		}
	}

	private function popUpScore(note:Note = null, player:Int = 0):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		if (!note.isOpponent) coolText.x = FlxG.width * 0.55;

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = judgeNote(note, noteDiff);
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

		rating.loadGraphic(Paths.image(getUIFile(daRating.image)));
		rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.visible = !ClientPrefs.hideHud && showRating;
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];
		rating.alpha = 0.5;

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(getUIFile('combo')));
		comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = coolText.x + 80;
		comboSpr.y += 60;
		comboSpr.acceleration.y = FlxG.random.int(200, 300);
		comboSpr.velocity.y -= FlxG.random.int(140, 160);
		comboSpr.visible = !ClientPrefs.hideHud;
		comboSpr.x += ClientPrefs.comboOffset[0];
		comboSpr.y -= ClientPrefs.comboOffset[1];
		comboSpr.y += 60;
		comboSpr.velocity.x += FlxG.random.int(1, 10);
		comboSpr.alpha = 0.5;

		insert(members.indexOf(strumLineNotes), rating);

		if (!PlayState.SONG.skinModifier.endsWith('pixel'))
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * PlayState.daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * PlayState.daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if (combo[player] >= 1000) {
			seperatedScore.push(Math.floor(combo[player] / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo[player] / 100) % 10);
		seperatedScore.push(Math.floor(combo[player] / 10) % 10);
		seperatedScore.push(combo[player] % 10);

		var daLoop:Int = 0;
		var xThing:Float = 0;
		if (showCombo)
		{
			insert(members.indexOf(strumLineNotes), comboSpr);
		}
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(getUIFile('num$i')));
			numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];

			if (!PlayState.SONG.skinModifier.endsWith('pixel'))
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * PlayState.daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.visible = !ClientPrefs.hideHud;
			numScore.alpha = 0.5;

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

	public static function judgeNote(note:Note, diff:Float = 0):Rating // die
	{
		var data:Array<Rating> = PvPPlayState.instance.ratingsData; //shortening cuz fuck u
		for(i in 0...data.length - 1) //skips last window (Shit)
		{
			if (diff <= data[i].hitWindow)
			{
				return data[i];
			}
		}
		return data[data.length - 1];
	}
}

class Rating
{
	public var name:String = '';
	public var displayName:String = 'Sick!!';
	public var image:String = '';
	public var counter:String = '';
	public var hitWindow:Null<Int> = 0; //ms
	public var ratingMod:Float = 1;
	public var score:Int = 350;
	public var noteSplash:Bool = true;
	public var causesMiss = false;

	public function new(name:String)
	{
		this.name = name;
		this.image = name;
		this.counter = name + 's';
		this.hitWindow = Reflect.field(ClientPrefs, name + 'Window');
		if(hitWindow == null)
		{
			hitWindow = 0;
		}
	}

	public function increase(blah:Int = 1, player:Int = 0)
	{
		var counter:Array<Int> = Reflect.field(PvPPlayState.instance, counter);
		counter[player] += blah;
	}
}