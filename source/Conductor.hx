package;

import Song.SwagSong;
import flixel.math.FlxMath;

/**
 * ...
 * @author
 */

typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
}

typedef SignatureChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var numerator:Int;
	var denominator:Int;
}

class Conductor
{
	public static var bpm:Float = 100;
	public static var crochet:Float = ((60 / bpm) * 1000); // beats in milliseconds
	public static var stepCrochet:Float = crochet / 4; // steps in milliseconds
	public static var songPosition:Float = 0;
	public static var numerator:Int = 4;
	public static var denominator:Int = 4;

	public static var safeZoneOffset:Float = (ClientPrefs.safeFrames / 60) * 1000; // is calculated in create(), is safeFrames in milliseconds

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];
	public static var signatureChangeMap:Array<SignatureChangeEvent> = [];

	public function new()
	{
	}

	public static function judgeNote(diff:Float = 0) //STOLEN FROM KADE ENGINE (bbpanzu) - I had to rewrite it later anyway after i added the custom hit windows lmao (Shadow Mario)
	{
		//tryna do MS based judgment due to popular demand
		var timingWindows:Array<Int> = [ClientPrefs.sickWindow, ClientPrefs.goodWindow, ClientPrefs.badWindow];
		var windowNames:Array<String> = ['sick', 'good', 'bad'];

		for(i in 0...timingWindows.length) // based on 4 timing windows, will break with anything else
		{
			if (diff <= timingWindows[FlxMath.minInt(i, timingWindows.length - 1)])
			{
				return windowNames[i];
			}
		}
		return 'shit';
	}
	public static function mapBPMChanges(song:SwagSong, ?mult:Float = 1)
	{
		bpmChangeMap = [];
		signatureChangeMap = [];

		var curBPM:Float = song.bpm * mult;
		var curNumerator:Int = song.numerator;
		var curDenominator:Int = song.denominator;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (i in 0...song.notes.length)
		{
			if (song.notes[i].changeBPM && song.notes[i].bpm * mult != curBPM && song.notes[i].bpm > 0)
			{
				curBPM = song.notes[i].bpm * mult;
				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM
				};
				bpmChangeMap.push(event);
			}
			if (song.notes[i].changeSignature && (song.notes[i].numerator != curNumerator || song.notes[i].denominator != curDenominator))
			{
				curNumerator = song.notes[i].numerator;
				curDenominator = song.notes[i].denominator;
				var event:SignatureChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					numerator: curNumerator,
					denominator: curDenominator
				};
				signatureChangeMap.push(event);
			}

			var deltaSteps:Int = song.notes[i].lengthInSteps;
			totalSteps += deltaSteps;
			totalPos += ((((60 / curBPM) * 4000) / curDenominator) / 4) * deltaSteps;
		}
	}

	public static function changeBPM(newBpm:Float, ?mult:Float = 1)
	{
		if (newBpm > 0) {
			bpm = newBpm * mult;

			crochet = ((60 / bpm) * 4000) / denominator;
			stepCrochet = crochet / 4;
		}
	}

	public static function changeSignature(newNumerator:Int, newDenominator:Int)
	{
		numerator = newNumerator;
		denominator = newDenominator;

		crochet = ((60 / bpm) * 4000) / denominator;
		stepCrochet = crochet / 4;
	}

	public static function getLastBPM(song:SwagSong, step:Int, ?mult:Float = 1) {
		var daBPM:Float = song.bpm * mult;
		var daNumerator:Int = song.numerator;
		var daDenominator:Int = song.denominator;
		for (i in 0...bpmChangeMap.length) {
			if (step >= bpmChangeMap[i].stepTime) {
				daBPM = bpmChangeMap[i].bpm;
			}
		}
		for (i in 0...signatureChangeMap.length) {
			if (step >= signatureChangeMap[i].stepTime) {
				daNumerator = signatureChangeMap[i].numerator;
				daDenominator = signatureChangeMap[i].denominator;
			}
		}
		if (bpm != daBPM)
			changeBPM(daBPM);
		if (numerator != daNumerator || denominator != daDenominator)
			changeSignature(daNumerator, daDenominator);
	}

	public static function getCurSection(song:SwagSong, step:Int):Int {
		//every time i try to optimize this it just fucking stops working
		if (step < 0) {
			return 0;
		}
		var daNumerator:Int = song.numerator;
		var daPos:Int = 0;
		var lastStep:Int = 0;
		for (i in 0...song.notes.length) {
			if (song.notes[i] != null) {
				if (song.notes[i].changeSignature) {
					daNumerator = song.notes[i].numerator;
				}
			}
			if (lastStep + (daNumerator * 4) >= step) {
				return FlxMath.maxInt(daPos + Math.floor((step - lastStep) / (daNumerator * 4)), 0);
			}
			lastStep += daNumerator * 4;
			daPos++;
		}
		return FlxMath.maxInt(daPos, 0);
	}

	public static function getCurNumeratorBeat(song:SwagSong, beat:Int):Int {
		var lastBeat = 0;
		var daBeat = 0;
		var daNumerator = song.numerator;
		for (i in 0...song.notes.length) {
			if (song.notes[i] != null && beat >= daBeat) {
				if (song.notes[i].changeSignature) {
					daNumerator = song.notes[i].numerator;
					lastBeat = daBeat;
				}
				daBeat += daNumerator;
			}
		}
		return beat - lastBeat;
	}
}
