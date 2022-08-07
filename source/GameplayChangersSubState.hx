package;

import flixel.util.FlxDestroyUtil;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

using StringTools;

class GameplayChangersSubState extends MusicBeatSubState
{
	private var curOption:GameplayOption = null;
	private var curSelected:Int = 0;
	private var optionsArray:Array<GameplayOption> = [];

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var checkboxGroup:FlxTypedGroup<CheckboxThingie>;
	private var grpTexts:FlxTypedGroup<AttachedText>;

	private var descBox:FlxSprite;
	private var descText:FlxText;

	function getOptions()
	{
		if (!MainMenuState.inPvP) {
			var goption:GameplayOption = new GameplayOption('Scroll Type',
				'How should the scroll speed be affected?',
				'scrolltype',
				'string',
				'multiplicative',
				["multiplicative", "constant"]);
			optionsArray.push(goption);

			var option:GameplayOption = new GameplayOption('Scroll Speed',
				'',
				'scrollspeed',
				'float',
				1);
			option.scrollSpeed = 1.5;
			option.minValue = 0.5;
			option.changeValue = 0.1;
			if (goption.getValue() != "constant")
			{
				option.description = "Multiplies the chart's scroll speed.";
				option.displayFormat = '%vX';
				option.maxValue = 3;
			}
			else
			{
				option.description = 'Forces a single scroll speed for every chart.';
				option.displayFormat = "%v";
				option.maxValue = 6;
			}
			optionsArray.push(option);
		}

		#if cpp
		var option:GameplayOption = new GameplayOption('Playback Rate',
			"Changes the song's playback rate, making it go faster.",
			'songspeed',
			'float',
			1);
		option.scrollSpeed = 0.5;
		option.minValue = 1;
		option.maxValue = 2.5;
		option.decimals = 2;
		option.changeValue = 0.01;
		option.displayFormat = '%vX';
		optionsArray.push(option);
		#end

		if (!MainMenuState.inPvP) {
			var option:GameplayOption = new GameplayOption('Health Gain Multiplier',
				"Multiplies the health gained from hitting notes.",
				'healthgain',
				'float',
				1);
			option.scrollSpeed = 2.5;
			option.minValue = 0;
			option.maxValue = 5;
			option.changeValue = 0.1;
			option.displayFormat = '%vX';
			optionsArray.push(option);

			var option:GameplayOption = new GameplayOption('Health Loss Multiplier',
				"Multiplies the health lost from missing notes or hitting hurt notes.",
				'healthloss',
				'float',
				1);
			option.scrollSpeed = 2.5;
			option.minValue = 0.5;
			option.maxValue = 5;
			option.changeValue = 0.1;
			option.displayFormat = '%vX';
			optionsArray.push(option);

			var option:GameplayOption = new GameplayOption('Play as Opponent',
				"Self-explanatory! Does not save your score.",
				'opponentplay',
				'bool',
				false);
			optionsArray.push(option);

			var option:GameplayOption = new GameplayOption('Instakill on Miss',
				"Instantly die if you miss a note or hit a hurt note.",
				'instakill',
				'bool',
				false);
			optionsArray.push(option);

			var option:GameplayOption = new GameplayOption('Practice Mode',
				"Prevents you from dying. Does not save your score.",
				'practice',
				'bool',
				false);
			optionsArray.push(option);

			var option:GameplayOption = new GameplayOption('Botplay',
				"Let the game play by itself!",
				'botplay',
				'bool',
				false);
			optionsArray.push(option);

			var option:GameplayOption = new GameplayOption('Demo Mode',
				"Hides most HUD elements so you can showcase the song. Botplay is activated.",
				'demomode',
				'bool',
				false);
			optionsArray.push(option);
		}
	}

	public function getOptionByName(name:String)
	{
		for(i in optionsArray)
		{
			var opt:GameplayOption = i;
			if (opt.name == name)
				return opt;
		}
		return null;
	}

