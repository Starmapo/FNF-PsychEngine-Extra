package pvp;

import haxe.Json;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.util.FlxColor;
#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

using StringTools;

class PvPSongState extends MusicBeatState {
	var songsOG:Array<SongMetadata> = [];
	var songSelects:Array<SongSelect> = [];

	public static var lastSelected:Array<Null<Int>> = [];
	public static var lastDiff:Array<Null<Int>> = [];
	public static var lastDiffName:Array<String> = [];
	public static var exiting:Bool = false;

    override function create() {
		super.create();
		
		controls.removeGamepad(0);
		MainMenuState.inPvP = true;
		exiting = false;

        persistentUpdate = true;
		PlayState.isStoryMode = false;
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
		songsOG.sort(sortAlphabetically);
		songsOG.insert(0, new SongMetadata(''));

		var songSelect1 = new SongSelect(0, 0, songsOG, true);
		songSelects.push(songSelect1);
		add(songSelect1);
		var songSelect2 = new SongSelect(FlxG.width / 2, 0, songsOG);
		songSelects.push(songSelect2);
		add(songSelect2);

		#if cpp
		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		var leText:String = "Press CTRL to open the Gameplay Changers Menu";
		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, 16);
		text.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);
		#end
    }

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!exiting) {
			#if cpp
			var ctrl = FlxG.keys.justPressed.CONTROL;

			var gamepad = FlxG.gamepads.lastActive;
			if (gamepad != null) {
				if (gamepad.justPressed.X) ctrl = true;
			}

			if (ctrl) {
				persistentUpdate = false;
				openSubState(new GameplayChangersSubState());
				return;
			}
			#end

			#if debug
			if (songSelects[1].ready && (songSelects[0].ready || FlxG.gamepads.lastActive == null))
			#else
			if (songSelects[1].ready && songSelects[0].ready)
			#end
			{
				var n = FlxG.random.int(0, 1);
				#if debug
				if (FlxG.gamepads.lastActive == null)
					n = 0;
				#end
				var chosenSong = songSelects[n];
				if (chosenSong.songs[chosenSong.curSelected].nothing) {
					n = 1 - n;
					chosenSong = songSelects[n];
					if (chosenSong.songs[chosenSong.curSelected].nothing)
						chosenSong.selectRandom();
				}
				trace(n);
				PlayState.storyDifficulty = chosenSong.curDifficulty;
				PlayState.storyWeek = chosenSong.storyWeek;
				PvPPlayState.skipStage = chosenSong.songs[chosenSong.curSelected].skipStage;
				
				persistentUpdate = false;
                var song:String = chosenSong.songs[chosenSong.curSelected].songName;
				CoolUtil.getDifficulties(song, true);
                var poop:String = Highscore.formatSong(song, chosenSong.curDifficulty);
                trace(poop);
                PlayState.SONG = Song.loadFromJson(poop, song);

                trace('CURRENT WEEK: ${WeekData.getWeekFileName()}');
                
				MusicBeatState.switchState(new PvPCharacterState());
				exiting = true;
			}
		}
	}

	override function closeSubState() {
		persistentUpdate = true;
		super.closeSubState();
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
	public var nothing:Bool = false;

	public function new(song:String, ?week:Int, ?songCharacter:String, ?color:Int, ?displayName:String, ?skipStage:Bool = false, ?difficulties:String)
	{
		songName = song;
		if (song == '') {
			nothing = true;
			this.color = FlxColor.GRAY;
			this.displayName = 'Nothing';
			this.difficulties = '';
		} else {
			this.week = week;
			this.songCharacter = songCharacter;
			this.color = color;
			this.displayName = displayName;
			if (this.displayName == null) this.displayName = songName;
			this.skipStage = skipStage;
			if (difficulties != null) this.difficulties = difficulties.trim();
		}
	}
}