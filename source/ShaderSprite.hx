package;

import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;

using StringTools;

class ShaderSprite extends FlxSprite
{
	var hShader:DynamicShaderHandler;

	public function new(type:String, optimize:Bool = false, ?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);

		// codism
		flipY = true;

		makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT);

		hShader = new DynamicShaderHandler(type, optimize);

		if (hShader.shader != null)
		{
			shader = hShader.shader;
		}

		antialiasing = ClientPrefs.globalAntialiasing;
	}
}