	public function new()
	{
		super();
		
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		// avoids lagspikes while scrolling through menus!
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		grpTexts = new FlxTypedGroup<AttachedText>();
		add(grpTexts);

		checkboxGroup = new FlxTypedGroup<CheckboxThingie>();
		add(checkboxGroup);

		descBox = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0.6;
		add(descBox);

		descText = new FlxText(50, 600, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);
		
		getOptions();

		for (i in 0...optionsArray.length)
		{
			var optionText:Alphabet = new Alphabet(0, 70 * i, optionsArray[i].name, true, false, 0.05, 0.8);
			optionText.isMenuItem = true;
			optionText.x += 300;
			optionText.xAdd = 120;
			optionText.targetY = i;
			grpOptions.add(optionText);

			if (optionsArray[i].type == 'bool') {
				var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, optionsArray[i].getValue() == true);
				checkbox.sprTracker = optionText;
				checkbox.offsetY = -60;
				checkbox.ID = i;
				checkboxGroup.add(checkbox);
				optionText.xAdd += 80;
			} else {
				var valueText:AttachedText = new AttachedText('${optionsArray[i].getValue()}', optionText.width + 80, true, 0.8);
				valueText.sprTracker = optionText;
				valueText.copyAlpha = true;
				valueText.ID = i;
				grpTexts.add(valueText);
				optionsArray[i].setChild(valueText);
			}
			updateTextFrom(optionsArray[i]);
		}

