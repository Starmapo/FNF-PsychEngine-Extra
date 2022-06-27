import flixel.ui.FlxButton;
import UIData.ManiaArray;
import flixel.FlxG;
import flixel.FlxSprite;

/*

    FOR MOBILE

*/

class NoteButton extends FlxButton {
    public function new(x:Float = 0, y:Float = 0, noteData:Int = 0, maniaData:ManiaArray) {
        super(x, y);
        var tex = 'noteButtons';
        frames = Paths.getSparrowAtlas(tex);
        animation.addByPrefix('idle', maniaData.colors[noteData], 0, false);
        animation.play('idle');
        antialiasing = ClientPrefs.globalAntialiasing;
        setGraphicSize(Std.int(FlxG.width / maniaData.keys), Std.int(FlxG.height * (3/4)));
        updateHitbox();
        alpha = 0.5;
        label = null;
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if (pressed) {
            alpha = 0.25;
        } else {
            alpha = 0.5;
        }
    }

    override function updateStatusAnimation() {}
}