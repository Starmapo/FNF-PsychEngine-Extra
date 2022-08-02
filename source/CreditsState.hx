package;

import flixel.util.FlxDestroyUtil;
#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

using StringTools;

class CreditsState extends MusicBeatState
{
	var curSelected:Int = -1;

	var grpOptions:FlxTypedGroup<Alphabet>;
	var iconArray:Array<AttachedSprite> = [];
	var creditsStuff:Array<Array<String>> = [];

	var bg:FlxSprite;
	var descText:FlxText;
	var intendedColor:Int;
	var colorTween:FlxTween;
	var descBox:AttachedSprite;

	var offsetThing:Float = -75;

	var warningText:FlxText;
	var warningBG:FlxSprite;

	override function create()
	{
		super.create();
		
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		persistentUpdate = true;
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		add(bg);
		bg.screenCenter();

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		var pisspoop:Array<Array<String>> = [ //Name - Icon name - Description - Link - BG Color
			['Psych Engine Extra'],
			['Leather128',			'leather',			'Leather Engine Creator\n(some code is from there)\n[NON-AFFILIATED]',	'https://www.youtube.com/channel/UCbCtO-ghipZessWaOBx8u1g',			'01A1FF'],
			['srPerez',				'perez',			'Original 6K+ designs\n[NON-AFFILIATED]',								'https://twitter.com/NewSrPerez',									'FBCA20'],
			['GitHub Contributors',	'github',			'Pull Requests to Psych Engine\n[NON-AFFILIATED]',						'https://github.com/ShadowMario/FNF-PsychEngine/pulls',				'546782'],
			[''],
			['Psych Engine Team'],
			['Shadow Mario',		'shadowmario',		'Main Programmer of Psych Engine',										'https://twitter.com/Shadow_Mario_',	'444444'],
			['RiverOaken',			'river',			'Main Artist/Animator of Psych Engine',									'https://twitter.com/RiverOaken',		'B42F71'],
			['shubs',				'shubs',			'Additional Programmer of Psych Engine',								'https://twitter.com/yoshubs',			'5E99DF'],
			[''],
			['Former Engine Members'],
			['bb-panzu',			'bb',				'Ex-Programmer of Psych Engine',										'https://twitter.com/bbsub3',			'3E813A'],
			[''],
			['Engine Contributors'],
			['iFlicky',				'flicky',			'Composer of Psync and Tea Time\nMade the Dialogue Sounds',				'https://twitter.com/flicky_i',			'9E29CF'],
			['SqirraRNG',			'sqirra',			'Crash Handler and Base code for\nChart Editor\'s Waveform',			'https://twitter.com/gedehari',			'E1843A'],
			['PolybiusProxy',		'proxy',			'.MP4 Video Loader Extension',											'https://twitter.com/polybiusproxy',	'DCD294'],
			['KadeDev',				'kade',				'Fixed some cool stuff on Chart Editor\nand other PRs',					'https://twitter.com/kade0912',			'64A250'],
			['Keoiki',				'keoiki',			'Note Splash Animations',												'https://twitter.com/Keoiki_',			'D2D2D2'],
			['Nebula the Zorua',	'nebula',			'LUA JIT Fork and some Lua reworks',									'https://twitter.com/Nebula_Zorua',		'7D40B2'],
			['Smokey',				'smokey',			'Spritemap Texture Support',											'https://twitter.com/Smokey_5_',		'483D92'],
			[''],
			["Funkin' Crew"],
			['ninjamuffin99',		'ninjamuffin99',	"Programmer of Friday Night Funkin'",									'https://twitter.com/ninja_muffin99',	'CF2D2D'],
			['PhantomArcade',		'phantomarcade',	"Animator of Friday Night Funkin'",										'https://twitter.com/PhantomArcade3K',	'FADC45'],
			['evilsk8r',			'evilsk8r',			"Artist of Friday Night Funkin'",										'https://twitter.com/evilsk8r',			'5ABD4B'],
			['kawaisprite',			'kawaisprite',		"Composer of Friday Night Funkin'",										'https://twitter.com/kawaisprite',		'378FC7']
		];
		
		for(i in pisspoop) {
			creditsStuff.push(i);
		}
	
		for (i in 0...creditsStuff.length)
		{
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(0, 70 * i, creditsStuff[i][0], !isSelectable, false);
			optionText.isMenuItem = true;
			optionText.screenCenter(X);
			optionText.yAdd -= 70;
			if (isSelectable) {
				optionText.x -= 70;
			}
			optionText.forceX = optionText.x;
			optionText.targetY = i;
			grpOptions.add(optionText);

			if (isSelectable) {
				if (curSelected == -1) {
					curSelected = i;
				}

				var icon:AttachedSprite = new AttachedSprite('credits/${creditsStuff[i][1]}');
				icon.xAdd = optionText.width + 10;
				icon.sprTracker = optionText;
	
				// using a FlxGroup is too much fuss!
				iconArray.push(icon);
				add(icon);
			}
		}

		descBox = new AttachedSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descBox.xAdd = -10;
		descBox.yAdd = -10;
		descBox.alphaMult = 0.6;
		descBox.alpha = 0.6;
		add(descBox);

		descText = new FlxText(50, FlxG.height + offsetThing - 25, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		descText.scrollFactor.set();
		descBox.sprTracker = descText;
		add(descText);
		
		warningBG = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		warningBG.alpha = 0.5;
		warningBG.visible = false;
		warningBG.scrollFactor.set();
		add(warningBG);

		warningText = new FlxText(0, 0, FlxG.width, "", 48);
		warningText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		warningText.scrollFactor.set();
		warningText.borderSize = 2;
        warningText.visible = false;
		add(warningText);

		bg.color = getCurrentBGColor();
		intendedColor = bg.color;
		changeSelection();
	}

	var quitting:Bool = false;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (!quitting) {
			if (!warningText.visible) {
				var shiftMult:Int = 1;
				if (FlxG.keys.pressed.SHIFT) shiftMult = 3;

				var upP = controls.UI_UP_P || FlxG.mouse.wheel > 0;
				var downP = controls.UI_DOWN_P || FlxG.mouse.wheel < 0;

				if (upP)
				{
					changeSelection(-1 * shiftMult);
					holdTime = 0;
				}
				if (downP)
				{
					changeSelection(1 * shiftMult);
					holdTime = 0;
				}

				if(controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						changeSelection((checkNewHold - checkLastHold) * ((controls.UI_UP) ? -shiftMult : shiftMult));
					}
				}

				if ((controls.ACCEPT || FlxG.mouse.justPressed) && creditsStuff[curSelected][3] != null && creditsStuff[curSelected][3].length > 4) {
					warningText.text = 'WARNING!!!\nYOU ARE ABOUT TO GO TO: \n${creditsStuff[curSelected][3]}\nARE YOU ABSOLUTELY SURE YOU WANT TO GO TO THIS URL? \n(ACCEPT - Yes, BACK - No)';
					warningText.screenCenter();
					warningText.visible = true;
				}
				if (controls.BACK)
				{
					if (colorTween != null) {
						colorTween.cancel();
					}
					CoolUtil.playCancelSound();
					MusicBeatState.switchState(new MainMenuState());
					quitting = true;
				}
			} else {
				if (controls.ACCEPT) {
					CoolUtil.browserLoad(creditsStuff[curSelected][3]);
					warningText.visible = false;
				}
				else if (controls.BACK) {
					warningText.visible = false;
				}
			}
		}