		changeSelection();
		reloadCheckboxes();
	}

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;
	override function update(elapsed:Float)
	{
		var upP = controls.UI_UP_P;
        var downP = controls.UI_DOWN_P;
		var leftP = controls.UI_LEFT_P;
        var rightP = controls.UI_RIGHT_P;
        var up = controls.UI_UP;
        var down = controls.UI_DOWN;
		var left = controls.UI_LEFT;
        var right = controls.UI_RIGHT;
		var leftR = controls.UI_LEFT_R;
        var rightR = controls.UI_RIGHT_R;
        var accept = controls.ACCEPT;
        var back = controls.BACK;
		var reset = controls.RESET;
		if (MainMenuState.inPvP) {
			var gamepad = FlxG.gamepads.lastActive;
			if (gamepad != null) {
				if (gamepad.justPressed.LEFT_STICK_DIGITAL_UP || gamepad.justPressed.DPAD_UP) upP = true;
				if (gamepad.justPressed.LEFT_STICK_DIGITAL_DOWN || gamepad.justPressed.DPAD_DOWN) downP = true;
				if (gamepad.justPressed.LEFT_STICK_DIGITAL_LEFT || gamepad.justPressed.DPAD_LEFT) leftP = true;
				if (gamepad.justPressed.LEFT_STICK_DIGITAL_RIGHT || gamepad.justPressed.DPAD_RIGHT) rightP = true;
				if (gamepad.pressed.LEFT_STICK_DIGITAL_UP || gamepad.pressed.DPAD_UP) up = true;
				if (gamepad.pressed.LEFT_STICK_DIGITAL_DOWN || gamepad.pressed.DPAD_DOWN) down = true;
				if (gamepad.pressed.LEFT_STICK_DIGITAL_LEFT || gamepad.pressed.DPAD_LEFT) left = true;
				if (gamepad.pressed.LEFT_STICK_DIGITAL_RIGHT || gamepad.pressed.DPAD_RIGHT) right = true;
				if (gamepad.justReleased.LEFT_STICK_DIGITAL_LEFT || gamepad.justReleased.DPAD_LEFT) leftR = true;
				if (gamepad.justReleased.LEFT_STICK_DIGITAL_RIGHT || gamepad.justReleased.DPAD_RIGHT) rightR = true;
				if (gamepad.justPressed.A) accept = true;
				if (gamepad.justPressed.B) back = true;
				if (gamepad.justPressed.Y) reset = true;
			}
		}

		if (upP || FlxG.mouse.wheel > 0)
		{
			changeSelection(-1);
			holdTime = 0;
		}
		if (downP || FlxG.mouse.wheel < 0)
		{
			changeSelection(1);
			holdTime = 0;
		}

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

		if (back) {
			close();
			ClientPrefs.saveSettings();
			CoolUtil.playCancelSound();
		}

		if (nextAccept <= 0)
		{
			var usesCheckbox = true;
			if (curOption.type != 'bool')
			{
				usesCheckbox = false;
			}

			if (usesCheckbox)
			{
				if (accept || FlxG.mouse.justPressed)
				{
					CoolUtil.playScrollSound();
					curOption.setValue((curOption.getValue() == true) ? false : true);
					curOption.change();
					reloadCheckboxes();
				}
			} else if (!down && !up) {
				if (left || right || (FlxG.mouse.wheel != 0 && FlxG.keys.pressed.SHIFT)) {
					var pressed = (leftP || rightP);
					var useWheel = FlxG.mouse.wheel != 0 && FlxG.keys.pressed.SHIFT;
					if (holdTime > 0.5 || pressed || useWheel) {
						if (pressed || useWheel) {
							var add:Dynamic = null;
							if (curOption.type != 'string') {
								if (useWheel) {
									add = curOption.changeValue * Std.int(CoolUtil.boundTo(FlxG.mouse.wheel, -1, 1));
								} else {
									add = (left) ? -curOption.changeValue : curOption.changeValue;
								}
							}

							switch(curOption.type)
							{
								case 'int' | 'float' | 'percent':
									holdValue = curOption.getValue() + add;
									if (holdValue < curOption.minValue) holdValue = curOption.minValue;
									else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;

									switch(curOption.type)
									{
										case 'int':
											holdValue = Math.round(holdValue);
											curOption.setValue(holdValue);

										case 'float' | 'percent':
											holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
											curOption.setValue(holdValue);
									}

								case 'string':
									var num:Int = curOption.curOption; //lol
									if (useWheel) num += Std.int(CoolUtil.boundTo(FlxG.mouse.wheel, -1, 1));
									else if (leftP) --num;
									else num++;

									if (num < 0) {
										num = curOption.options.length - 1;
									} else if (num >= curOption.options.length) {
										num = 0;
									}

									curOption.curOption = num;
									curOption.setValue(curOption.options[num]); //lol
									
									if (curOption.name == "Scroll Type")
									{
										var oOption:GameplayOption = getOptionByName("Scroll Speed");
										if (oOption != null)
										{
											if (curOption.getValue() == "constant")
											{
												oOption.description = 'Forces a single scroll speed for every chart.';
												oOption.displayFormat = "%v";
												oOption.maxValue = 6;
											}
											else
											{
												oOption.description = "Multiplies the chart's scroll speed.";
												oOption.displayFormat = "%vX";
												oOption.maxValue = 3;
												if (oOption.getValue() > 3) oOption.setValue(3);
											}
											updateTextFrom(oOption);
										}
									}
							}
							updateTextFrom(curOption);
							curOption.change();
							CoolUtil.playScrollSound();
						} else if (curOption.type != 'string') {
							holdValue += curOption.scrollSpeed * elapsed * ((left) ? -1 : 1);
							if (holdValue < curOption.minValue) holdValue = curOption.minValue;
							else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;

							switch(curOption.type)
							{
								case 'int':
									curOption.setValue(Math.round(holdValue));
								
								case 'float' | 'percent':
									curOption.setValue(FlxMath.roundDecimal(holdValue, curOption.decimals));
							}
							updateTextFrom(curOption);
							curOption.change();
						}
					}

					if (curOption.type != 'string' && !useWheel) {
						holdTime += elapsed;
					}
				} else if (leftR || rightR) {
					clearHold();
				}
			}

			if (reset)
			{
				for (i in 0...optionsArray.length)
				{
					var leOption:GameplayOption = optionsArray[i];
					leOption.setValue(leOption.defaultValue);
					if (leOption.type != 'bool')
					{
						if (leOption.type == 'string')
						{
							leOption.curOption = leOption.options.indexOf(leOption.getValue());
						}
						updateTextFrom(leOption);
					}

					if (leOption.name == 'Scroll Speed')
					{
						leOption.displayFormat = "%vX";
						leOption.maxValue = 3;
						if (leOption.getValue() > 3)
						{
							leOption.setValue(3);
						}
						updateTextFrom(leOption);
					}
					leOption.change();
				}
				CoolUtil.playCancelSound();
				reloadCheckboxes();
			}
		}

		if (nextAccept > 0) {
			nextAccept -= 1;
		}
		super.update(elapsed);
	}

	function updateTextFrom(option:GameplayOption) {
		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();
		if (option.type == 'percent') val *= 100;
		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', val).replace('%d', def);
	}

	function clearHold()
	{
		if (holdTime > 0.5) {
			CoolUtil.playScrollSound();
		}
		holdTime = 0;
	}
	
	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		if (curSelected < 0)
			curSelected = optionsArray.length - 1;
		if (curSelected >= optionsArray.length)
			curSelected = 0;

		descText.text = optionsArray[curSelected].description;
		descText.screenCenter(Y);
		descText.y += 270;

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
			}
		}
		for (text in grpTexts) {
			text.alpha = 0.6;
			if (text.ID == curSelected) {
				text.alpha = 1;
			}
		}

		descBox.setPosition(descText.x - 10, descText.y - 10);
		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();

		curOption = optionsArray[curSelected]; //shorter lol
		CoolUtil.playScrollSound();
	}

	function reloadCheckboxes() {
		for (checkbox in checkboxGroup) {
			checkbox.daValue = (optionsArray[checkbox.ID].getValue() == true);
		}
	}

	override public function destroy() {
		curOption = null;
		optionsArray = null;
		grpOptions = FlxDestroyUtil.destroy(grpOptions);
		checkboxGroup = FlxDestroyUtil.destroy(checkboxGroup);
		grpTexts = FlxDestroyUtil.destroy(grpTexts);
		descBox = FlxDestroyUtil.destroy(descBox);
		descText = FlxDestroyUtil.destroy(descText);
		super.destroy();
	}
}

