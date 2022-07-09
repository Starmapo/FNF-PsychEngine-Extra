package pvp;

import pvp.CharacterSelect.AlternateForm;
import haxe.Json;
import pvp.CharacterSelect.CharacterData;
import flixel.FlxSprite;
import flixel.FlxG;

using StringTools;

class PvPCharacterState extends MusicBeatState {
    var charSelect1:CharacterSelect;
    var charSelect2:CharacterSelect;

    override public function create() {
        super.create();

        var bg = new FlxSprite().loadGraphic(Paths.image('menuBGBlue'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
        bg.scrollFactor.set();
		bg.screenCenter();
        add(bg);

        if (PvPPlayState.SONG == null)
            PvPPlayState.SONG = Song.loadFromJson('ugh', 'ugh');

        var chars = getCharacters();
        charSelect2 = new CharacterSelect(0, 0, chars);
        add(charSelect2);
        charSelect1 = new CharacterSelect(FlxG.width / 2, 0, chars, true);
        //add(charSelect1);
    }

   function getCharacters() {
        var tempMap:Map<String, Bool> = new Map();
        var rawJson = Paths.getContent(Paths.json('pvpCharacters')).trim();
        var stuff:Dynamic = Json.parse(rawJson);
        var charDataList:Array<CharacterData> = [];
        var daList:Array<Array<Dynamic>> = Reflect.getProperty(stuff, "characters");
        for (char in daList) {
            if (!tempMap.exists(char[0])) {
                var charData:CharacterData = {
                    name: char[0],
                    displayName: char[1],
                    alternateForms: []
                };
                for (i in 0...char[2].length) {
                    var altData:AlternateForm = {
                        name: char[2][i][0],
                        displayName: char[2][i][1]
                    };
                    charData.alternateForms.push(altData);
                }
                tempMap.set(char[0], true);
                charDataList.push(charData);
                trace('pushed character: $charData');
            }
        }

        charDataList.sort(sortChars);
        return charDataList;
    }

    static function sortChars(a:CharacterData, b:CharacterData):Int {
		var val1 = a.name.toUpperCase();
		var val2 = b.name.toUpperCase();
		if (val1 < val2) {
		  return -1;
		} else if (val1 > val2) {
		  return 1;
		} else {
		  return 0;
		}
	}
}