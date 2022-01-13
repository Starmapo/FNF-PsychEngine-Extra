package editors;

import Section.SwagSection;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;

using StringTools;

class EditorPlayState extends MusicBeatState
{
	// Yes, this is mostly a copy of PlayState, it's kinda dumb to make a direct copy of it but... ehhh
	private var strumLine:FlxSprite;
	private var comboGroup:FlxTypedGroup<FlxSprite>;
	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];

	var generatedMusic:Bool = false;
	var vocals:FlxSound;

	var startOffset:Float = 0;
	var startPos:Float = 0;

	var bfKeys:Int = 4;
	var dadKeys:Int = 4;

	public function new(startPos:Float) {
		this.startPos = startPos;
		Conductor.songPosition = startPos - startOffset;

		startOffset = Conductor.crochet;
		timerToStart = startOffset;
		super();
	}

	var scoreTxt:FlxText;
	var stepTxt:FlxText;
	var beatTxt:FlxText;
	
	var timerToStart:Float = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	
	// Less laggy controls
	private var keysArray:Array<Dynamic>;

	public static var instance:EditorPlayState;

	override function create()
	{
		instance = this;

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = FlxColor.fromHSB(FlxG.random.int(0, 359), FlxG.random.float(0, 0.8), FlxG.random.float(0.3, 1));
		add(bg);

		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];

		bfKeys = PlayState.SONG.keyAmount;
		dadKeys = PlayState.SONG.keyAmount;
		switch (bfKeys) {
			case 1:
				keysArray = [
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note1'))
				];
			case 2:
				keysArray = [
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note3_left')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note3_right'))
				];
			case 3:
				keysArray = [
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note3_left')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note3_center')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note3_right'))
				];
			case 5:
				keysArray = [
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_center')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
				];
			case 6:
				keysArray = [
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note7_left')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note7_up')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note7_right')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note7_left2')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note7_down')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note7_right2'))
				];
			case 7:
				keysArray = [
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note7_left')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note7_up')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note7_right')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note7_center')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note7_left2')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note7_down')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note7_right2'))
				];
			case 8:
				keysArray = [
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note9_left')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note9_down')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note9_up')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note9_right')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note9_left2')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note9_down2')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note9_up2')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note9_right2'))
				];
			case 9:
				keysArray = [
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note9_left')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note9_down')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note9_up')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note9_right')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note9_center')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note9_left2')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note9_down2')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note9_up2')),
					ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note9_right2'))
				];
		}
		
		strumLine = new FlxSprite(ClientPrefs.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if(ClientPrefs.downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();
		
		comboGroup = new FlxTypedGroup<FlxSprite>();
		add(comboGroup);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);

		generateStaticArrows(0);
		generateStaticArrows(1);
		/*if(ClientPrefs.middleScroll) {
			opponentStrums.forEachAlive(function (note:StrumNote) {
				note.visible = false;
			});
		}*/
		
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		add(grpNoteSplashes);

		var splash:NoteSplash = new NoteSplash(100, 100, null);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;
		
		if (PlayState.SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();

		generateSong(PlayState.SONG.song);
		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys()) {
			var luaToLoad:String = Paths.modFolders('custom_notetypes/' + notetype + '.lua');
			if(sys.FileSystem.exists(luaToLoad)) {
				var lua:editors.EditorLua = new editors.EditorLua(luaToLoad);
				new FlxTimer().start(0.1, function (tmr:FlxTimer) {
					lua.stop();
					lua = null;
				});
			}
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;

		scoreTxt = new FlxText(0, FlxG.height - 50, FlxG.width, "Hits: 0 | Misses: 0", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.hideHud;
		add(scoreTxt);
		
		beatTxt = new FlxText(10, 610, FlxG.width, "Beat: 0", 20);
		beatTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		beatTxt.scrollFactor.set();
		beatTxt.borderSize = 1.25;
		add(beatTxt);

		stepTxt = new FlxText(10, 640, FlxG.width, "Step: 0", 20);
		stepTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		stepTxt.scrollFactor.set();
		stepTxt.borderSize = 1.25;
		add(stepTxt);

		var tipText:FlxText = new FlxText(10, FlxG.height - 24, 0, 'Press ESC to Go Back to Chart Editor', 16);
		tipText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tipText.borderSize = 2;
		tipText.scrollFactor.set();
		add(tipText);
		FlxG.mouse.visible = false;

		//sayGo();
		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		super.create();
	}

	function sayGo() {
		var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image('uiskins/default/go'));
		go.scrollFactor.set();

		go.updateHitbox();

		go.screenCenter();
		go.antialiasing = ClientPrefs.globalAntialiasing;
		add(go);
		FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				go.destroy();
			}
		});
		FlxG.sound.play(Paths.sound('introGo'), 0.6);
	}

	//var songScore:Int = 0;
	var songHits:Int = 0;
	var songMisses:Int = 0;
	var startingSong:Bool = true;
	private function generateSong(dataPath:String):Void
	{
		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0, false);
		FlxG.sound.music.pause();
		FlxG.sound.music.onComplete = endSong;
		vocals.pause();
		vocals.volume = 0;

		var songData = PlayState.SONG;
		Conductor.numerator = songData.numerator;
		Conductor.denominator = songData.denominator;
		Conductor.mapBPMChanges(songData);
		if (songData.notes[Math.floor(curStep / (Conductor.numerator * 4))].changeBPM && songData.notes[Math.floor(curStep / (Conductor.numerator * 4))].bpm > 0)
		{
			Conductor.changeBPM(songData.notes[Math.floor(curStep / (Conductor.numerator * 4))].bpm);
		}
		else
		{
			var daBPM:Float = songData.bpm;
			for (i in 0...Math.floor(curStep / (Conductor.numerator * 4)))
				if (songData.notes[i].changeBPM)
					daBPM = songData.notes[i].bpm;
			Conductor.changeBPM(daBPM);
		}
		
		notes = new FlxTypedGroup<Note>();
		add(notes);
		
		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				if(songNotes[1] > -1) { //Real notes
					var daStrumTime:Float = songNotes[0];
					if(daStrumTime >= startPos) {
						var daNoteData:Int = Std.int(songNotes[1] % PlayState.SONG.keyAmount);

						var gottaHitNote:Bool = section.mustHitSection;

						if (songNotes[1] >= PlayState.SONG.keyAmount)
						{
							gottaHitNote = !section.mustHitSection;
						}

						var oldNote:Note;
						if (unspawnNotes.length > 0)
							oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						else
							oldNote = null;

						var keys:Int = bfKeys;
						if (!gottaHitNote) keys = dadKeys;

						var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, false, keys);
						swagNote.mustPress = gottaHitNote;
						swagNote.sustainLength = songNotes[2];
						swagNote.noteType = songNotes[3];
						swagNote.scrollFactor.set();

						var susLength:Float = swagNote.sustainLength;

						susLength = susLength / Conductor.stepCrochet;
						unspawnNotes.push(swagNote);

						var floorSus:Int = Math.floor(susLength);
						if(floorSus > 0) {
							for (susNote in 0...floorSus+1)
							{
								oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

								var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(PlayState.SONG.speed, 2)), daNoteData, oldNote, true, false, keys);
								sustainNote.mustPress = gottaHitNote;
								sustainNote.noteType = swagNote.noteType;
								sustainNote.scrollFactor.set();
								unspawnNotes.push(sustainNote);

								if (sustainNote.mustPress)
								{
									sustainNote.x += FlxG.width / 2; // general offset
								}
								else if(ClientPrefs.middleScroll)
								{
									sustainNote.x += 310;
									if(daNoteData >= Math.floor(dadKeys/2))
									{ //Up and Right
										sustainNote.x += FlxG.width / 2 + 25;
									}
								}
							}
						}

						if (swagNote.mustPress)
						{
							swagNote.x += FlxG.width / 2; // general offset
						}
						else if(ClientPrefs.middleScroll)
						{
							swagNote.x += 310;
							if(daNoteData >= Math.floor(dadKeys/2)) //Up and Right
							{
								swagNote.x += FlxG.width / 2 + 25;
							}
						}
						
						if(!noteTypeMap.exists(swagNote.noteType)) {
							noteTypeMap.set(swagNote.noteType, true);
						}
					}
				}
			}
			daBeats += 1;
		}

		unspawnNotes.sort(sortByShit);
		generatedMusic = true;
	}

	function startSong():Void
	{
		startingSong = false;
		FlxG.sound.music.time = startPos;
		FlxG.sound.music.play();
		FlxG.sound.music.volume = ClientPrefs.instVolume;
		vocals.volume = ClientPrefs.voicesVolume;
		vocals.time = startPos;
		vocals.play();
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	private function endSong() {
		LoadingState.loadAndSwitchState(new editors.ChartingState());
	}

	override function update(elapsed:Float) {
		if (FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.sound.music.pause();
			vocals.pause();
			LoadingState.loadAndSwitchState(new editors.ChartingState());
		}

		if (startingSong) {
			timerToStart -= elapsed * 1000;
			Conductor.songPosition = startPos - timerToStart;
			if(timerToStart < 0) {
				startSong();
			}
		} else {
			Conductor.songPosition += elapsed * 1000;
		}

		var roundedSpeed:Float = FlxMath.roundDecimal(PlayState.SONG.speed, 2);
		if (unspawnNotes[0] != null)
		{
			var time:Float = 1500;
			if(roundedSpeed < 1) time /= roundedSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}
		
		if (generatedMusic)
		{
			var fakeCrochet:Float = (60 / Conductor.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				/*if (daNote.y > FlxG.height)
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}*/

				// i am so fucking sorry for this if condition
				var strumX:Float = 0;
				var strumY:Float = 0;
				if(daNote.mustPress) {
					strumX = playerStrums.members[daNote.noteData].x;
					strumY = playerStrums.members[daNote.noteData].y;
				} else {
					strumX = opponentStrums.members[daNote.noteData].x;
					strumY = opponentStrums.members[daNote.noteData].y;
				}

				strumX += daNote.offsetX;
				strumY += daNote.offsetY;
				var center:Float = strumY + daNote.swagWidth / 2;

				if(daNote.copyX) {
					daNote.x = strumX;
				}
				if(daNote.copyY) {
					if (ClientPrefs.downScroll) {
						daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);
						if (daNote.isSustainNote) {
							//Jesus fuck this took me so much mother fucking time AAAAAAAAAA
							if (daNote.animation.curAnim.name.endsWith('end')) {
								daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * roundedSpeed + (46 * (roundedSpeed - 1));
								daNote.y -= 46 * (1 - (fakeCrochet / 600)) * roundedSpeed;
								if(PlayState.isPixelStage) {
									daNote.y += 8;
								} else {
									daNote.y -= 19;
								}
							} 
							daNote.y += (daNote.swagWidth / 2) - (60.5 * (roundedSpeed - 1));
							daNote.y += 27.5 * ((Conductor.bpm / 100) - 1) * (roundedSpeed - 1);

							if(daNote.mustPress || !daNote.ignoreNote)
							{
								if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center
									&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
								{
									var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
									swagRect.height = (center - daNote.y) / daNote.scale.y;
									swagRect.y = daNote.frameHeight - swagRect.height;

									daNote.clipRect = swagRect;
								}
							}
						}
					} else {
						daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);

						if(daNote.mustPress || !daNote.ignoreNote)
						{
							if (daNote.isSustainNote
								&& daNote.y + daNote.offset.y * daNote.scale.y <= center
								&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
							{
								var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
								swagRect.y = (center - daNote.y) / daNote.scale.y;
								swagRect.height -= swagRect.y;

								daNote.clipRect = swagRect;
							}
						}
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
				{
					if (PlayState.SONG.needsVoices)
						vocals.volume = ClientPrefs.voicesVolume;

					var time:Float = 0.15;
					if(daNote.isSustainNote && !daNote.animation.curAnim.name.endsWith('end')) {
						time += 0.15;
					}
					StrumPlayAnim(true, daNote.noteData, time);
					daNote.hitByOpponent = true;

					if (!daNote.isSustainNote)
					{
						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				}

				var doKill:Bool = daNote.y < -daNote.height;
				if(ClientPrefs.downScroll) doKill = daNote.y > FlxG.height;

				if (doKill)
				{
					if (daNote.mustPress)
					{
						if (daNote.tooLate || !daNote.wasGoodHit)
						{
							//Dupe note remove
							notes.forEachAlive(function(note:Note) {
								if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 10) {
									note.kill();
									notes.remove(note, true);
									note.destroy();
								}
							});

							if(!daNote.ignoreNote) {
								songMisses++;
								vocals.volume = 0;
							}
						}
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}

		keyShit();
		scoreTxt.text = 'Hits: ' + songHits + ' | Misses: ' + songMisses;
		beatTxt.text = 'Beat: ' + curBeat;
		stepTxt.text = 'Step: ' + curStep;
		super.update(elapsed);
	}
	
	override public function onFocus():Void
	{
		vocals.play();

		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		vocals.pause();

		super.onFocusLost();
	}

	override function beatHit()
	{
		super.beatHit();

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		if (PlayState.SONG.notes[Math.floor(curStep / (Conductor.numerator * 4))] != null && PlayState.SONG.notes[Math.floor(curStep / (Conductor.numerator * 4))].changeBPM)
		{
			Conductor.changeBPM(PlayState.SONG.notes[Math.floor(curStep / (Conductor.numerator * 4))].bpm);
		}
	}

	override function stepHit()
	{
		super.stepHit();
		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
		{
			resyncVocals();
		}
	}

	function resyncVocals():Void
	{
		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}
	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//trace('Pressed: ' + eventKey);

		if (key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{
			if(generatedMusic)
			{
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				//var notesDatas:Array<Int> = [];
				var notesStopped:Bool = false;

				trace('test!');
				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
					{
						if(daNote.noteData == key && !daNote.isSustainNote)
						{
							trace('pushed note!');
							sortedNotesList.push(daNote);
							//notesDatas.push(daNote.noteData);
						}
						canMiss = true;
					}
				});
				sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

				if (sortedNotesList.length > 0) {
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes) {
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							} else
								notesStopped = true;
						}
							
						// eee jack detection before was not super good
						if (!notesStopped) {
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}

					}
				}
				else if (canMiss && !ClientPrefs.ghostTapping) {
					noteMiss(key);
				}

				//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if(spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
		}
	}
		
	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if(key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];
			if(spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
		}
		//trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if(key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	private function keyShit():Void
	{
		// HOLDING
		var a1 = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note1'));
		var oneHold = [
			FlxG.keys.anyPressed(a1)
		];

		var a1 = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note3_left'));
		var a2 = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note3_center'));
		var a3 = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note3_right'));
		var twoHold = [
			FlxG.keys.anyPressed(a1),
			FlxG.keys.anyPressed(a3)
		];
		var threeHold = [
			FlxG.keys.anyPressed(a1),
			FlxG.keys.anyPressed(a2),
			FlxG.keys.anyPressed(a3)
		];

		var a1 = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left'));
		var a2 = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down'));
		var a3 = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_center'));
		var a4 = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up'));
		var a5 = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'));
		var fourHold = [
			FlxG.keys.anyPressed(a1),
			FlxG.keys.anyPressed(a2),
			FlxG.keys.anyPressed(a4),
			FlxG.keys.anyPressed(a5)
		];
		var fiveHold = [
			FlxG.keys.anyPressed(a1),
			FlxG.keys.anyPressed(a2),
			FlxG.keys.anyPressed(a3),
			FlxG.keys.anyPressed(a4),
			FlxG.keys.anyPressed(a5)
		];

		var a1 = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note7_left'));
		var a2 = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note7_up'));
		var a3 = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note7_right'));
		var a4 = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note7_center'));
		var a5 = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note7_left2'));
		var a6 = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note7_down'));
		var a7 = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note7_right2'));
		var sixHold = [
			FlxG.keys.anyPressed(a1),
			FlxG.keys.anyPressed(a2),
			FlxG.keys.anyPressed(a3),
			FlxG.keys.anyPressed(a5),
			FlxG.keys.anyPressed(a6),
			FlxG.keys.anyPressed(a7)
		];
		var sevenHold = [
			FlxG.keys.anyPressed(a1),
			FlxG.keys.anyPressed(a2),
			FlxG.keys.anyPressed(a3),
			FlxG.keys.anyPressed(a4),
			FlxG.keys.anyPressed(a5),
			FlxG.keys.anyPressed(a6),
			FlxG.keys.anyPressed(a7)
		];

		var a1 = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note9_left'));
		var a2 = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note9_down'));
		var a3 = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note9_up'));
		var a4 = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note9_right'));
		var a5 = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note9_center'));
		var a6 = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note9_left2'));
		var a7 = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note9_down2'));
		var a8 = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note9_up2'));
		var a9 = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note9_right2'));
		var eightHold = [
			FlxG.keys.anyPressed(a1),
			FlxG.keys.anyPressed(a2),
			FlxG.keys.anyPressed(a3),
			FlxG.keys.anyPressed(a4),
			FlxG.keys.anyPressed(a6),
			FlxG.keys.anyPressed(a7),
			FlxG.keys.anyPressed(a8),
			FlxG.keys.anyPressed(a9)
		];
		var nineHold = [
			FlxG.keys.anyPressed(a1),
			FlxG.keys.anyPressed(a2),
			FlxG.keys.anyPressed(a3),
			FlxG.keys.anyPressed(a4),
			FlxG.keys.anyPressed(a5),
			FlxG.keys.anyPressed(a6),
			FlxG.keys.anyPressed(a7),
			FlxG.keys.anyPressed(a8),
			FlxG.keys.anyPressed(a9)
		];

		var controlHoldArray:Array<Bool> = fourHold;
		switch (bfKeys) {
			case 1:
				controlHoldArray = oneHold;
			case 2:
				controlHoldArray = twoHold;
			case 3:
				controlHoldArray = threeHold;
			case 5:
				controlHoldArray = fiveHold;
			case 6:
				controlHoldArray = sixHold;
			case 7:
				controlHoldArray = sevenHold;
			case 8:
				controlHoldArray = eightHold;
			case 9:
				controlHoldArray = nineHold;
		}
		
		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode && bfKeys == 4)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_P, controls.NOTE_DOWN_P, controls.NOTE_UP_P, controls.NOTE_RIGHT_P];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		// FlxG.watch.addQuick('asdfa', upP);
		if (generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit 
				&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit) {
					goodNoteHit(daNote);
				}
			});
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode && bfKeys == 4)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_R, controls.NOTE_DOWN_R, controls.NOTE_UP_R, controls.NOTE_RIGHT_R];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	var combo:Int = 0;
	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			switch(note.noteType) {
				case 'Hurt Note': //Hurt note
					noteMiss(note.noteData);
					--songMisses;
					if(!note.isSustainNote) {
						if(!note.noteSplashDisabled) {
							spawnNoteSplashOnNote(note);
						}
					}

					note.wasGoodHit = true;
					vocals.volume = 0;

					if (!note.isSustainNote)
					{
						note.kill();
						notes.remove(note, true);
						note.destroy();
					}
					return;
			}

			if (!note.isSustainNote)
			{
				popUpScore(note);
				combo += 1;
				songHits++;
				if(combo > 9999) combo = 9999;
			}

			playerStrums.forEach(function(spr:StrumNote)
			{
				if (note.noteData == spr.ID)
				{
					spr.playAnim('confirm', true);
				}
			});

			note.wasGoodHit = true;
			vocals.volume = ClientPrefs.voicesVolume;

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	function noteMiss(direction:Int = 1):Void
	{
		combo = 0;

		//songScore -= 10;
		songMisses++;

		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		vocals.volume = 0;
	}

	var COMBO_X:Float = 400;
	var COMBO_Y:Float = 340;
	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);

		vocals.volume = ClientPrefs.voicesVolume;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.x = COMBO_X;
		coolText.y = COMBO_Y;
		//

		var rating:FlxSprite = new FlxSprite();
		//var score:Int = 350;

		var daRating:String = "sick";

		if (noteDiff > Conductor.safeZoneOffset * 0.75)
		{
			daRating = 'shit';
			//score = 50;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.5)
		{
			daRating = 'bad';
			//score = 100;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.25)
		{
			daRating = 'good';
			//score = 200;
		}

		if(daRating == 'sick' && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note);
		}
		//songScore += score;

		/* if (combo > 60)
				daRating = 'sick';
			else if (combo > 12)
				daRating = 'good'
			else if (combo > 4)
				daRating = 'bad';
			*/

		rating.loadGraphic(Paths.image('uiskins/default/$daRating'));
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.visible = !ClientPrefs.hideHud;
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image('uiskins/default/combo'));
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;
		comboSpr.visible = !ClientPrefs.hideHud;
		comboSpr.x += ClientPrefs.comboOffset[0];
		comboSpr.y -= ClientPrefs.comboOffset[1];

		comboSpr.velocity.x += FlxG.random.int(1, 10);
		comboGroup.add(rating);

		rating.setGraphicSize(Std.int(rating.width * 0.7));
		rating.antialiasing = ClientPrefs.globalAntialiasing;
		comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
		comboSpr.antialiasing = ClientPrefs.globalAntialiasing;

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if(combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image('uiskins/default/num' + Std.int(i)));
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * PlayState.daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.visible = !ClientPrefs.hideHud;

			if (combo >= 10 || combo == 0)
				insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
		/* 
			trace(combo);
			trace(seperatedScore);
			*/

		coolText.text = Std.string(seperatedScore);
		// comboGroup.add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});
	}

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1 && ClientPrefs.middleScroll) targetAlpha = 0.35;

			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X, strumLine.y, i, player);
			babyArrow.alpha = targetAlpha;

			if (player == 1)
			{
				playerStrums.add(babyArrow);
			}
			else
			{
				if(ClientPrefs.middleScroll)
				{
					babyArrow.x += 310;
					if(i >= Math.floor(dadKeys/2)) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}


	// For Opponent's notes glow
	function StrumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = strumLineNotes.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}


	// Note splash shit, duh
	function spawnNoteSplashOnNote(note:Note) {
		if(ClientPrefs.noteSplashes && note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'noteSplashes';
		
		var hue:Float = ClientPrefs.arrowHSV[data % 4][0] / 360;
		var sat:Float = ClientPrefs.arrowHSV[data % 4][1] / 100;
		var brt:Float = ClientPrefs.arrowHSV[data % 4][2] / 100;
		if(note != null) {
			skin = note.noteSplashTexture;
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, note, skin, hue, sat, brt, bfKeys);
		grpNoteSplashes.add(splash);
	}
	
	override function destroy() {
		FlxG.sound.music.stop();
		vocals.stop();
		vocals.destroy();

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		super.destroy();
	}
}
