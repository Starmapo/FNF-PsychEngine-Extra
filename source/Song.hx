package;

import Section.SwagSection;
import haxe.Json;
import lime.utils.Assets;
#if sys
import sys.io.File;
import sys.FileSystem;
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
	var player3:String; //deprecated, now replaced by gfVersion
	var gfVersion:String;
	var stage:String;

	var arrowSkin:String;
	var splashSkin:String;
	var validScore:Bool;

	var keyAmount:Null<Int>;
	var numerator:Null<Int>;
	var denominator:Null<Int>;
}

typedef DifferentJSON =
{
	var mania:Null<Int>; //Shaggy
	var keyCount:Null<Int>; //Leather Engine
	var timescale:Array<Int>; //Leather Engine
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var bpm:Float;

	private static function onLoadJson(songJson:SwagSong) // Convert old charts to newest format
	{
		var songName:String = Paths.formatToSongPath(songJson.song);

		if(songJson.events == null)
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
					if(note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else i++;
				}
			}
		}

		for (secNum in 0...songJson.notes.length) { //removing int note types
			var sec:SwagSection = songJson.notes[secNum];
			var i:Int = 0;
			var notes:Array<Dynamic> = sec.sectionNotes;
			var len:Int = notes.length;
			while(i < len)
			{
				var note:Array<Dynamic> = notes[i];
				if (note[1] > -1) {
					var daStrum:Float = note[0];
					var daData:Int = note[1];
					var daSusLength:Float = note[2];
					var daType:String = note[3];
					if(!Std.isOfType(note[3], String) && note[3] < 6) daType = editors.ChartingState.noteTypeList[note[3]];
					sec.sectionNotes[i] = [daStrum, daData, daSusLength, daType];
				}
				i++;
			}
		}

		if(songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			songJson.player3 = null;
		}
		
		if(songJson.keyAmount == null)
		{
			songJson.keyAmount = 4;
		}
		if(songJson.numerator == null)
		{
			songJson.numerator = 4;
		}
		if(songJson.denominator == null)
		{
			songJson.denominator = 4;
		}

		if(songJson.notes[0].changeSignature == null)
		{
			for (secNum in 0...songJson.notes.length)
			{
				songJson.notes[secNum].changeSignature = false;
				songJson.notes[secNum].numerator = songJson.numerator;
				songJson.notes[secNum].denominator = songJson.denominator;
			}
		}
	}

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson = null;
		
		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		#if MODS_ALLOWED
		var moddyFile:String = Paths.modsJson(formattedFolder + '/' + formattedSong);
		if(FileSystem.exists(moddyFile)) {
			rawJson = File.getContent(moddyFile).trim();
		}
		#end

		if(rawJson == null) {
			#if sys
			rawJson = File.getContent(Paths.json(formattedFolder + '/' + formattedSong)).trim();
			#else
			rawJson = Assets.getText(Paths.json(formattedFolder + '/' + formattedSong)).trim();
			#end
		}

		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		// FIX THE CASTING ON WINDOWS/NATIVE
		// Windows???
		// trace(songData);

		// trace('LOADED FROM JSON: ' + songData.notes);
		/* 
			for (i in 0...songData.notes.length)
			{
				trace('LOADED FROM JSON: ' + songData.notes[i].sectionNotes);
				// songData.notes[i].sectionNotes = songData.notes[i].sectionNotes
			}

				daNotes = songData.notes;
				daSong = songData.song;
				daBpm = songData.bpm; */

		var songJson:SwagSong = parseJSONshit(rawJson);
		if(formattedSong != 'events') StageData.loadDirectory(songJson);
		onLoadJson(songJson);
		return songJson;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var tempSong:DifferentJSON = cast Json.parse(rawJson).song;

		var swagShit:SwagSong = cast Json.parse(rawJson).song;
		if (tempSong.mania != null && !Math.isNaN(tempSong.mania)) {
			switch (tempSong.mania) {
				case 1:
					swagShit.keyAmount = 6;
				case 2:
					swagShit.keyAmount = 7;
				case 3:
					swagShit.keyAmount = 9;
				default:
					swagShit.keyAmount = 4;
			}
		}
		if (tempSong.keyCount != null && !Math.isNaN(tempSong.keyCount)) {
			swagShit.keyAmount = tempSong.keyCount;
		}
		if (tempSong.timescale != null && tempSong.timescale.length == 2) {
			swagShit.numerator = tempSong.timescale[0];
			swagShit.denominator = tempSong.timescale[1];
		}
		swagShit.validScore = true;
		return swagShit;
	}
}
