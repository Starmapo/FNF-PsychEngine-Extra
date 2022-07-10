package pvp;

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

class PvPPlayState extends MusicBeatState {
    //event variables
	private var isCameraOnForcedPos:Bool = false;
	public var boyfriendMap:Map<String, Character> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();

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
	public var keybindGroup:FlxTypedGroup<AttachedFlxText>;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	public var camBop:Bool = false;
	public var curSong:String = "";
	public var curSongDisplayName:String = "";

	public var health:Float = 1;
	public var shownHealth:Float = 1;
	public var p1Combo:Int = 0;
	public var p2Combo:Int = 0;

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

	public var songScore:Array<Int> = [0, 0];
	public var songMisses:Array<Int> = [0, 0];
	public var scoreTxt:Array<FlxText>;
	var timeTxt:FlxText;
	var songTxt:FlxText;
	var scoreTxtTween:Array<FlxTween>;

	public var ratingTxtGroup:Array<FlxTypedGroup<FlxText>>;
	public var ratingTxtTweens:Array<Array<FlxTween>> = [[null], [null]];

	public var defaultCamZoom:Float = 1.05;
	public var defaultCamHudZoom:Float = 1;

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
	#end

	// Lua shit
	public static var instance:PvPPlayState;
	
	// Less laggy controls
	private var keysArray:Array<Array<Array<FlxKey>>>;

	var bfGroupFile:CharacterGroupFile = null;
	var dadGroupFile:CharacterGroupFile = null;
	var gfGroupFile:CharacterGroupFile = null;

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
        super.create();
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
	public var player:Int = 0;

	public function new(name:String, player:Int)
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

	public function increase(blah:Int = 1)
	{
		var counter:Array<Int> = Reflect.field(PvPPlayState.instance, counter);
		counter[player] += blah;
	}
}