class GameplayOption
{
	private var child:Alphabet;
	public var text(get, set):String;
	public var onChange:Void->Void = null; //Pressed enter (on Bool type options) or pressed/held left/right (on other types)

	public var type(get, default):String = 'bool'; //bool, int (or integer), float (or fl), percent, string (or str)
	// Bool will use checkboxes
	// Everything else will use a text

	public var showBoyfriend:Bool = false;
	public var scrollSpeed:Float = 50; //Only works on int/float, defines how fast it scrolls per second while holding left/right

	private var variable:String = null; //Variable from ClientPrefs.hx's gameplaySettings
	public var defaultValue:Dynamic = null;

	public var curOption:Int = 0; //Don't change this
	public var options:Array<String> = null; //Only used in string type
	public var changeValue:Dynamic = 1; //Only used in int/float/percent type, how much is changed when you PRESS
	public var minValue:Dynamic = null; //Only used in int/float/percent type
	public var maxValue:Dynamic = null; //Only used in int/float/percent type
	public var decimals:Int = 1; //Only used in float/percent type

	public var displayFormat:String = '%v'; //How String/Float/Percent/Int values are shown, %v = Current value, %d = Default value
	public var description:String = '';
	public var name:String = 'Unknown';

	public function new(name:String, description:String = '', variable:String, type:String = 'bool', defaultValue:Dynamic = 'null variable value', ?options:Array<String> = null)
	{
		this.name = name;
		this.description = description;
		this.variable = variable;
		this.type = type;
		this.defaultValue = defaultValue;
		this.options = options;

		if (defaultValue == 'null variable value')
		{
			switch(type)
			{
				case 'bool':
					defaultValue = false;
				case 'int' | 'float':
					defaultValue = 0;
				case 'percent':
					defaultValue = 1;
				case 'string':
					defaultValue = '';
					if (options.length > 0) {
						defaultValue = options[0];
					}
			}
		}

		if (getValue() == null) {
			setValue(defaultValue);
		}

		switch(type)
		{
			case 'string':
				var num:Int = options.indexOf(getValue());
				if (num > -1) {
					curOption = num;
				}
	
			case 'percent':
				displayFormat = '%v%';
				changeValue = 0.01;
				minValue = 0;
				maxValue = 1;
				scrollSpeed = 0.5;
				decimals = 2;
		}
	}

	public function change()
	{
		//nothing lol
		if (onChange != null) {
			onChange();
		}
	}

	public function getValue():Dynamic
	{
		return ClientPrefs.gameplaySettings.get(variable);
	}
	public function setValue(value:Dynamic)
	{
		ClientPrefs.gameplaySettings.set(variable, value);
	}

	public function setChild(child:Alphabet)
	{
		this.child = child;
	}

	private function get_text()
	{
		if (child != null) {
			return child.text;
		}
		return null;
	}
	private function set_text(newValue:String = '')
	{
		if (child != null) {
			child.changeText(newValue);
		}
		return null;
	}

	private function get_type()
	{
		var newValue:String = 'bool';
		switch(type.toLowerCase().trim())
		{
			case 'int' | 'float' | 'percent' | 'string': newValue = type;
			case 'integer': newValue = 'int';
			case 'str': newValue = 'string';
			case 'fl': newValue = 'float';
		}
		type = newValue;
		return type;
	}
}
