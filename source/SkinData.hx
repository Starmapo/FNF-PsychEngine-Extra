class SkinData {
    public static function getNoteFile(file:String, folder:String, ?skin:String) {
        if (skin == null) skin = ClientPrefs.noteSkin;
        skin = Paths.formatToSongPath(skin);
        var path = 'noteskins/$skin/$folder/$file';
        //trace(path);
        if (!Paths.existsPath('images/$path.png', IMAGE)) {
            path = 'noteskins/default/$folder/$file';
            //trace(path);
        }
        if (!Paths.existsPath('images/$path.png', IMAGE)) {
            path = 'noteskins/default/base/$file';
            //trace(path);
        }
        if (!Paths.existsPath('images/$path.png', IMAGE)) {
            path = (folder == 'pixel' && Paths.existsPath('images/pixelUI/$file.png', IMAGE) ? 'pixelUI' : '') + file;
            //trace(path);
        }
        return path;
    }

    public static function getUIFile(file:String, folder:String, ?skin:String) {
        if (skin == null) skin = ClientPrefs.uiSkin;
        skin = Paths.formatToSongPath(skin);
        var path = 'uiskins/$skin/$folder/$file';
        //trace(path);
        if (!Paths.existsPath('images/$path.png', IMAGE)) {
            path = 'uiskins/default/$folder/$file';
            //trace(path);
        }
        if (!Paths.existsPath('images/$path.png', IMAGE)) {
            path = 'uiskins/default/base/$file';
            //trace(path);
        }
        if (!Paths.existsPath('images/$path.png', IMAGE)) {
            path = (folder == 'pixel' && Paths.existsPath('images/pixelUI/$file.png', IMAGE) ? 'pixelUI' : '') + file;
            //trace(path);
        }
        return path;
    }
}