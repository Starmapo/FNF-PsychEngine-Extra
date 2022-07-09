package editors;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using StringTools;

class MasterEditorMenu extends MusicBeatState
{
	var options:Array<String> = [
		'Character Editor',
		'Chart Editor',
		'Dialogue Editor',
		'Dialogue Portrait Editor',
		'Menu Character Editor',
		'Week Editor'
	];
	private var grpTexts:FlxTypedGroup<Alphabet>;

	private var curSelected = 0;

	override function create()
	{
		FlxG.camera.bgColor = FlxColor.BLACK;
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Editors Main Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF353535;
		add(bg);

		grpTexts = new FlxTypedGroup<Alphabet>();
		add(grpTexts);

		for (i in 0...options.length)
		{
			var leText:Alphabet = new Alphabet(0, (70 * i) + 30, options[i], true, false);
			leText.isMenuItem = true;
			leText.targetY = i;
			grpTexts.add(leText);
		}
		
		changeSelection();

		FlxG.mouse.visible = false;
		super.create();
	}

	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (controls.UI_UP_P || FlxG.mouse.wheel > 0)
		{
			changeSelection(-1);
			holdTime = 0;
		}
		if (controls.UI_DOWN_P || FlxG.mouse.wheel < 0)
		{
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

		if (controls.BACK)
		{
			MusicBeatState.switchState(new MainMenuState());
		}

		if (controls.ACCEPT || FlxG.mouse.justPressed)
		{
			switch(options[curSelected]) {
				case 'Character Editor':
					PlayState.SONG = null;
					LoadingState.loadAndSwitchState(new CharacterEditorState(Character.DEFAULT_CHARACTER, false));
				case 'Week Editor':
					MusicBeatState.switchState(new WeekEditorState());
				case 'Menu Character Editor':
					MusicBeatState.switchState(new MenuCharacterEditorState());
				case 'Dialogue Portrait Editor':
					PlayState.SONG = null;
					LoadingState.loadAndSwitchState(new DialogueCharacterEditorState());
				case 'Dialogue Editor':
					PlayState.SONG = null;
					LoadingState.loadAndSwitchState(new DialogueEditorState());
				case 'Chart Editor'://felt it would be cool maybe
					PlayState.chartingMode = true;
					LoadingState.loadAndSwitchState(new ChartingState(true));
			}
			FlxG.sound.music.volume = 0;
			FreeplayState.destroyFreeplayVocals();
		}
		
		var bullShit:Int = 0;
		for (item in grpTexts.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}
		super.update(elapsed);
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;
	}
}