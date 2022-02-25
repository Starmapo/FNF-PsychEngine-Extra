package;

typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var lengthInSteps:Int;
	var mustHitSection:Bool;
	var gfSection:Null<Bool>;
	var bpm:Null<Float>;
	var changeBPM:Null<Bool>;
	var numerator:Null<Int>;
	var denominator:Null<Int>;
	var changeSignature:Null<Bool>;
	var altAnim:Null<Bool>;
	var changeKeys:Null<Bool>;
	var playerKeys:Null<Int>;
	var opponentKeys:Null<Int>;
}