package;

import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import flixel.addons.effects.FlxTrail;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.system.FlxSound;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxBasic;

using StringTools;

class Stage extends FlxBasic {
    public var curStage:String = '';
    var instance:Dynamic;

    public var boyfriendGroup:FlxTypedSpriteGroup<Character>;
	public var dadGroup:FlxTypedSpriteGroup<Character>;
	public var gfGroup:FlxTypedSpriteGroup<Character>;

    public var background:FlxTypedGroup<FlxBasic> = new FlxTypedGroup();
    public var overGF:FlxTypedGroup<FlxBasic> = new FlxTypedGroup();
    public var overDad:FlxTypedGroup<FlxBasic> = new FlxTypedGroup();
    public var foreground:FlxTypedGroup<FlxBasic> = new FlxTypedGroup();

    public var halloweenBG:BGSprite;
	public var halloweenWhite:BGSprite;
    var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

    public var phillyLightsColors:Array<FlxColor>;
	public var phillyWindow:BGSprite;
	public var phillyStreet:BGSprite;
	public var phillyTrain:BGSprite;
	public var trainSound:FlxSound;
    var curLight:Int = -1;
    var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;
	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;
    var startedMoving:Bool = false;

    var limoKillingState:Int = 0;
	public var limo:BGSprite;
	public var limoMetalPole:BGSprite;
	public var limoLight:BGSprite;
	public var limoCorpse:BGSprite;
	public var limoCorpseTwo:BGSprite;
	public var bgLimo:BGSprite;
	public var grpLimoParticles:FlxTypedSpriteGroup<BGSprite>;
	public var grpLimoDancers:FlxTypedSpriteGroup<BackgroundDancer>;
	public var fastCar:BGSprite;
    var limoSpeed:Float = 0;
    var fastCarCanDrive:Bool = true;
    var carTimer:FlxTimer;

    public var upperBoppers:BGSprite;
	public var bottomBoppers:BGSprite;
	public var santa:BGSprite;
	var heyTimer:Float;

    public var bgGirls:BackgroundGirls;
	public var bgGhouls:BGSprite;

    public var tankWatchtower:BGSprite;
	public var tankGround:BGSprite;
	public var tankmanRun:FlxTypedSpriteGroup<TankmenBG>;
    var tankX:Float = 400;
	var tankSpeed:Float = FlxG.random.float(5, 7);
	var tankAngle:Float = FlxG.random.int(-90, 45);

    public var bgspec:BGSprite;

    public function new(stage:String = '', instance:Dynamic) {
        super();
        this.instance = instance;

        boyfriendGroup = instance.boyfriendGroup;
        dadGroup = instance.dadGroup;
        gfGroup = instance.gfGroup;

        createStage(stage);
    }

