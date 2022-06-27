package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.effects.FlxFlicker;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;

	var warnText:FlxText;

	#if mobile
	var buttonENTER:Button;
	var buttonESC:Button;
	#end
	override function create()
	{
		super.create();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		warnText = new FlxText(0, 0, FlxG.width,
			"Hey, watch out!\n
			This Mod contains some flashing lights!\n
			Press ENTER to disable them now or go to Options Menu.\n
			Press ESCAPE to ignore this message.\n
			You've been warned!",
			32);
		warnText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		add(warnText);

		#if mobile
		buttonENTER = new Button(904, 574, 'ENTER');
		add(buttonENTER);
		buttonESC = new Button(buttonENTER.x + buttonENTER.width + 50, buttonENTER.y, 'ESC');
		add(buttonESC);
		#end
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (!leftState) {
			#if mobile
			var accept:Bool = controls.ACCEPT || buttonENTER.justReleased;
			var back:Bool = controls.BACK || buttonESC.justReleased;
			#else
			var accept:Bool = controls.ACCEPT;
			var back:Bool = controls.BACK;
			#end
			if (accept || back) {
				leftState = true;
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				if (!back) {
					ClientPrefs.flashing = false;
					ClientPrefs.saveSettings();
					FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
					FlxFlicker.flicker(warnText, 1, 0.1, false, true, function(flk:FlxFlicker) {
						new FlxTimer().start(0.5, function (tmr:FlxTimer) {
							MusicBeatState.switchState(new TitleState());
						});
					});
				} else {
					ClientPrefs.flashing = true;
					ClientPrefs.saveSettings();
					FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
					FlxTween.tween(warnText, {alpha: 0}, 1, {
						onComplete: function (twn:FlxTween) {
							MusicBeatState.switchState(new TitleState());
						}
					});
				}
			}
		}
	}
}
