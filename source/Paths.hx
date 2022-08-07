package;

import flash.media.Sound;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import haxe.io.Path;
import lime.app.Promise;
import lime.app.Future;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import lime.utils.Assets;
import openfl.system.System;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
#if sys
import haxe.Json;
import openfl.display.BitmapData;
#end
#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	public static final VIDEO_EXT = ['mp4', 'webm', 'mov', 'wmv', 'avi', 'flv'];

	public static var ignoreLibraries:Array<String> = [
		'default',
		'shared',
		'songs',
		'videos'
	];

	public static function excludeAsset(key:String) {
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> =
	[
		'assets/images/alphabet.png',
		'assets/sounds/scrollMenu.$SOUND_EXT',
		'assets/sounds/confirmMenu.$SOUND_EXT',
		'assets/sounds/cancelMenu.$SOUND_EXT',
		'assets/music/freakyMenu.$SOUND_EXT',
		'shared:assets/shared/music/breakfast.$SOUND_EXT',
		'shared:assets/shared/music/tea-time.$SOUND_EXT'
	];
	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory() {
		// clear non local assets in the tracked assets list
		for (key in currentTrackedAssets.keys()) {
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key) 
				&& !dumpExclusions.contains(key)) {
				// get rid of it
				var obj = currentTrackedAssets.get(key);
				@:privateAccess
				if (obj != null) {
					OpenFlAssets.cache.removeBitmapData(key);
					FlxG.bitmap._cache.remove(key);
					obj.destroy();
					currentTrackedAssets.remove(key);
				}
			}
		}
		// run the garbage collector for good measure lmfao
		System.gc();
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];
	public static function clearStoredMemory() {
		// clear anything not in the tracked assets list
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null && !currentTrackedAssets.exists(key)) {
				OpenFlAssets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}

		// clear all sounds that are cached
		for (key in currentTrackedSounds.keys()) {
			if (key != null && !localTrackedAssets.contains(key) 
			&& !dumpExclusions.contains(key)) {
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}	
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		OpenFlAssets.cache.clear("songs");
	}

	static public function loadLibraryManifest(id:String):Future<AssetLibrary> {
		var promise = new Promise<AssetLibrary>();

		var library = Assets.getLibrary(id);

		if (library != null)
		{
			return Future.withValue(library);
		}

		var path = id;
		var rootPath = null;

		@:privateAccess
		var libraryPaths = Assets.libraryPaths;
		if (libraryPaths.exists(id))
		{
			path = libraryPaths[id];
			rootPath = Path.directory(path);
		}
		else
		{
			if (StringTools.endsWith(path, ".bundle"))
			{
				rootPath = path;
				path += "/library.json";
			}
			else
			{
				rootPath = Path.directory(path);
			}
			@:privateAccess
			path = Assets.__cacheBreak(path);
		}

		AssetManifest.loadFromFile(path, rootPath).onComplete(function(manifest)
		{
			if (manifest == null)
			{
				promise.error('Cannot parse asset manifest for library "$id"');
				return;
			}

			var library = AssetLibrary.fromManifest(manifest);

			if (library == null)
			{
				promise.error('Cannot open library "$id"');
			}
			else
			{
				@:privateAccess
				Assets.libraries.set(id, library);
				library.onChange.add(Assets.onChange.dispatch);
				promise.completeWith(Future.withValue(library));
			}
		}).onError(function(_)
		{
			promise.error('There is no asset library with an ID of "$id"');
		});

		return promise.future;
	}

	static public function getLibraries(ignore:Bool = false):Array<String> {
		var libraries:Array<String> = [];
		@:privateAccess
		for (i in Assets.libraryPaths.keys()) {
			if (!ignore || !ignoreLibraries.contains(i))
				libraries.push(i);
		}
		return libraries;
	}

	static public var currentLevel:String;
	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	public static function getPath(file:String, type:AssetType = null, library:String = null)
	{
		#if MODS_ALLOWED
		var modPath = mods((library != null ? '$library/' : '') + '$file');
		if (FileSystem.exists(modPath)) {
			return modPath;
		}
		modPath = mods(file);
		if (FileSystem.exists(modPath)) {
			return modPath;
		}
		#end

		if (library != null && exists(getLibraryPath(file, library)))
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if (currentLevel != 'shared') {
				levelPath = getLibraryPathForce(file, currentLevel);
				if (exists(levelPath, type))
					return levelPath;
			}

			levelPath = getLibraryPathForce(file, "shared");
			if (exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		var returnPath = '$library:assets/$library/$file';
		return returnPath;
	}

	inline public static function getPreloadPath(file:String = '')
	{
		return 'assets/$file';
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('images/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	static public function video(key:String)
	{
		for (i in VIDEO_EXT) {
			var path = 'assets/videos/$key.$i';
			if (exists(path))
			{
				return path;
			}
		}
		return 'assets/videos/$key.mp4';
	}

	static public function sound(key:String, ?library:String):Sound
	{
		var sound:Sound = returnSound('sounds', key, library);
		return sound;
	}
	
	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String):Sound
	{
		var file:Sound = returnSound('music', key, library);
		return file;
	}

	inline static public function inst(song:String, ?suffix:String = ''):Sound
	{
		var songKey:String = '${formatToSongPath(song)}';
		var inst = returnSound(songKey, 'Inst', 'songs');
		if (suffix.length > 0 && existsPath('$songKey/Inst$suffix.$SOUND_EXT', SOUND, 'songs'))
			inst = returnSound(songKey, 'Inst$suffix', 'songs');
		return inst;
	}

	inline static public function voices(song:String, ?suffix:String = ''):Sound
	{
		var songKey:String = '${formatToSongPath(song)}';
		var voices = returnSound(songKey, 'Voices', 'songs');
		if (suffix.length > 0 && existsPath('$songKey/Voices$suffix.$SOUND_EXT', SOUND, 'songs'))
			voices = returnSound(songKey, 'Voices$suffix', 'songs');
		return voices;
	}

	static public function voicesDad(song:String, ?suffix:String = ''):Sound
	{
		var songKey:String = '${formatToSongPath(song)}';
		var suffixes = ['Dad', 'Opponent'];
		for (dadSuffix in suffixes) {
			var voices = returnSound(songKey, 'Voices$dadSuffix', 'songs');
			if (suffix.length > 0 && existsPath('$songKey/Voices$dadSuffix$suffix.$SOUND_EXT', SOUND, 'songs'))
				voices = returnSound(songKey, 'Voices$dadSuffix$suffix', 'songs');
			if (voices != null)
				return voices;
		}
		return null;
	}

	inline static public function image(key:String, ?library:String):FlxGraphic
	{
		// streamlined the assets process more
		var returnAsset:FlxGraphic = returnGraphic(key, library);
		return returnAsset;
	}
	
	static public function getTextFromFile(key:String):String
	{
		if (exists(getPath(key)))
			return getContent(getPath(key));

		return null;
	}

	inline static public function font(key:String)
	{
		return 'assets/fonts/$key';
	}

	inline static public function exists(key:String, type:AssetType = null, ?library:String)
	{
		#if sys
		if (FileSystem.exists(key)) {
			return true;
		}
		#end
		
		if (OpenFlAssets.exists(key, type)) {
			return true;
		}
		return false;
	}

	inline static public function existsPath(key:String, type:AssetType = null, ?library:String)
	{
		#if sys
		if (FileSystem.exists(getPath(key, type, library))) {
			return true;
		}
		#end
		
		if (OpenFlAssets.exists(getPath(key, type, library), type)) {
			return true;
		}
		return false;
	}

	inline static public function getSparrowAtlas(key:String, ?library:String)
	{
		var imageLoaded:FlxGraphic = returnGraphic(key);
		return FlxAtlasFrames.fromSparrow((imageLoaded != null ? imageLoaded : image(key, library)), getContent(file('images/$key.xml', TEXT, library)));
	}


	inline static public function getPackerAtlas(key:String, ?library:String)
	{
		var imageLoaded:FlxGraphic = returnGraphic(key);
		return FlxAtlasFrames.fromSpriteSheetPacker((imageLoaded != null ? imageLoaded : image(key, library)), getContent(file('images/$key.txt', TEXT, library)));
	}

	inline static public function getTexturePackerAtlas(key:String, ?library:String)
	{
		var imageLoaded:FlxGraphic = returnGraphic(key);
		return FlxAtlasFrames.fromTexturePackerJson((imageLoaded != null ? imageLoaded : image(key, library)), getContent(file('images/$key.json', TEXT, library)));
	}

	inline static public function formatToSongPath(path:String) {
		return path.toLowerCase().replace(' ', '-');
	}

	// completely rewritten asset loading? fuck!
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static function returnGraphic(key:String, ?library:String) {
		var path = getPath('images/$key.png', IMAGE, library);
		#if sys
		if(FileSystem.exists(path)) {
			if(!currentTrackedAssets.exists(path)) {
				var newBitmap:BitmapData = BitmapData.fromFile(path);
				var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(newBitmap, false, path);
				newGraphic.persist = true;
				currentTrackedAssets.set(path, newGraphic);
			}
			if (!localTrackedAssets.contains(path)) localTrackedAssets.push(path);
			return currentTrackedAssets.get(path);
		}
		#end
		if (OpenFlAssets.exists(path, IMAGE)) {
			if(!currentTrackedAssets.exists(path)) {
				var newGraphic:FlxGraphic = FlxG.bitmap.add(path, false, path);
				newGraphic.persist = true;
				currentTrackedAssets.set(path, newGraphic);
			}
			if (!localTrackedAssets.contains(path)) localTrackedAssets.push(path);
			return currentTrackedAssets.get(path);
		}
		trace('oh no its returning null NOOOO: $path');
		return null;
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];
	public static function returnSound(path:String, key:String, ?library:String) {
		var gottenPath:String = getPath('$path/$key.$SOUND_EXT', SOUND, library);
		if (!existsPath('$path/$key.$SOUND_EXT', SOUND, library)) {
			trace('oh no its returning null NOOOO: $gottenPath');
			return null;
		}
		if (!currentTrackedSounds.exists(gottenPath))
			#if sys
			currentTrackedSounds.set(gottenPath, Sound.fromFile('./' + gottenPath.substring(gottenPath.indexOf(':') + 1)));
			#else
			currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(gottenPath));
			#end
		if (!localTrackedAssets.contains(gottenPath)) localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}

	inline public static function getContent(path:String) {
		#if sys
		if (path.contains(':'))
			path = path.substring(path.indexOf(':') + 1);
		if (FileSystem.exists(path))
			return File.getContent(path);
		return null;
		#else
		return OpenFlAssets.getText(path);
		#end
	}

	#if MODS_ALLOWED
	inline static public function mods(key:String = '') {
		return 'mods/' + key;
	}
	#end
}
