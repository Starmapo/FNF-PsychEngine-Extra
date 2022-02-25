package;

import Section.SwagSection;
import haxe.Json;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#else
import lime.utils.Assets;
#end

using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;

	var uiSkin:String;
	var uiSkinOpponent:String;
	var validScore:Bool;

	var playerKeyAmount:Null<Int>;
	var opponentKeyAmount:Null<Int>;
	var numerator:Null<Int>;
	var denominator:Null<Int>;
}

typedef DifferentJSON =
{
	var player3:String; //Psych Engine
	var mania:Null<Int>; //Shaggy
	var gf:String; //Leather Engine
	var keyCount:Null<Int>; //Leather Engine
	var playerKeyCount:Null<Int>; //Leather Engine
	var timescale:Array<Int>; //Leather Engine
	var ui_Skin:String; //Leather Engine
}

class Song
{
	private static function onLoadJson(songJson:SwagSong) // Convert old charts to newest format
	{
		var songName:String = Paths.formatToSongPath(songJson.song);

		if (songJson.events == null)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while(i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if (note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else i++;
				}
			}
		}

		if (songJson.playerKeyAmount == null)
		{
			songJson.playerKeyAmount = 4;
			songJson.opponentKeyAmount = 4;
		}
		if (songJson.numerator == null)
		{
			songJson.numerator = 4;
			songJson.denominator = 4;
		}
		if (songJson.uiSkin == null)
		{
			songJson.uiSkin = '';
		}
		if (songJson.uiSkinOpponent == null)
		{
			songJson.uiSkinOpponent = songJson.uiSkin;
		}
		
		for (secNum in 0...songJson.notes.length) {
			var sec:SwagSection = songJson.notes[secNum];
			if (sec.gfSection == null) sec.gfSection = false;
			if (sec.bpm == null) sec.bpm = songJson.bpm;
			if (sec.changeBPM == null) sec.changeBPM = false;
			if (sec.numerator == null) sec.numerator = songJson.numerator;
			if (sec.denominator == null) sec.denominator = songJson.denominator;
			if (sec.changeSignature == null) sec.changeSignature = false;
			if (sec.altAnim == null) sec.altAnim = false;
			if (sec.changeKeys == null) sec.changeKeys = false;
			if (sec.playerKeys == null) sec.playerKeys = songJson.playerKeyAmount;
			if (sec.opponentKeys == null) sec.opponentKeys = songJson.opponentKeyAmount;
			var i:Int = 0;
			var notes:Array<Dynamic> = sec.sectionNotes;
			var len:Int = notes.length;
			while(i < len)
			{
				var note:Array<Dynamic> = notes[i];
				if (note[3] != null && Std.isOfType(note[3], Int)) note[3] = editors.ChartingState.noteTypeList[note[3]];
				else if (note[3] == null) note[3] = '';
				if (note[4] == null || note[4].length < 1) note[4] = [0];
				notes[i] = [note[0], note[1], note[2], note[3], note[4]];
				i++;
			}
			songJson.notes[secNum] = sec;
		}
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson = null;
		
		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		#if MODS_ALLOWED
		var moddyFile:String = Paths.modsData('$formattedFolder/$formattedSong');
		if (FileSystem.exists(moddyFile)) {
			rawJson = File.getContent(moddyFile).trim();
		}
		#end

		if (rawJson == null) {
			#if MODS_ALLOWED
			rawJson = File.getContent(Paths.json('$formattedFolder/$formattedSong')).trim();
			#else
			rawJson = Assets.getText(Paths.json('$formattedFolder/$formattedSong')).trim();
			#end
		}

		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		var songJson:SwagSong = parseJSONshit(rawJson);
		if (formattedSong != 'events') StageData.loadDirectory(songJson);
		onLoadJson(songJson);
		return songJson;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var tempSong:DifferentJSON = cast Json.parse(rawJson).song;
		var swagShit:SwagSong = cast Json.parse(rawJson).song;

		if (swagShit.gfVersion == null) {
			if (tempSong.player3 != null) {
				swagShit.gfVersion = tempSong.player3;
			}
			if (tempSong.gf != null) {
				swagShit.gfVersion = tempSong.gf;
			}
		}
		if (swagShit.uiSkin == null) {
			if (tempSong.ui_Skin != null) {
				swagShit.uiSkin = tempSong.ui_Skin;
				swagShit.uiSkinOpponent = tempSong.ui_Skin;
			}
		}
		if (swagShit.playerKeyAmount == null) {
			if (tempSong.mania != null) {
				switch (tempSong.mania) {
					case 1:
						swagShit.playerKeyAmount = 6;
					case 2:
						swagShit.playerKeyAmount = 7;
					case 3:
						swagShit.playerKeyAmount = 9;
					default:
						swagShit.playerKeyAmount = 4;
				}
				swagShit.opponentKeyAmount = swagShit.playerKeyAmount;
			}
			if (tempSong.keyCount != null) {
				swagShit.playerKeyAmount = tempSong.keyCount;
				swagShit.opponentKeyAmount = tempSong.keyCount;
			}
			if (tempSong.playerKeyCount != null) {
				swagShit.playerKeyAmount = tempSong.playerKeyCount;
			}
		}
		if (swagShit.numerator == null && tempSong.timescale != null && tempSong.timescale.length == 2) {
			swagShit.numerator = tempSong.timescale[0];
			swagShit.denominator = tempSong.timescale[1];
		}

		swagShit.validScore = true;
		return swagShit;
	}
}
