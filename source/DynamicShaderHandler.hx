package;

import flixel.FlxG;
import flixel.graphics.tile.FlxGraphicsShader;
import openfl.utils.Assets;
#if MODS_ALLOWED
import sys.FileSystem;
#end

/*
	Class to handle animated shaders, calling the new consturctor is enough, 
	the update function will be automatically called by the playstate.
	Access the shader the handler with `PlayState.animatedShaders["fileName"]`
	Shaders should be placed at /shaders folder, with ".frag" extension, 
	See shaders folder for examples and guides.
	Optimize variable might help with some heavy shaders but only makes a difference on decent Intel CPUs.
	@author Kemo
	Please respect the effort put to this and credit us if used :]
 */

class DynamicShaderHandler
{
	public var shader:FlxGraphicsShader;

	private var bHasResolution:Bool = false;
	private var bHasTime:Bool = false;

	public function new(fileName:String, optimize:Bool = false)
	{
		#if MODS_ALLOWED
		var path = Paths.modsShaderFragment(fileName);
		if (!FileSystem.exists(path)) path = Paths.shaderFragment(fileName);
		#else
		var path = Paths.shaderFragment(fileName);
		#end

		var fragSource:String = "";

		#if MODS_ALLOWED
		if (Assets.exists(path) || FileSystem.exists(path))
		{
			fragSource = sys.io.File.getContent(path);
		}
		#else
		if (Assets.exists(path))
		{
			fragSource = Assets.getText(path);
		}
		#end

		#if MODS_ALLOWED
		var path2 = Paths.modsShaderVertex(fileName);
		if (!FileSystem.exists(path2)) path2 = Paths.shaderVertex(fileName);
		#else
		var path2 = Paths.shaderVertex(fileName);
		#end

		var vertSource:String = "";

		#if MODS_ALLOWED
		if (Assets.exists(path2) || FileSystem.exists(path2))
		{
			vertSource = sys.io.File.getContent(path2);
		}
		#else
		if (Assets.exists(path2))
		{
			vertSource = Assets.getText(path2);
		}
		#end

		if (fragSource != "" || vertSource != "")
		{
			shader = new FlxGraphicsShader(fragSource, optimize, vertSource);
		}

		if (shader == null)
		{
			return;
		}

		if (fragSource.indexOf("iResolution") != -1)
		{
			bHasResolution = true;
			shader.data.iResolution.value = [FlxG.width, FlxG.height];
		}

		if (fragSource.indexOf("iTime") != -1)
		{
			bHasTime = true;
			shader.data.iTime.value = [0];
		}

		#if LUA_ALLOWED 
		PlayState.instance.luaShaders[fileName] = this;
		#end
		PlayState.animatedShaders[fileName] = this;

	}

	public function modifyShaderProperty(property:String, value:Dynamic)
	{
		if (shader == null)
		{
			return;
		}

		if (shader.data.get(property) != null)
		{
			shader.data.get(property).value = value;
		}
	}

	private function getTime()
	{
		return shader.data.iTime.value[0];
	}

	private function setTime(value)
	{
		shader.data.iTime.value = [value];
	}

	public function update(elapsed:Float)
	{
		if (bHasTime)
		{
			setTime(getTime() + elapsed);
		}
	}
}