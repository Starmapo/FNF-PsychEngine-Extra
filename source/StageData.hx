package;

#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#else
import openfl.utils.Assets;
#end
import haxe.Json;
import Song;

using StringTools;

typedef StageFile = {
	var directory:String;
	var defaultZoom:Float;

	var boyfriend:Array<Dynamic>;
	var girlfriend:Array<Dynamic>;
	var opponent:Array<Dynamic>;

	var boyfriendCamOffset:Array<Float>;
	var opponentCamOffset:Array<Float>;
}

class StageData {
	public static var forceNextDirectory:String = null;
	public static function loadDirectory(SONG:SwagSong) {
		var stage:String = '';
		if (SONG.stage != null) {
			stage = SONG.stage;
		} else if (SONG.song != null) {
			switch (Paths.formatToSongPath(SONG.song))
			{
				case 'spookeez' | 'south' | 'monster':
					stage = 'spooky';
				case 'pico' | 'blammed' | 'philly' | 'philly-nice':
					stage = 'philly';
				case 'milf' | 'satin-panties' | 'high':
					stage = 'limo';
				case 'cocoa' | 'eggnog':
					stage = 'mall';
				case 'winter-horrorland':
					stage = 'mallEvil';
				case 'senpai' | 'roses':
					stage = 'school';
				case 'thorns':
					stage = 'schoolEvil';
				default:
					stage = 'stage';
			}
		} else {
			stage = 'stage';
		}

		var stageFile:StageFile = getStageFile(stage);
		if (stageFile == null) { //preventing crashes
			forceNextDirectory = '';
		} else {
			forceNextDirectory = stageFile.directory;
		}
	}

	public static function getStageFile(stage:String):StageFile {
		var rawJson:String = null;
		var path:String = Paths.getPreloadPath('stages/$stage.json');

		#if MODS_ALLOWED
		var modPath:String = Paths.modFolders('stages/$stage.json');
		if (FileSystem.exists(modPath)) {
			rawJson = File.getContent(modPath);
		} else if (FileSystem.exists(path)) {
			rawJson = File.getContent(path);
		}
		#else
		if (Assets.exists(path)) {
			rawJson = Assets.getText(path);
		}
		#end
		else
		{
			return null;
		}

		var stageFile:StageFile = cast Json.parse(rawJson);
		if (stageFile.boyfriendCamOffset == null || stageFile.boyfriendCamOffset.length < 2) {
			stageFile.boyfriendCamOffset = [-100, -100];
		}
		if (stageFile.opponentCamOffset == null || stageFile.opponentCamOffset.length < 2) {
			stageFile.opponentCamOffset = [150, -100];
		}
		return stageFile;
	}
}