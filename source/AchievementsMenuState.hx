package;

import flixel.util.FlxDestroyUtil;
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
	var achievements:Array<AchievementFile> = [];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	private var achievementArray:Array<AttachedAchievement> = [];
	private var descText:FlxText;

	override function create() {
		super.create();
		
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
			if (!Achievements.achievementsStuff[i].hiddenUntilUnlocked || Achievements.achievementsMap.exists(Achievements.achievementsStuff[i].name))
				achievements.push(Achievements.achievementsStuff[i]);
		}

		for (i in 0...achievements.length) {
			var achieveName:String = achievements[i].name;
			var optionText:Alphabet = new Alphabet(0, (100 * i) + 210, Achievements.isAchievementUnlocked(achieveName) ? achievements[i].displayName : '?');
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
	}

	var holdTime:Float = 0;
	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.UI_UP_P || FlxG.mouse.wheel > 0) {
			changeSelection(-1);
			holdTime = 0;
		}
		if (controls.UI_DOWN_P || FlxG.mouse.wheel < 0) {
			changeSelection(1);
			holdTime = 0;
		}
		var down = controls.UI_DOWN;
		var up = controls.UI_UP;
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

		if (controls.BACK) {
			CoolUtil.playCancelSound();
			MusicBeatState.switchState(new MainMenuState());
		}
	}

	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = achievements.length - 1;
		if (curSelected >= achievements.length)
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
		descText.text = achievements[curSelected].description;
		CoolUtil.playScrollSound();
	}
	#end

	override public function destroy() {
		achievements = null;
		achievementArray = null;
		grpOptions = FlxDestroyUtil.destroy(grpOptions);
		descText = FlxDestroyUtil.destroy(descText);
		super.destroy();
	}
}
