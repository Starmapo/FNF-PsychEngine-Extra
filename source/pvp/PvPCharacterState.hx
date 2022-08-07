package pvp;

import flixel.effects.FlxFlicker;
import pvp.CharacterSelect.AlternateForm;
import haxe.Json;
import pvp.CharacterSelect.CharacterData;
import flixel.FlxSprite;
import flixel.FlxG;

using StringTools;

class PvPCharacterState extends MusicBeatState {
    var charSelect1:CharacterSelect;
    var charSelect2:CharacterSelect;

    public static var lastCharacters:Array<Array<Int>> = [[], []];
    public static var exiting:Bool = false;

    override public function create() {
        super.create();
        persistentUpdate = true;
        exiting = false;

        var bg = new FlxSprite().loadGraphic(Paths.image('menuBGBlue'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
        bg.scrollFactor.set();
		bg.screenCenter();
        add(bg);

        var chars = getCharacters();
        charSelect1 = new CharacterSelect(0, 0, chars, true);
        add(charSelect1);
        charSelect2 = new CharacterSelect(FlxG.width / 2, 0, chars);
        add(charSelect2);
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        #if debug
        if (!exiting && charSelect2.ready && (charSelect1.ready || FlxG.gamepads.lastActive == null))
        #else
        if (!exiting && charSelect2.ready && charSelect1.ready)
        #end
        {
            charSelect1.fadeStuff();
            charSelect2.fadeStuff();
            FlxFlicker.flicker(charSelect1.readyText, 1, 0.06, false, false);
            FlxFlicker.flicker(charSelect2.readyText, 1, 0.06, false, false, function(flick:FlxFlicker) {
                var charSelects = [charSelect1, charSelect2];
                for (charSelect in charSelects) {
                    for (i in 0...charSelect.selectedChars.length) {
                        if (charSelect.selectedChars[i] == '!random')
                            charSelect.selectedChars[i] = charSelect.fullCharList[FlxG.random.int(1, charSelect.fullCharList.length - 1)];
                    }
                    trace(charSelect.selectedChars);
                }

                PvPPlayState.dadMatch = (charSelect1.selectedChars[0] == PlayState.SONG.player2);
                PvPPlayState.boyfriendMatch = (charSelect2.selectedChars[0] == PlayState.SONG.player1);
                PvPPlayState.intendedDadLength = Character.getCharacterGroupLength(PlayState.SONG.player2);
                PvPPlayState.intendedBoyfriendLength = Character.getCharacterGroupLength(PlayState.SONG.player1);

                PlayState.SONG.player2 = charSelect1.selectedChars[0];
                PlayState.SONG.player1 = charSelect2.selectedChars[0];
                PvPPlayState.dadSwitch = charSelect1.selectedChars[1];
                PvPPlayState.boyfriendSwitch = charSelect2.selectedChars[1];
                StageData.loadDirectory(PlayState.SONG);
                LoadingState.loadAndSwitchState(new PvPPlayState(), true);
            });
            exiting = true;
        }
    }

    function getCharacters() {
        var rawJson = Paths.getContent(Paths.json('pvpCharacters')).trim();
        var stuff:Dynamic = Json.parse(rawJson);
        var charDataList:Array<CharacterData> = [];
        charDataList.push({
            name: '!random',
            displayName: 'Random',
            alternateForms: []
        });
        var daList:Array<Array<Dynamic>> = Reflect.getProperty(stuff, "characters");
        for (char in daList) {
            var charData:CharacterData = {
                name: char[0],
                displayName: char[1],
                alternateForms: []
            };
            if (char[2] != null) {
                for (i in 0...char[2].length) {
                    var altData:AlternateForm = {
                        name: char[2][i][0],
                        displayName: char[2][i][1]
                    };
                    charData.alternateForms.push(altData);
                }
            }
            charDataList.push(charData);
        }

        return charDataList;
    }

    static function sortChars(a:CharacterData, b:CharacterData):Int {
		var val1 = a.displayName.toUpperCase();
		var val2 = b.displayName.toUpperCase();
		if (val1 < val2) {
		  return -1;
		} else if (val1 > val2) {
		  return 1;
		} else {
		  return 0;
		}
	}
}