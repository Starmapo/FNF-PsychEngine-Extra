package;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import Achievements;

using StringTools;

class AchievementsMenuState extends MusicBeatState
{
	#if ACHIEVEMENTS_ALLOWED
	var options:Array<AchievementFile> = [];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	private var achievementArray:Array<AttachedAchievement> = [];
	private var descText:FlxText;

	#if mobile
	var buttonUP:Button;
	var buttonDOWN:Button;
	var buttonESC:Button;
	#end

	override function create() {
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Achievements Menu", null);
		#end

		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBGBlue'));
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = ClientPrefs.globalAntialiasing;
		add(menuBG);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);
		
		Achievements.loadAchievements();
		for (i in 0...Achievements.achievementsStuff.length) {
			if (!Achievements.achievementsStuff[i].hiddenUntilUnlocked || Achievements.achievementsMap.exists(Achievements.achievementsStuff[i].name)) {
				options.push(Achievements.achievementsStuff[i]);
			}
		}

		for (i in 0...options.length) {
			var achieveName:String = options[i].name;
			var optionText:Alphabet = new Alphabet(0, (100 * i) + 210, Achievements.isAchievementUnlocked(achieveName) ? options[i].displayName : '?');
			optionText.isMenuItem = true;
			optionText.x += 280;
			optionText.xAdd = 200;
			optionText.targetY = i;
			grpOptions.add(optionText);

			var icon:AttachedAchievement = new AttachedAchievement(optionText.x - 105, optionText.y, achieveName);
			icon.sprTracker = optionText;
			achievementArray.push(icon);
			add(icon);
		}

		descText = new FlxText(150, 600, 980, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);
		changeSelection();

		#if mobile
		buttonUP = new Button(10, 130, 'UP');
		buttonDOWN = new Button(buttonUP.x, buttonUP.y + buttonUP.height + 10, 'DOWN');
		buttonESC = new Button(1134, 564, 'ESC');

		add(buttonUP);
		add(buttonDOWN);
		add(buttonESC);
		#end

		super.create();
	}

	var holdTime:Float = 0;
	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.UI_UP_P || #if mobile buttonUP.justPressed #else FlxG.mouse.wheel > 0 #end) {
			changeSelection(-1);
			holdTime = 0;
		}
		if (controls.UI_DOWN_P || #if mobile buttonDOWN.justPressed #else FlxG.mouse.wheel < 0 #end) {
			changeSelection(1);
			holdTime = 0;
		}
		var down = controls.UI_DOWN #if mobile || buttonDOWN.pressed #end;
		var up = controls.UI_UP #if mobile || buttonUP.pressed #end;
		if (down || up)
		{
			var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
			holdTime += elapsed;
			var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

			if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
			{
				changeSelection((checkNewHold - checkLastHold) * (up ? -1 : 1));
			}
		}

		if (controls.BACK #if mobile || buttonESC.justPressed #end) {
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
			MusicBeatState.switchState(new MainMenuState());
		}
	}

	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
			}
		}

		for (i in 0...achievementArray.length) {
			achievementArray[i].alpha = 0.6;
			if (i == curSelected) {
				achievementArray[i].alpha = 1;
			}
		}
		descText.text = options[curSelected].description;
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}
	#end
}
