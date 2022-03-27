package;

typedef SwagSection =
{
	var sectionNotes:Array<Array<Dynamic>>;
	var lengthInSteps:Int;
	var mustHitSection:Bool;
	var ?gfSection:Bool;
	var ?bpm:Float;
	var ?changeBPM:Bool;
	var ?numerator:Int;
	var ?denominator:Int;
	var ?changeSignature:Bool;
	var ?altAnim:Bool;
	var ?changeKeys:Bool;
	var ?playerKeys:Int;
	var ?opponentKeys:Int;
}