package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

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

	var warningText:FlxText;
	var warningBG:FlxSprite;

	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		add(bg);
		bg.screenCenter();

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		#if MODS_ALLOWED
		//trace("finding mod shit");
		for (folder in Paths.getModDirectories())
		{
			var creditsFile:String = Paths.mods(folder + '/data/credits.txt');
			if (FileSystem.exists(creditsFile))
			{
				var firstarray:Array<String> = File.getContent(creditsFile).split('\n');
				for(i in firstarray)
				{
					var arr:Array<String> = i.replace('\\n', '\n').split("::");
					if(arr.length >= 5) arr.push(folder);
					creditsStuff.push(arr);
				}
				creditsStuff.push(['']);
			}
		};
		var folder = "";
			var creditsFile:String = Paths.mods('data/credits.txt');
			if (FileSystem.exists(creditsFile))
			{
				var firstarray:Array<String> = File.getContent(creditsFile).split('\n');
				for(i in firstarray)
				{
					var arr:Array<String> = i.replace('\\n', '\n').split("::");
					if(arr.length >= 5) arr.push(folder);
					creditsStuff.push(arr);
				}
				creditsStuff.push(['']);
			}
		#end

		var pisspoop:Array<Array<String>> = [ //Name - Icon name - Description - Link - BG Color
			['Psych Engine Extra'],
			['srPerez',				'srperez',			'Original multi-key designs',							'https://twitter.com/NewSrPerez',									'FBCA20'],
			['KadeDev',				'kade',				'Kade Engine Creator\n(some code is from there)',		'https://twitter.com/kade0912',										'4F6441'],
			['Leather128',			'leather',			'Leather Engine Creator\n(some code is from there)',	'https://www.youtube.com/channel/UCbCtO-ghipZessWaOBx8u1g',			'01A1FF'],
			['GitHub Contributors',	'github',			'Pull Requests to Psych Engine',						'https://github.com/ShadowMario/FNF-PsychEngine/pulls',				'546782'],
			[''],
			['Psych Engine Team'],
			['Shadow Mario',		'shadowmario',		'Main Programmer of Psych Engine',						'https://twitter.com/Shadow_Mario_',	'444444'],
			['RiverOaken',			'riveroaken',		'Main Artist/Animator of Psych Engine',					'https://twitter.com/river_oaken',		'C30085'],
			['bb-panzu',			'bb-panzu',			'Additional Programmer of Psych Engine',				'https://twitter.com/bbsub3',			'389A58'],
			[''],
			['Engine Contributors'],
			['shubs',				'shubs',			'New Input System Programmer',							'https://twitter.com/yoshubs',			'4494E6'],
			['SqirraRNG',			'gedehari',			'Chart Editor\'s Sound Waveform base',					'https://twitter.com/gedehari',			'FF9300'],
			['iFlicky',				'iflicky',			'Delay/Combo Menu Song Composer\nand Dialogue Sounds',	'https://twitter.com/flicky_i',			'C549DB'],
			['PolybiusProxy',		'polybiusproxy',	'.MP4 Video Loader Extension',							'https://twitter.com/polybiusproxy',	'FFEAA6'],
			['Keoiki',				'keoiki',			'Note Splash Animations',								'https://twitter.com/Keoiki_',			'FFFFFF'],
			['Smokey',				'smokey',			'Spritemap Texture Support',							'https://twitter.com/Smokey_5_',		'0033CC'],
			[''],
			["Funkin' Crew"],
			['ninjamuffin99',		'ninjamuffin99',	"Programmer of Friday Night Funkin'",					'https://twitter.com/ninja_muffin99',	'F73838'],
			['PhantomArcade',		'phantomarcade',	"Animator of Friday Night Funkin'",						'https://twitter.com/PhantomArcade3K',	'FFBB1B'],
			['evilsk8r',			'evilsk8r',			"Artist of Friday Night Funkin'",						'https://twitter.com/evilsk8r',			'53E52C'],
			['kawaisprite',			'kawaisprite',		"Composer of Friday Night Funkin'",						'https://twitter.com/kawaisprite',		'6475F3']
		];
		
		for(i in pisspoop){
			creditsStuff.push(i);
		}
	
		for (i in 0...creditsStuff.length)
		{
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(0, 70 * i, creditsStuff[i][0], !isSelectable, false);
			optionText.isMenuItem = true;
			optionText.screenCenter(X);
			optionText.yAdd -= 70;
			if(isSelectable) {
				optionText.x -= 70;
			}
			optionText.forceX = optionText.x;
			//optionText.yMult = 90;
			optionText.targetY = i;
			grpOptions.add(optionText);

			if(isSelectable) {
				if(creditsStuff[i][5] != null)
				{
					Paths.currentModDirectory = creditsStuff[i][5];
				}

				var icon:AttachedSprite = new AttachedSprite('credits/' + creditsStuff[i][1]);
				icon.xAdd = optionText.width + 10;
				icon.sprTracker = optionText;
	
				// using a FlxGroup is too much fuss!
				iconArray.push(icon);
				add(icon);
				Paths.currentModDirectory = '';

				if(curSelected == -1) curSelected = i;
			}
		}

		var descBar = new FlxSprite(0, 550).makeGraphic(FlxG.width, FlxG.height - 550, FlxColor.BLACK);
		descBar.alpha = 0.5;
		descBar.scrollFactor.set();
		add(descBar);

		descText = new FlxText(50, 600, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
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
		super.create();
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;

		if (!warningText.visible) {
			if (FlxG.mouse.wheel != 0) {
				changeSelection(Std.int(CoolUtil.boundTo(FlxG.mouse.wheel, -1, 1)) * -1);
			}
			if (upP)
			{
				changeSelection(-1);
			}
			if (downP)
			{
				changeSelection(1);
			}
		}

		if (controls.BACK && !warningText.visible)
		{
			if(colorTween != null) {
				colorTween.cancel();
			}
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}
		if((controls.ACCEPT || FlxG.mouse.justPressed) && !warningText.visible) {
			warningText.text = "WARNING!!!\nYOU ARE ABOUT TO GO TO: \n" + creditsStuff[curSelected][3] + "\nARE YOU ABSOLUTELY SURE YOU WANT TO GO TO THIS URL? \n(Y - Yes, N - No)";
			warningText.screenCenter();
			warningText.visible = true;
		}
		if (warningText.visible) {
			if (FlxG.keys.pressed.Y) {
				CoolUtil.browserLoad(creditsStuff[curSelected][3]);
				warningText.visible = false;
			}
			else if (FlxG.keys.pressed.N || controls.BACK) {
				warningText.visible = false;
			}
		}
		warningBG.visible = warningText.visible;
		super.update(elapsed);
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		do {
			curSelected += change;
			if (curSelected < 0)
				curSelected = creditsStuff.length - 1;
			if (curSelected >= creditsStuff.length)
				curSelected = 0;
		} while(unselectableCheck(curSelected));

		var newColor:Int =  getCurrentBGColor();
		if(newColor != intendedColor) {
			if(colorTween != null) {
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

			if(!unselectableCheck(bullShit-1)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
				}
			}
		}
		descText.text = creditsStuff[curSelected][2];
	}

	function getCurrentBGColor() {
		var bgColor:String = creditsStuff[curSelected][4];
		if(!bgColor.startsWith('0x')) {
			bgColor = '0xFF' + bgColor;
		}
		return Std.parseInt(bgColor);
	}

	private function unselectableCheck(num:Int):Bool {
		return creditsStuff[num].length <= 1;
	}
}