		for (item in grpOptions.members)
		{
			if(!item.isBold)
			{
				var lerpVal:Float = CoolUtil.boundTo(elapsed * 12, 0, 1);
				if(item.targetY == 0)
				{
					var lastX:Float = item.x;
					item.screenCenter(X);
					item.x = FlxMath.lerp(lastX, item.x - 70, lerpVal);
					item.forceX = item.x;
				}
				else
				{
					item.x = FlxMath.lerp(item.x, 200 + -40 * Math.abs(item.targetY), lerpVal);
					item.forceX = item.x;
				}
			}
		}

		warningBG.visible = warningText.visible;
		super.update(elapsed);
	}

	var moveTween:FlxTween = null;
	function changeSelection(change:Int = 0)
	{
		CoolUtil.playScrollSound();
		do {
			curSelected += change;
			if (curSelected < 0)
				curSelected = creditsStuff.length - 1;
			if (curSelected >= creditsStuff.length)
				curSelected = 0;
		} while(unselectableCheck(curSelected));

		var newColor:Int =  getCurrentBGColor();
		if (newColor != intendedColor) {
			if (colorTween != null) {
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
		}

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			if (!unselectableCheck(bullShit-1)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
				}
			}
		}
		
		descText.text = creditsStuff[curSelected][2];
		descText.y = FlxG.height - descText.height + offsetThing - 60;

		if(moveTween != null) moveTween.cancel();
		moveTween = FlxTween.tween(descText, {y : descText.y + 75}, 0.25, {ease: FlxEase.sineOut});

		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();
	}

	function getCurrentBGColor() {
		var bgColor:String = creditsStuff[curSelected][4];
		if (!bgColor.startsWith('0x')) {
			bgColor = '0xFF$bgColor';
		}
		return Std.parseInt(bgColor);
	}

	private function unselectableCheck(num:Int):Bool {
		return creditsStuff[num].length <= 1;
	}

	override public function destroy() {
		iconArray = null;
		creditsStuff = null;
		if (colorTween != null) {
			colorTween.cancel();
			colorTween.destroy();
		}
		colorTween = null;
		if (moveTween != null) {
			moveTween.cancel();
			moveTween.destroy();
		}
		moveTween = null;
		grpOptions = FlxDestroyUtil.destroy(grpOptions);
		bg = FlxDestroyUtil.destroy(bg);
		descText = FlxDestroyUtil.destroy(descText);
		descBox = FlxDestroyUtil.destroy(descBox);
		warningText = FlxDestroyUtil.destroy(warningText);
		warningBG = FlxDestroyUtil.destroy(warningBG);
		super.destroy();
	}
}