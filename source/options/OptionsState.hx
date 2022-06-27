package options;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;

using StringTools;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = ['Note Colors', #if !mobile 'Controls', #end 'Adjust Delay and Combo', 'Graphics', 'Visuals and UI', 'Gameplay', 'Save Data'];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	static var goToPlayState:Bool = false;

	#if mobile
	var buttonUP:Button;
	var buttonDOWN:Button;
	var buttonENTER:Button;
	var buttonESC:Button;
	#end

	public function new(?goToPlayState:Bool)
	{
		super();
		if (goToPlayState != null)
			OptionsState.goToPlayState = goToPlayState;
	}

	function openSelectedSubState(label:String) {
		switch(label) {
			case 'Note Colors':
				openSubState(new options.NotesSubState.NotesChooseSubState());
			case 'Controls':
				openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals and UI':
				openSubState(new options.VisualsUISubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				LoadingState.loadAndSwitchState(new options.NoteOffsetState());
			case 'Save Data':
				openSubState(new options.SaveDataSubState());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create() {
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		#if !mobile
		FlxG.mouse.visible = true;
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true, false);
			optionText.screenCenter();
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true, false);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true, false);
		add(selectorRight);

		changeSelection();
		ClientPrefs.saveSettings();

		#if mobile
		buttonUP = new Button(10, 240, 'UP');
		add(buttonUP);
		buttonDOWN = new Button(buttonUP.x, buttonUP.y + buttonUP.height + 10, 'DOWN');
		add(buttonDOWN);
		buttonENTER = new Button(904, 574, 'ENTER');
		add(buttonENTER);
		buttonESC = new Button(buttonENTER.x + buttonENTER.width + 10, buttonENTER.y, 'ESC');
		add(buttonESC);
		#end

		super.create();
	}

	override function closeSubState() {
		super.closeSubState();
		ClientPrefs.saveSettings();
		for (sprite in members)
		{
			var sprite:Dynamic = sprite; //Make it check for FlxSprite instead of FlxBasic
			var sprite:FlxSprite = sprite; //Don't judge me ok
			if (sprite != null && (sprite is FlxSprite) && !(sprite is FlxText)) {
				sprite.antialiasing = ClientPrefs.globalAntialiasing;
			}
		}
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
			FlxG.mouse.visible = false;
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
			if (goToPlayState) {
				StageData.loadDirectory(PlayState.SONG);
				goToPlayState = false;
				LoadingState.loadAndSwitchState(new PlayState(), true);
			} else {
				MusicBeatState.switchState(new MainMenuState());
			}
		}

		if (controls.ACCEPT || #if mobile buttonENTER.justPressed #else FlxG.mouse.justPressed #end) {
			openSelectedSubState(options[curSelected]);
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
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}
}