    public function createStage(stage:String = '') {
        var groups = [background, overGF, overDad, foreground];
        for (grp in groups) {
            for (spr in grp) {
                spr.kill();
                background.remove(spr);
                spr.destroy();
            }
        }
        curStage = stage;
        
        if (ClientPrefs.gameQuality != 'Crappy') {
            switch (curStage)
            {
                case 'stage': //Week 1
                    var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
                    background.add(bg);

                    var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
                    stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
                    stageFront.updateHitbox();
                    background.add(stageFront);

                    if (ClientPrefs.gameQuality == 'Normal') {
                        var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
                        stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
                        stageLight.updateHitbox();
                        background.add(stageLight);
                        var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
                        stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
                        stageLight.updateHitbox();
                        stageLight.flipX = true;
                        background.add(stageLight);

                        var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
                        stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
                        stageCurtains.updateHitbox();
                        foreground.add(stageCurtains);
                    }

                case 'spooky': //Week 2
                    if (ClientPrefs.gameQuality == 'Normal') {
                        halloweenBG = new BGSprite('halloween_bg', -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
                    } else {
                        halloweenBG = new BGSprite('halloween_bg_low', -200, -100);
                    }
                    background.add(halloweenBG);

                    halloweenWhite = new BGSprite(null, -800, -400, 0, 0);
                    halloweenWhite.makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.WHITE);
                    halloweenWhite.alpha = 0;
                    halloweenWhite.blend = ADD;
                    foreground.add(halloweenWhite);

                    //PRECACHE SOUNDS
                    Paths.sound('thunder_1');
                    Paths.sound('thunder_2');

                case 'philly': //Week 3
                    if (ClientPrefs.gameQuality == 'Normal') {
                        var bg:BGSprite = new BGSprite('philly/sky', -100, 0, 0.1, 0.1);
                        background.add(bg);
                    }

                    var city:BGSprite = new BGSprite('philly/city', -10, 0, 0.3, 0.3);
                    city.setGraphicSize(Std.int(city.width * 0.85));
                    city.updateHitbox();
                    background.add(city);

                    phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
                    phillyWindow = new BGSprite('philly/window', city.x, city.y, 0.3, 0.3);
                    phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
                    phillyWindow.updateHitbox();
                    background.add(phillyWindow);
                    phillyWindow.alpha = 0;

                    if (ClientPrefs.gameQuality == 'Normal') {
                        var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -40, 50);
                        background.add(streetBehind);
                    }

                    phillyTrain = new BGSprite('philly/train', 2000, 360);
                    background.add(phillyTrain);

                    trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
                    FlxG.sound.list.add(trainSound);

                    phillyStreet = new BGSprite('philly/street', -40, 50);
                    background.add(phillyStreet);

                case 'limo': //Week 4
                    var skyBG:BGSprite = new BGSprite('limo/limoSunset', -120, -50, 0.1, 0.1);
                    background.add(skyBG);

                    if (ClientPrefs.gameQuality == 'Normal') {
                        limoMetalPole = new BGSprite('gore/metalPole', -500, 220, 0.4, 0.4);
                        background.add(limoMetalPole);

                        bgLimo = new BGSprite('limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
                        background.add(bgLimo);

                        limoCorpse = new BGSprite('gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
                        background.add(limoCorpse);

                        limoCorpseTwo = new BGSprite('gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
                        background.add(limoCorpseTwo);

                        grpLimoDancers = new FlxTypedSpriteGroup<BackgroundDancer>();
                        background.add(grpLimoDancers);

                        for (i in 0...5)
                        {
                            var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
                            dancer.scrollFactor.set(0.4, 0.4);
                            grpLimoDancers.add(dancer);
                        }

                        limoLight = new BGSprite('gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
                        background.add(limoLight);

                        grpLimoParticles = new FlxTypedSpriteGroup<BGSprite>();
                        background.add(grpLimoParticles);

                        //PRECACHE BLOOD
                        var particle:BGSprite = new BGSprite('gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
                        particle.alpha = 0.01;
                        grpLimoParticles.add(particle);
                        resetLimoKill();

                        //PRECACHE SOUND
                        Paths.sound('dancerdeath');
                    }

                    limo = new BGSprite('limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);
                    overGF.add(limo);

                    fastCar = new BGSprite('limo/fastCarLol', -300, 160);
                    fastCar.active = true;
                    background.add(fastCar);
                    limoKillingState = 0;

                case 'mall': //Week 5 - Cocoa, Eggnog
                    var bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
                    bg.setGraphicSize(Std.int(bg.width * 0.8));
                    bg.updateHitbox();
                    background.add(bg);

                    if (ClientPrefs.gameQuality == 'Normal') {
                        upperBoppers = new BGSprite('christmas/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
                        upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
                        upperBoppers.updateHitbox();
                        background.add(upperBoppers);

                        var bgEscalator:BGSprite = new BGSprite('christmas/bgEscalator', -1100, -600, 0.3, 0.3);
                        bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
                        bgEscalator.updateHitbox();
                        background.add(bgEscalator);
                    }

                    var tree:BGSprite = new BGSprite('christmas/christmasTree', 370, -250, 0.40, 0.40);
                    background.add(tree);

                    bottomBoppers = new BGSprite('christmas/bottomBop', -300, 140, 0.9, 0.9, ['Bottom Level Boppers Idle']);
                    bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
                    bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
                    bottomBoppers.updateHitbox();
                    background.add(bottomBoppers);

                    var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 700);
                    background.add(fgSnow);

                    santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
                    background.add(santa);
                    Paths.sound('Lights_Shut_off');

                case 'mallEvil': //Week 5 - Winter Horrorland
                    var bg:BGSprite = new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2);
                    bg.setGraphicSize(Std.int(bg.width * 0.8));
                    bg.updateHitbox();
                    background.add(bg);

                    var evilTree:BGSprite = new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2);
                    background.add(evilTree);

                    var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -200, 700);
                    background.add(evilSnow);

                case 'school': //Week 6 - Senpai, Roses
                    var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
                    background.add(bgSky);
                    bgSky.antialiasing = false;

                    var repositionShit = -200;

                    var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
                    background.add(bgSchool);
                    bgSchool.antialiasing = false;

                    var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
                    background.add(bgStreet);
                    bgStreet.antialiasing = false;

                    var widShit = Std.int(bgSky.width * 6);
                    if (ClientPrefs.gameQuality == 'Normal') {
                        var fgTrees:BGSprite = new BGSprite('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
                        fgTrees.setGraphicSize(Std.int(widShit * 0.8));
                        fgTrees.updateHitbox();
                        background.add(fgTrees);
                        fgTrees.antialiasing = false;
                    }

                    var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
                    bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
                    bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
                    bgTrees.animation.play('treeLoop');
                    bgTrees.scrollFactor.set(0.85, 0.85);
                    background.add(bgTrees);
                    bgTrees.antialiasing = false;

                    if (ClientPrefs.gameQuality == 'Normal') {
                        var treeLeaves:BGSprite = new BGSprite('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
                        treeLeaves.setGraphicSize(widShit);
                        treeLeaves.updateHitbox();
                        background.add(treeLeaves);
                        treeLeaves.antialiasing = false;
                    }

                    bgSky.setGraphicSize(widShit);
                    bgSchool.setGraphicSize(widShit);
                    bgStreet.setGraphicSize(widShit);
                    bgTrees.setGraphicSize(Std.int(widShit * 1.4));

                    bgSky.updateHitbox();
                    bgSchool.updateHitbox();
                    bgStreet.updateHitbox();
                    bgTrees.updateHitbox();

                    if (ClientPrefs.gameQuality == 'Normal') {
                        bgGirls = new BackgroundGirls(-100, 190);
                        bgGirls.scrollFactor.set(0.9, 0.9);

                        bgGirls.setGraphicSize(Std.int(bgGirls.width * PlayState.daPixelZoom));
                        bgGirls.updateHitbox();
                        background.add(bgGirls);
                    }

                case 'schoolEvil': //Week 6 - Thorns
                    var posX = 400;
                    var posY = 200;
                    if (ClientPrefs.gameQuality == 'Normal') {
                        var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool', posX, posY, 0.8, 0.9, ['background 2'], true);
                        bg.scale.set(6, 6);
                        bg.antialiasing = false;
                        background.add(bg);

                        bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
                        bgGhouls.setGraphicSize(Std.int(bgGhouls.width * PlayState.daPixelZoom));
                        bgGhouls.updateHitbox();
                        bgGhouls.visible = false;
                        bgGhouls.antialiasing = false;
                        background.add(bgGhouls);
                    } else {
                        var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool_low', posX, posY, 0.8, 0.9);
                        bg.scale.set(6, 6);
                        bg.antialiasing = false;
                        background.add(bg);
                    }

                case 'tank': //Week 7 - Ugh, Guns, Stress
                    var sky:BGSprite = new BGSprite('tankSky', -400, -400, 0, 0);
                    background.add(sky);

                    if(ClientPrefs.gameQuality == 'Normal')
                    {
                        var clouds:BGSprite = new BGSprite('tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
                        clouds.active = true;
                        clouds.velocity.x = FlxG.random.float(5, 15);
                        background.add(clouds);

                        var mountains:BGSprite = new BGSprite('tankMountains', -300, -20, 0.2, 0.2);
                        mountains.setGraphicSize(Std.int(1.2 * mountains.width));
                        mountains.updateHitbox();
                        background.add(mountains);

                        var buildings:BGSprite = new BGSprite('tankBuildings', -200, 0, 0.3, 0.3);
                        buildings.setGraphicSize(Std.int(1.1 * buildings.width));
                        buildings.updateHitbox();
                        background.add(buildings);
                    }

                    var ruins:BGSprite = new BGSprite('tankRuins',-200,0,.35,.35);
                    ruins.setGraphicSize(Std.int(1.1 * ruins.width));
                    ruins.updateHitbox();
                    background.add(ruins);

                    if(ClientPrefs.gameQuality == 'Normal')
                    {
                        var smokeLeft:BGSprite = new BGSprite('smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
                        background.add(smokeLeft);
                        var smokeRight:BGSprite = new BGSprite('smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
                        background.add(smokeRight);

                        tankWatchtower = new BGSprite('tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
                        background.add(tankWatchtower);
                    }

                    tankGround = new BGSprite('tankRolling', 300, 300, 0.5, 0.5,['BG tank w lighting'], true);
                    background.add(tankGround);

                    tankmanRun = new FlxTypedSpriteGroup<TankmenBG>();
                    background.add(tankmanRun);

                    var ground:BGSprite = new BGSprite('tankGround', -420, -150);
                    ground.setGraphicSize(Std.int(1.15 * ground.width));
                    ground.updateHitbox();
                    background.add(ground);
                    moveTank();

                    foreground.add(new BGSprite('tank0', -500, 650, 1.7, 1.5, ['fg']));
                    if(ClientPrefs.gameQuality == 'Normal') foreground.add(new BGSprite('tank1', -300, 750, 2, 0.2, ['fg']));
                    foreground.add(new BGSprite('tank2', 450, 940, 1.5, 1.5, ['foreground']));
                    if(ClientPrefs.gameQuality == 'Normal') foreground.add(new BGSprite('tank4', 1300, 900, 1.5, 1.5, ['fg']));
                    foreground.add(new BGSprite('tank5', 1620, 700, 1.5, 1.5, ['fg']));
                    if(ClientPrefs.gameQuality == 'Normal') foreground.add(new BGSprite('tank3', 1300, 1200, 3.5, 2.5, ['fg']));
                
                case 'mansion':
                    var bg = new BGSprite('shaggy/bg_lemon', -400, -160, 0.95, 0.95);
                    bg.setGraphicSize(Std.int(bg.width * 1.5));
                    background.add(bg);

                case 'sonicStage':
                    var sSKY = new BGSprite('sonicexe/PolishedP1/SKY', -222, 134);
                    background.add(sSKY);

                    if (ClientPrefs.gameQuality == 'Normal') {
                        var hills = new BGSprite('sonicexe/PolishedP1/HILLS', -264, -6, 1.1);
                        background.add(hills);

                        var bg2 = new BGSprite('sonicexe/PolishedP1/FLOOR2', -345, -119, 1.2);
                        background.add(bg2);
                    }

                    var bg = new BGSprite('sonicexe/PolishedP1/FLOOR1', -297, -96, 1.3);
                    background.add(bg);
                    
                    var eggman = new BGSprite('sonicexe/PolishedP1/EGGMAN', -218, -69, 1.32);
                    background.add(eggman);

                    var knuckle = new BGSprite('sonicexe/PolishedP1/KNUCKLE', 285, -200, 1.36);
                    background.add(knuckle);

                    var sticklol:FlxSprite = new FlxSprite(-100, 50);
                    sticklol.frames = Paths.getSparrowAtlas('sonicexe/PolishedP1/TailsSpikeAnimated');
                    sticklol.animation.addByPrefix('a', 'Tails Spike Animated instance 1', 4, true);
                    sticklol.setGraphicSize(Std.int(sticklol.width * 1.2));
                    sticklol.updateHitbox();
                    sticklol.antialiasing = ClientPrefs.globalAntialiasing;
                    sticklol.scrollFactor.set(1.37, 1);
                    background.add(sticklol);
                    sticklol.animation.play('a', true);
                    if (ClientPrefs.gameQuality != 'Normal')
                        sticklol.animation.stop();

                    var tail = new BGSprite('sonicexe/PolishedP1/TAIL', -349, -109, 1.34);
                    foreground.add(tail);

                case 'sonicexeStage':
                    var sSKY = new BGSprite('sonicexe/SonicP2/sky', -414, -440.8);
                    sSKY.scale.set(1.4, 1.4);
                    background.add(sSKY);

                    var trees = new BGSprite('sonicexe/SonicP2/backtrees', -290.55, -298.3, 1.1);
                    trees.scale.set(1.2, 1.2);
                    background.add(trees);

                    var bg2 = new BGSprite('sonicexe/SonicP2/trees', -306, -334.65, 1.2);
                    bg2.scale.set(1.2, 1.2);
                    background.add(bg2);

                    var bg = new BGSprite('sonicexe/SonicP2/ground', -309.95, -240.2, 1.3);
                    bg.scale.x = 1.2;
                    bg.scale.y = 1.2;
                    background.add(bg);

                    bgspec = new BGSprite("sonicexe/SonicP2/GreenHill", 321.5, 382.65);
                    bgspec.antialiasing = false;
                    bgspec.alpha = 0.00001;
                    bgspec.scale.x = 8;
                    bgspec.scale.y = 8;
                    background.add(bgspec);
            }
        }
    }

    public function onStageSwitch() {
        if (ClientPrefs.gameQuality != 'Crappy') {
            switch(curStage) {
                case 'school' | 'schoolEvil':
                    GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
                    GameOverSubstate.loopSoundName = 'gameOver-pixel';
                    GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
                    GameOverSubstate.characterName = 'bf-pixel-dead';
                
                case 'sonicStage' | 'sonicexeStage':
                    var grps = [boyfriendGroup, dadGroup, gfGroup];
                    for (grp in grps) {
                        if (grp != null) {
                            for (char in grp)
                                char.scrollFactor.set(1.37, 1);
                        }
                    }
            }
        }
    }

    public function onCharacterInit() {
        if (ClientPrefs.gameQuality != 'Crappy') {
            switch(curStage) {
                case 'limo':
                    resetFastCar();
            }
        }
    }

    public function onCountdownTick() {
        if (ClientPrefs.gameQuality != 'Crappy') {
            switch (curStage) {
                case 'mall':
                    // head bopping for bg characters on Mall
                    if (ClientPrefs.gameQuality == 'Normal')
                        upperBoppers.dance(true);
    
                    bottomBoppers.dance(true);
                    santa.dance(true);
            }
        }
    }

    public function onUpdate() {
        if (ClientPrefs.gameQuality != 'Crappy') {
            switch (curStage) {
                case 'philly':
                    if (trainMoving)
                    {
                        trainFrameTiming += FlxG.elapsed;

                        if (trainFrameTiming >= 1 / 24)
                        {
                            updateTrainPos();
                            trainFrameTiming = 0;
                        }
                    }
                    phillyWindow.alpha -= (Conductor.normalizedCrochet / 1000) * FlxG.elapsed * 1.5;
                
                case 'limo':
                    if (ClientPrefs.gameQuality == 'Normal') {
                        grpLimoParticles.forEach(function(spr:BGSprite) {
                            if (spr.animation.curAnim != null && spr.animation.curAnim.finished) {
                                spr.kill();
                                grpLimoParticles.remove(spr, true);
                                spr.destroy();
                            }
                        });

                        switch(limoKillingState) {
                            case 1:
                                limoMetalPole.x += 5000 * FlxG.elapsed;
                                limoLight.x = limoMetalPole.x - 180;
                                limoCorpse.x = limoLight.x - 50;
                                limoCorpseTwo.x = limoLight.x + 35;

                                var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
                                for (i in 0...dancers.length) {
                                    if (dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 130) {
                                        switch(i) {
                                            case 0 | 3:
                                                if (i == 0) FlxG.sound.play(Paths.sound('dancerdeath'), 0.5);

                                                var diffStr:String = i == 3 ? ' 2 ' : ' ';
                                                var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4, ['hench leg spin${diffStr}PINK'], false);
                                                grpLimoParticles.add(particle);
                                                var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4, ['hench arm spin${diffStr}PINK'], false);
                                                grpLimoParticles.add(particle);
                                                var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4, ['hench head spin${diffStr}PINK'], false);
                                                grpLimoParticles.add(particle);

                                                var particle:BGSprite = new BGSprite('gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'], false);
                                                particle.flipX = true;
                                                particle.angle = -57.5;
                                                grpLimoParticles.add(particle);
                                            case 1:
                                                limoCorpse.visible = true;
                                            case 2:
                                                limoCorpseTwo.visible = true;
                                        } //Note: Nobody cares about the fifth dancer because he is mostly hidden offscreen :(
                                        dancers[i].x += FlxG.width * 2;
                                    }
                                }

                                if (limoMetalPole.x > FlxG.width * 2) {
                                    resetLimoKill();
                                    limoSpeed = 800;
                                    limoKillingState = 2;
                                }

                            case 2:
                                limoSpeed -= 4000 * FlxG.elapsed;
                                bgLimo.x -= limoSpeed * FlxG.elapsed;
                                if (bgLimo.x > FlxG.width * 1.5) {
                                    limoSpeed = 3000;
                                    limoKillingState = 3;
                                }

                            case 3:
                                limoSpeed -= 2000 * FlxG.elapsed;
                                if (limoSpeed < 1000) limoSpeed = 1000;

                                bgLimo.x -= limoSpeed * FlxG.elapsed;
                                if (bgLimo.x < -275) {
                                    limoKillingState = 4;
                                    limoSpeed = 800;
                                }

                            case 4:
                                bgLimo.x = FlxMath.lerp(bgLimo.x, -150, CoolUtil.boundTo(FlxG.elapsed * 9, 0, 1));
                                if (Math.round(bgLimo.x) == -150) {
                                    bgLimo.x = -150;
                                    limoKillingState = 0;
                                }
                        }

                        if (limoKillingState > 2) {
                            var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
                            for (i in 0...dancers.length) {
                                dancers[i].x = (370 * i) + bgLimo.x + 280;
                            }
                        }
                    }
                
                case 'mall':
                    if (heyTimer > 0) {
                        heyTimer -= FlxG.elapsed;
                        if (heyTimer <= 0) {
                            bottomBoppers.dance(true);
                            heyTimer = 0;
                        }
                    }
                
                case 'schoolEvil':
                    if (ClientPrefs.gameQuality == 'Normal' && bgGhouls.animation.curAnim != null && bgGhouls.animation.curAnim.finished) {
                        bgGhouls.visible = false;
                    }

                case 'tank':
					moveTank(FlxG.elapsed);
            }
        }
    }

    public function onStepHit() {
        //nothing lol
    }

    public function onBeatHit() {
        if (ClientPrefs.gameQuality != 'Crappy') {
            var curNumeratorBeat = Conductor.getCurNumeratorBeat(PlayState.SONG, instance.curBeat);
            switch (curStage) {
                case 'spooky':
                    if (FlxG.random.bool(10) && instance.curBeat > lightningStrikeBeat + lightningOffset && ClientPrefs.gameQuality != 'Crappy')
                    {
                        lightningStrikeShit();
                    }
                
                case 'philly':
                    if (!trainMoving)
                        trainCooldown += 1;

                    if (curNumeratorBeat % Conductor.timeSignature[0] == 0)
                    {
                        curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
                        phillyWindow.color = phillyLightsColors[curLight];
                        phillyWindow.alpha = 1;
                    }

                    if (curNumeratorBeat % (Conductor.timeSignature[0] * 2) == Conductor.timeSignature[0] && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8 && !trainSound.playing)
                    {
                        trainCooldown = FlxG.random.int(-4, 0);
                        trainStart();
                    }
                
                case 'limo':
                    if (ClientPrefs.gameQuality == 'Normal') {
                        grpLimoDancers.forEach(function(dancer:BackgroundDancer)
                        {
                            dancer.dance();
                        });
                    }

                    if (FlxG.random.bool(10) && fastCarCanDrive)
                        fastCarDrive();
                
                case 'mall':
                    if (ClientPrefs.gameQuality == 'Normal') {
                        upperBoppers.dance(true);
                    }

                    if (heyTimer <= 0) bottomBoppers.dance(true);
                    santa.dance(true);
                
                case 'school':
                    if (ClientPrefs.gameQuality == 'Normal') {
                        bgGirls.dance();
                    }

                case 'tank':
                    if(ClientPrefs.gameQuality == 'Normal') tankWatchtower.dance();
                    foreground.forEach(function(spr:FlxBasic)
                    {
                        var sprite:Dynamic = spr;
                        var sprite:BGSprite = sprite;
                        sprite.dance();
                    });
            }
        }
    }

    public function onEvent(eventName:String, value1:String, value2:String) {
        if (ClientPrefs.gameQuality != 'Crappy') {
            switch (eventName) {
                case 'Hey!':
                    if (curStage == 'mall') {
                        var value:Int = 2;
                        switch(value1.toLowerCase().trim()) {
                            case 'bf' | 'boyfriend' | '0':
                                value = 0;
                            case 'gf' | 'girlfriend' | '1':
                                value = 1;
                        }

                        var time:Float = Std.parseFloat(value2);
				        if (Math.isNaN(time) || time <= 0) time = 0.6;

                        if (value != 0) {
                            bottomBoppers.animation.play('hey', true);
                            heyTimer = time;
                        }
                    }
                
                case 'Trigger BG Ghouls':
                    if (curStage == 'schoolEvil' && ClientPrefs.gameQuality == 'Normal') {
                        bgGhouls.dance(true);
                        bgGhouls.visible = true;
                    }

                case 'BG Freaks Expression':
                    if (bgGirls != null) bgGirls.swapDanceType();
            }
        }
    }

    public function onOpenSubState() {
        if (ClientPrefs.gameQuality != 'Crappy') {
            if (carTimer != null) carTimer.active = false;
        }
    }

    public function onCloseSubState() {
        if (ClientPrefs.gameQuality != 'Crappy') {
            if (carTimer != null) carTimer.active = true;
        }
    }

    function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		if (ClientPrefs.gameQuality == 'Normal') halloweenBG.animation.play('halloweem bg lightning strike');

		lightningStrikeBeat = instance.curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		var chars = [boyfriendGroup, gfGroup];
		for (group in chars) {
			for (char in group) {
				if (char.animOffsets.exists('scared')) {
					char.playAnim('scared', true);
				}
			}
		}

		if (ClientPrefs.camZooms) {
			FlxG.camera.zoom += 0.015;
			instance.camHUD.zoom += 0.03;

			if (!instance.camZooming) { //Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: instance.defaultCamZoom}, 0.5);
				FlxTween.tween(instance.camHUD, {zoom: 1}, 0.5);
			}
		}

		if (ClientPrefs.flashing) {
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
		}
	}

	function trainStart():Void
	{
		trainMoving = true;
		trainSound.play(true);
	}

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			for (gf in gfGroup) {
				if (gf.animOffsets.exists('hairBlow')) {
					gf.playAnim('hairBlow');
					gf.specialAnim = true;
				}
			}
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		for (gf in gfGroup) {
			if (gf.animOffsets.exists('hairFall')) {
				gf.danced = false; //Sets head to the correct position once the animation ends
				gf.playAnim('hairFall');
				gf.specialAnim = true;
			}
		}
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	function fastCarDrive()
	{
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		carTimer = new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
			carTimer = null;
		});
	}

	public function killHenchmen():Void
	{
		if (ClientPrefs.gameQuality == 'Normal' && curStage == 'limo') {
			if (limoKillingState < 1) {
				limoMetalPole.x = -400;
				limoMetalPole.visible = true;
				limoLight.visible = true;
				limoCorpse.visible = false;
				limoCorpseTwo.visible = false;
				limoKillingState = 1;

				#if ACHIEVEMENTS_ALLOWED
                if (instance.checkForAchievement != null) {
                    Achievements.henchmenDeath++;
                    FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;
                    var achieve:String = instance.checkForAchievement(['roadkill_enthusiast']);
                    if (achieve != null) {
                        instance.startAchievement(achieve);
                    } else {
                        FlxG.save.flush();
                    }
                    FlxG.log.add('Deaths: ${Achievements.henchmenDeath}');
                }
				#end
			}
		}
	}

	function resetLimoKill():Void
	{
		if (curStage == 'limo') {
			limoMetalPole.x = -500;
			limoMetalPole.visible = false;
			limoLight.x = -500;
			limoLight.visible = false;
			limoCorpse.x = -500;
			limoCorpse.visible = false;
			limoCorpseTwo.x = -500;
			limoCorpseTwo.visible = false;
		}
	}

    function moveTank(?elapsed:Float = 0):Void
	{
		if(instance.inCutscene != null && !instance.inCutscene)
		{
			tankAngle += elapsed * tankSpeed;
			tankGround.angle = tankAngle - 90 + 15;
			tankGround.x = tankX + 1500 * Math.cos(Math.PI / 180 * (1 * tankAngle + 180));
			tankGround.y = 1300 + 1100 * Math.sin(Math.PI / 180 * (1 * tankAngle + 180));
		}
	}
}