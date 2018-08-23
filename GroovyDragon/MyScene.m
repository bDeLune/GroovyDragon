#import "MyScene.h"
#import "BTLEManager.h"

@interface MyScene () <SKPhysicsContactDelegate, BTLEManagerDelegate, MySceneProtocol> {
    SKSpriteNode* _bird;
    SKColor* _skyColor;
    SKTexture* _pipeTexture1;
    SKTexture* _pipeTexture2;
    SKAction* _movePipesAndRemove;
    SKNode* _moving;
    SKNode* _pipes;
    BOOL _canRestart;
    SKLabelNode* _scoreLabelNode;
    NSInteger _score;
    int _currentLevel;
    
    //Level Properties
    SKTexture* birdTexture1;
    SKTexture* birdTexture2;
    SKTexture* skylineTexture;
    SKTexture* groundTexture;
    
    NSMutableArray * _localJSONInfo;
    NSMutableArray * _levelSpeedArray;
    NSMutableArray * _levelPipeGapArray;
    NSMutableArray * _levelPipePositionArray;
    NSMutableArray * _levelPipeNoArray;
    
    NSMutableArray* levelInformation;
    BOOL _disallowNextExhale;
    BOOL _disallowNextInhale;
    float _lowestInhaleValue;
    float _lowestExhaleValue;
    CGFloat _currentInhaleValue;
    CGFloat _currentExhaleValue;
    bool _exhaleTriggerToggle;
    bool _reverseMode;
    bool _firstLevelPauseAllow;
    NSUserDefaults * userDefaults ;
    int _currentPipeNo;
    
    int _totalLevelCount;
    bool _justStarted;
    bool firstBlow;
    BOOL _affectedByG;
    id thisSelf;
}
@end

@implementation MyScene

static const uint32_t birdCategory = 1 << 0;
static const uint32_t worldCategory = 1 << 1;
static const uint32_t pipeCategory = 1 << 2;
static const uint32_t scoreCategory = 1 << 3;
static NSInteger const kVerticalPipeGap = 100;

//INITIALISE FIRST LEVEL WITH JSON///
-(id)initWithSize:(CGSize)size {

    if (self = [super initWithSize:size]) {
        
        _disallowNextExhale = false;
        _disallowNextInhale = false;
        _lowestInhaleValue = 1;
        _lowestExhaleValue = 1;
        
        firstBlow = true;
        _justStarted = true;
        _levelPipeGapArray = [[NSMutableArray alloc] init];
        _levelPipePositionArray = [[NSMutableArray alloc] init];
        _levelSpeedArray = [[NSMutableArray alloc] init];
        _levelPipeNoArray = [[NSMutableArray alloc] init];
        levelInformation = [[NSMutableArray alloc] init];
        self.btleMager=[BTLEManager new];
        self.btleMager.delegate=self;
        [self.btleMager startWithDeviceName:@"GroovTube 2.0" andPollInterval:0.035]; //was .035
        
        _affectedByG = true;
        _bird.physicsBody.affectedByGravity = YES;
        
        NSError* error = nil;
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"flappyBreathLevelInfo" ofType:@".json"];
        NSData *content = [[NSData alloc] initWithContentsOfFile:filePath options: 0 error: &error];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:content options:kNilOptions error:nil];
        
        int i = 0;
        
        if (json == nil)
        {
            NSLog(@"Failed to read file, error %@", error);
        }
        
        NSMutableDictionary *structure = [json valueForKey:@"levelStructure"];
        _totalLevelCount = (int)[json[@"LevelCount"] integerValue];
        NSLog(@"levelcount : %d", _totalLevelCount);
        
        [_levelSpeedArray addObject:@"Nothing Here"];
        [_levelPipeGapArray addObject:@"Nothing Here"];
        [_levelPipePositionArray addObject:@"Nothing Here"];
        [_levelPipeNoArray addObject:@"Nothing Here"];
        
        for (NSMutableDictionary *dictionary in structure)
        {
            NSArray *levelInfo = [dictionary valueForKey:@"structure"];
            NSMutableArray *gapPositionArray = [levelInfo valueForKey:@"GapPosition"];
            NSMutableArray *pipePositionArray = [levelInfo valueForKey:@"GapWidth"];
            NSMutableArray* thislevelPositionInfo = [[NSMutableArray alloc] init];
            NSMutableArray* thislevelGapInfo = [[NSMutableArray alloc] init];
            
            int noOfPipes = (int)[levelInfo count];
            
            for (int k = 0; k < [levelInfo count]; k++){
                
                NSNumber *gapPosition = [gapPositionArray objectAtIndex:k];
                NSNumber *pipePosition = [pipePositionArray objectAtIndex:k];
                
                [thislevelGapInfo addObject:gapPosition];
                [thislevelPositionInfo addObject:pipePosition];
            }
            
            NSNumber *levelSpeed = [dictionary valueForKey:@"speed"];
            [_levelSpeedArray addObject:levelSpeed];
            [_levelPipePositionArray addObject:thislevelPositionInfo];
            [_levelPipeGapArray addObject:thislevelGapInfo];
            [_levelPipeNoArray addObject: [NSNumber numberWithInt:noOfPipes]];
            
            i++;
        }
        
        [self createLevel];
        
        return self;
    }

    return self;
}

-(void) createLevel{
    NSLog(@"Creating level");
    int reset = 0;
    
    [self.thisdelegate updateProgressBarDG:reset];
    _currentLevel = [[NSUserDefaults standardUserDefaults] integerForKey:@"_currentLevel"];
    
    if (_currentLevel == 0 || _currentLevel > 3){
        _currentLevel = 1;
    }

    levelInformation = [self getLevels];
    NSArray *thisLevelInformation = [levelInformation objectAtIndex:_currentLevel];
    _currentInhaleValue = [self loadFloatFromUserDefaultsForKey:@"_currentInhaleValue"];
    _currentExhaleValue = [self loadFloatFromUserDefaultsForKey:@"_currentExhaleValue"];
    
    //Set threshold level value///
    if (_currentInhaleValue < 0.1){
        _currentInhaleValue = .50;
        NSLog(@"NO PREVIOUS INHALE VALUE FOUND - SET TO .15");
    }else{
        NSLog(@"INHALE VALUE FOUND - SET TO %f", _currentInhaleValue);
    }
    
    if (_currentExhaleValue < 0.1){
        _currentExhaleValue = .5;
        NSLog(@"NO PREVIOUS EXHALE VALUE FOUND - SET TO .15");
    }else{
        NSLog(@"EXHALE VALUE FOUND - SET TO %f", _currentExhaleValue);
    }
    
    _disallowNextExhale = false;
    _disallowNextInhale = false;
    _firstLevelPauseAllow = true;

    [self.thisdelegate updateLevelDG: _currentLevel];
    _exhaleTriggerToggle = true;
    _reverseMode = YES;
    _canRestart = NO;
    _currentPipeNo = 0;
    
    self.physicsWorld.gravity = CGVectorMake( 0.0, -5.0 );
    self.physicsWorld.contactDelegate = self;
    
    _skyColor = [SKColor colorWithRed:113.0/255.0 green:197.0/255.0 blue:207.0/255.0 alpha:1.0];
    
    [self setBackgroundColor:_skyColor];
    
    _moving = [SKNode node];
    [self addChild:_moving];
    
    _pipes = [SKNode node];
    [_moving addChild:_pipes];
    
    groundTexture = [SKTexture textureWithImageNamed:@"floor.png"];
    groundTexture.filteringMode = SKTextureFilteringNearest;
    
    SKAction* moveGroundSprite = [SKAction moveByX:-groundTexture.size.width*2 y:0 duration:0.02 * groundTexture.size.width*2];
    SKAction* resetGroundSprite = [SKAction moveByX:groundTexture.size.width*2 y:0 duration:0];
    SKAction* moveGroundSpritesForever = [SKAction repeatActionForever:[SKAction sequence:@[moveGroundSprite, resetGroundSprite]]];
    
    for( int t = 0; t < 2 + self.frame.size.width / ( groundTexture.size.width * 2 ); ++t ) {
        //Create the sprite
        SKSpriteNode* sprite = [SKSpriteNode spriteNodeWithTexture:groundTexture];
        [sprite setScale:2.0];
        sprite.position = CGPointMake(t * sprite.size.width, sprite.size.height / 2);
        [sprite runAction:moveGroundSpritesForever];
        [_moving addChild:sprite];
    }
   
    skylineTexture = [SKTexture textureWithImageNamed:[thisLevelInformation objectAtIndex:6]];
    skylineTexture = [SKTexture textureWithImageNamed:@"skyline2"];
    skylineTexture.filteringMode = SKTextureFilteringNearest;
    
    SKAction* moveSkylineSprite = [SKAction moveByX:-skylineTexture.size.width*2 y:0 duration:0.1 * skylineTexture.size.width*2];
    SKAction* resetSkylineSprite = [SKAction moveByX:skylineTexture.size.width*2 y:0 duration:0];
    SKAction* moveSkylineSpritesForever = [SKAction repeatActionForever:[SKAction sequence:@[moveSkylineSprite, resetSkylineSprite]]];
    
    for( int i = 0; i < 2 + self.frame.size.width / ( skylineTexture.size.width * 2 ); ++i ) {
        SKSpriteNode* sprite = [SKSpriteNode spriteNodeWithTexture:skylineTexture];
        [sprite setScale:2.0];
        sprite.zPosition = -20;
       sprite.position = CGPointMake(i * sprite.size.width, sprite.size.height / 2 + groundTexture.size.height * 2);
        [sprite runAction:moveSkylineSpritesForever];
        [_moving addChild:sprite];
    }
    
    SKNode* dummy = [SKNode node];
    dummy.position = CGPointMake(0, groundTexture.size.height);
    dummy.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(self.frame.size.width, groundTexture.size.height * 2)];
    dummy.physicsBody.dynamic = NO;
    dummy.physicsBody.categoryBitMask = worldCategory;
    [self addChild:dummy];
   
    _pipeTexture1 = [SKTexture textureWithImageNamed:[thisLevelInformation objectAtIndex:3]];
    _pipeTexture1.filteringMode = SKTextureFilteringNearest;
    _pipeTexture2 = [SKTexture textureWithImageNamed:[thisLevelInformation objectAtIndex:4]];
    _pipeTexture2.filteringMode = SKTextureFilteringNearest;
    
    CGFloat distanceToMove = self.frame.size.width + 2 * _pipeTexture1.size.width;
    SKAction* movePipes = [SKAction moveByX:-distanceToMove y:0 duration:0.01 * distanceToMove];
    SKAction* removePipes = [SKAction removeFromParent];
    _movePipesAndRemove = [SKAction sequence:@[movePipes, removePipes]];
    
   // Initialize label and create a label which holds the score
    _score = 0;
    _scoreLabelNode = [SKLabelNode labelNodeWithFontNamed:@"MarkerFelt-Wide"];
    _scoreLabelNode.position = CGPointMake( CGRectGetMidX( self.frame ), 3 * self.frame.size.height / 4 );
    _scoreLabelNode.zPosition = 100;
    _scoreLabelNode.text = [NSString stringWithFormat:@"Ready? Blow/Tap to go!"];
    [self addChild:_scoreLabelNode];
    
    [self.thisdelegate passbackSliderValueDG:_currentExhaleValue];
    [self.thisdelegate changeThresholdSliderValue:_currentExhaleValue];
}


-(void) firstBlow {
    
    NSLog(@"Very first blow - starting pipe spawn");
    levelInformation = [self getLevels];
    NSArray *thisLevelInformation = [levelInformation objectAtIndex:_currentLevel];
    
    birdTexture1 = [SKTexture textureWithImageNamed:[thisLevelInformation objectAtIndex:1]];
    birdTexture1.filteringMode = SKTextureFilteringNearest;
    birdTexture2 = [SKTexture textureWithImageNamed:[thisLevelInformation objectAtIndex:2]];
    birdTexture2.filteringMode = SKTextureFilteringNearest;
    
    NSNumber* levelSpeed = [_levelSpeedArray objectAtIndex:_currentLevel];
    CGFloat levelSpeedFloat = [levelSpeed floatValue];
    _moving.speed = levelSpeedFloat;
    
    SKAction* flap = [SKAction repeatActionForever:[SKAction animateWithTextures:@[birdTexture1, birdTexture2] timePerFrame:0.2]];
    
    _bird = [SKSpriteNode spriteNodeWithTexture:birdTexture1];
    [_bird setScale:2.0];
    _bird.position = CGPointMake(self.frame.size.width / 4, CGRectGetMidY(self.frame));
    [_bird runAction:flap];
    
    _bird.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:_bird.size.height / 2];
    _bird.physicsBody.dynamic = YES;
    //_bird.physicsBody.affectedByGravity = YES;
    // _affectedByG = YES;
    _bird.physicsBody.allowsRotation = NO;
    _bird.physicsBody.categoryBitMask = birdCategory;
    _bird.physicsBody.collisionBitMask = worldCategory | pipeCategory;
    _bird.physicsBody.contactTestBitMask = worldCategory | pipeCategory;
    
    if (_affectedByG == false){
        _bird.physicsBody.affectedByGravity = NO;
    }else{
        _bird.physicsBody.affectedByGravity = YES;
    }
    
    [self addChild:_bird];
    
    SKAction* spawn = [SKAction performSelector:@selector(spawnPipes) onTarget:self];
    SKAction* delay = [SKAction waitForDuration:2.0];
    SKAction* spawnThenDelay = [SKAction sequence:@[spawn, delay]];
    SKAction* spawnThenDelayForever = [SKAction repeatActionForever:spawnThenDelay];
    [self runAction:spawnThenDelayForever];
}

-(void)spawnPipes {
    
    _bird.speed = 1;
    
    NSMutableArray* currentLevelPipeGapInfo= [_levelPipePositionArray objectAtIndex: _currentLevel];
    NSMutableArray* currentLevelPipeHeightInfo = [_levelPipeGapArray objectAtIndex: _currentLevel];

    int noOfPipes = [[_levelPipeNoArray objectAtIndex: _currentLevel] intValue] ;
    if (_currentLevel > 1){
        [self.thisdelegate updateLevelDG:_currentLevel];
    }
    
    if (_score == 0 && _firstLevelPauseAllow == true){
        _firstLevelPauseAllow = false;
       [_pipes removeAllChildren];
        return;
    }else if (_currentPipeNo < noOfPipes && _moving.speed > 0 && self.paused == false){
    
        if (_score == 0 && _justStarted == true){
            _justStarted = false;
            [_pipes removeAllChildren];
        
        }

        if (_currentPipeNo < noOfPipes){
            NSLog(@"Creating pipe %d", _currentPipeNo);
            
    NSNumber* currentPipeHeightInfo = [currentLevelPipeHeightInfo objectAtIndex: _currentPipeNo];
    CGFloat pipeHeight = [currentPipeHeightInfo floatValue];
        
   
    NSNumber* currentPipeGapWidthInfo = [currentLevelPipeGapInfo objectAtIndex: _currentPipeNo];
    CGFloat pipeWidth = [currentPipeGapWidthInfo floatValue];
    
    SKNode* pipePair = [SKNode node];
    pipePair.position = CGPointMake( self.frame.size.width + _pipeTexture1.size.width, 0 );
    pipePair.zPosition = -10;
    
    CGFloat height = self.frame.size.height / 3;
    CGFloat y = pipeHeight*height;

    SKSpriteNode* pipe1 = [SKSpriteNode spriteNodeWithTexture:_pipeTexture1];
    SKSpriteNode* pipe2 = [SKSpriteNode spriteNodeWithTexture:_pipeTexture2];
    CGSize pipeOneSize = pipe1.size;
    CGSize pipeTwoSize = pipe2.size;
        
    [pipe1 setScale:2];
    pipe1.position = CGPointMake( 0, y );
    pipe1.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:pipe1.size];
    pipe1.physicsBody.dynamic = NO;
    pipe1.physicsBody.categoryBitMask = pipeCategory;
    pipe1.physicsBody.contactTestBitMask = birdCategory;
    
    [pipePair addChild:pipe1];
    
    [pipe2 setScale:2];
    pipe2.position = CGPointMake( 0, y + pipe1.size.height + pipeWidth);
    pipe2.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:pipe2.size];
    pipe2.physicsBody.dynamic = NO;
    pipe2.physicsBody.categoryBitMask = pipeCategory;
    pipe2.physicsBody.contactTestBitMask = birdCategory;
    [pipePair addChild:pipe2];
    
    SKNode* contactNode = [SKNode node];
    contactNode.position = CGPointMake( pipe1.size.width + _bird.size.width / 2, CGRectGetMidY( self.frame ) );
    contactNode.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(pipe2.size.width, self.frame.size.height)];
    contactNode.physicsBody.dynamic = NO;
    contactNode.physicsBody.categoryBitMask = scoreCategory;
    contactNode.physicsBody.contactTestBitMask = birdCategory;
    [pipePair addChild:contactNode];
    [pipePair runAction:_movePipesAndRemove];
    
    [_pipes addChild:pipePair];
        
    _currentPipeNo++;
            
        }else{
            NSLog(@"all pipes created");
        }
    }
}

-(void)resetScene {
    
    //create next level
    [self.thisdelegate updateLevelDG:_currentLevel];
    NSArray *thisLevelInformation = [_levelPipeGapArray objectAtIndex:_currentLevel];
    NSLog(@"Starting from level %ld using the following information %@", (long)_currentLevel, thisLevelInformation);
    [self.thisdelegate updateLevelDG:_currentLevel];
    
    NSNumber* levelSpeed = [_levelSpeedArray objectAtIndex:_currentLevel];
    CGFloat levelSpeedFloat = [levelSpeed floatValue];
    
    // Reset bird properties
    _bird.position = CGPointMake(self.frame.size.width / 4, CGRectGetMidY(self.frame));
    _bird.physicsBody.velocity = CGVectorMake( 0, 0 );
    _bird.physicsBody.collisionBitMask = worldCategory | pipeCategory;
    _bird.speed = 1.0;
    _bird.zRotation = 0.0;
    
    // Remove all existing pipes
    [_pipes removeAllChildren];
    
    // Reset _canRestart
    _canRestart = NO;
    
    // Restart animation
    _moving.speed = levelSpeedFloat;
    
    // Reset score
    _score = 0;
    
    if (_currentLevel == 1){
        _scoreLabelNode.text = [NSString stringWithFormat:@"Ready? Blow/Tap to go!"];
    }else{
        _scoreLabelNode.text = [NSString stringWithFormat:@"Take a break! Blow/tap to continue!"];
    }
    
    self.paused = true;
    _currentPipeNo = 0;
}

-(void)totalResetScene {
    // Reset bird properties
    _bird.position = CGPointMake(self.frame.size.width / 4, CGRectGetMidY(self.frame));
    _bird.physicsBody.velocity = CGVectorMake( 0, 0 );
    _bird.physicsBody.collisionBitMask = worldCategory | pipeCategory;
    _bird.speed = 1.0;
    _bird.zRotation = 0.0;
    
    // Remove all existing pipes
    [_pipes removeAllChildren];
    
    // Reset _canRestart
    _canRestart = NO;
    
    // Restart animation
    _moving.speed = 1;
    
    // Reset score
    _score = 0;
    _scoreLabelNode.text = [NSString stringWithFormat:@"%ld", (long)_score];
}

//DRAGON MOVEMENT AND COLLISION SETTINGS (TOUCH)///
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    if (firstBlow == true){
        _scoreLabelNode.text = [NSString stringWithFormat:@""];
        [self firstBlow];
        firstBlow = false;
    }
    
    if (self.paused == true){
        _scoreLabelNode.text = [NSString stringWithFormat:@""];
        self.paused = false;
        return;
    }
    
    if (_bird.physicsBody.affectedByGravity == YES){
    
        if( _moving.speed > 0 ) {
            _bird.physicsBody.velocity = CGVectorMake(0, 0);
            [_bird.physicsBody applyImpulse:CGVectorMake(0, 4)];
        } else if( _canRestart ) {
            [self resetScene];
        }
    }else if(_bird.physicsBody.affectedByGravity == NO){
        
        if( _moving.speed > 0 ) {
            _bird.physicsBody.velocity = CGVectorMake(0, 0);
            [_bird.physicsBody applyImpulse:CGVectorMake(0, -4)];
             _bird.speed = 1;
            
            dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.3);
            dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                _bird.physicsBody.velocity = CGVectorMake(0, 0);
                [_bird.physicsBody applyImpulse:CGVectorMake(0, 0)];
                _bird.speed = 1;
            });

        } else if( _canRestart ) {
            [self resetScene];
        }
    }
}

//DRAGON MOVEMENT AND COLLISION SETTINGS (BLOW)///

-(void)recievedBlow:(NSString*)type{
    
    NSLog(@"recieved blow");
   
    if (firstBlow == true){
        _scoreLabelNode.text = [NSString stringWithFormat:@""];
        [self firstBlow];
        firstBlow = false;
    }
    
    if (self.paused == true){
        _scoreLabelNode.text = [NSString stringWithFormat:@""];
        self.paused = false;
        return;
    }

    if (_bird.physicsBody.affectedByGravity == YES){
       // NSLog(@"blow recieved - affected by gravity");
        if( _moving.speed > 0 ) {
            _bird.physicsBody.velocity = CGVectorMake(0, 0);
            [_bird.physicsBody applyImpulse:CGVectorMake(0, 4)];
        } else if( _canRestart ) {
            [self resetScene];
        }
    }else if(_bird.physicsBody.affectedByGravity == NO){
        if ([type isEqualToString:@"Inhale"]){
            
         //   NSLog(@"Inhale impulse: gravity off");
            if( _moving.speed > 0 ) {
                _bird.physicsBody.velocity = CGVectorMake(0, 0);
                
                if(_reverseMode == NO){
                    [_bird.physicsBody applyImpulse:CGVectorMake(0, 4)];
                }else{
                    [_bird.physicsBody applyImpulse:CGVectorMake(0, -4)];
                }
                
                dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.3);
                dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                    _bird.physicsBody.velocity = CGVectorMake(0, 0);
                    [_bird.physicsBody applyImpulse:CGVectorMake(0, 0)];
                });
            } else if( _canRestart ) {
                [self resetScene];
            }
            
        }else if ([type isEqualToString:@"Exhale"]){
           // NSLog(@"Exhale impulse: gravity off");
            if( _moving.speed > 0 ) {
                _bird.physicsBody.velocity = CGVectorMake(0, 0);
                
                if(_reverseMode == NO){
                    [_bird.physicsBody applyImpulse:CGVectorMake(0, -4)];
                }else{
                    [_bird.physicsBody applyImpulse:CGVectorMake(0, 4)];
                }
                
                dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.3);
                dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                    _bird.physicsBody.velocity = CGVectorMake(0, 0);
                    [_bird.physicsBody applyImpulse:CGVectorMake(0, 0)];
                });
            } else if( _canRestart ) {
                [self resetScene];
            }
            
        }
    }
}

CGFloat clamp(CGFloat min, CGFloat max, CGFloat value) {
    if( value > max ) {
        return max;
    } else if( value < min ) {
        return min;
    } else {
        return value;
    }
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    if( _moving.speed > 0 ) {
        _bird.zRotation = clamp( -1, 0.5, _bird.physicsBody.velocity.dy * ( _bird.physicsBody.velocity.dy < 0 ? 0.003 : 0.001 ) );
    }
}

- (void)didBeginContact:(SKPhysicsContact *)contact {
   
    int sum = [[_levelPipeNoArray objectAtIndex: _currentLevel] intValue] ;

    int newsum = sum;
    NSNumber *noOfPipesInLevel = [NSNumber numberWithInt:newsum];
   
    //if moving
    if( _moving.speed > 0 ) {
        if( ( contact.bodyA.categoryBitMask & scoreCategory ) == scoreCategory || ( contact.bodyB.categoryBitMask & scoreCategory ) == scoreCategory ) {
    
            _score++;
             NSNumber *myNum = @(_score);
    
            if ([myNum intValue] == [noOfPipesInLevel intValue]){
                
                if (_currentLevel == (_totalLevelCount)){
                     _moving.speed = 0;
                    _scoreLabelNode.text = [NSString stringWithFormat:@"Game Over - You Win!"];
                     _currentLevel = 1;
                }else{
                    _moving.speed = 0;
                    _scoreLabelNode.text = [NSString stringWithFormat:@"Level %d Passed!", _currentLevel];
                    _currentLevel++;
                }
                    
                [[NSUserDefaults standardUserDefaults] setInteger:_currentLevel forKey:@"_currentLevel"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                [self runAction:[SKAction sequence:@[[SKAction repeatAction:[SKAction sequence:@[[SKAction runBlock:^{
                    self.backgroundColor = [SKColor greenColor];
                }], [SKAction waitForDuration:0.05], [SKAction runBlock:^{
                    self.backgroundColor = _skyColor;
                }], [SKAction waitForDuration:0.05]]] count:4], [SKAction runBlock:^{
                     _canRestart = YES;
                }]]] withKey:@"flash"];
            }else{
                //Add score to top
                 _scoreLabelNode.text = [NSString stringWithFormat:@"%@/%@", myNum, noOfPipesInLevel];
                [_scoreLabelNode runAction:[SKAction sequence:@[[SKAction scaleTo:1.5 duration:0.1], [SKAction scaleTo:1.0 duration:0.1]]]];
            }
        } else {
         
            _moving.speed = 0;
            
            _bird.physicsBody.collisionBitMask = worldCategory;
            
            [_bird runAction:[SKAction rotateByAngle:M_PI * _bird.position.y * 0.01 duration:_bird.position.y * 0.003] completion:^{
                _bird.speed = 0;
            }];
            
            // Flash background if contact is detected
            [self removeActionForKey:@"flash"];
            [self runAction:[SKAction sequence:@[[SKAction repeatAction:[SKAction sequence:@[[SKAction runBlock:^{
                self.backgroundColor = [SKColor redColor];
            }], [SKAction waitForDuration:0.05], [SKAction runBlock:^{
                self.backgroundColor = _skyColor;
            }], [SKAction waitForDuration:0.05]]] count:4], [SKAction runBlock:^{
                _canRestart = YES;
            }]]] withKey:@"flash"];
        }
    }
}

///BLUETOOTH////

-(void)btleManagerBreathStopped:(BTLEManager *)manager
{
    //Stop all interaction
    _disallowNextInhale = false;
    _disallowNextExhale = false;
    [self.thisdelegate  updateProgressBarDG:0];
}

-(void)btleManager:(BTLEManager*)manager inhaleWithValue:(float)percentOfmax{
    
    float calibratedInhaleVal = _currentInhaleValue*.5;
    //NSLog(@"old inhale val : %f", _currentInhaleValue);
    //NSLog(@"new inhale val : %f", calibratedInhaleVal);

    if (percentOfmax < _lowestInhaleValue){ _lowestInhaleValue = percentOfmax;}
    
    if (percentOfmax > (_lowestInhaleValue + 0.03)){ [self.thisdelegate  updateProgressBarDG:0];}
    
    //float calibratedExhaleVal = percentOfmax;
    if (percentOfmax <= calibratedInhaleVal){ _disallowNextInhale = false;}
    
    float percentageValue = percentOfmax/calibratedInhaleVal;
    
    NSLog(@"inhale percentageValue %f", percentageValue);
    //NSLog(@"inhale percentOfmax %f", percentOfmax);
    //NSLog(@"_currentInhaleValue %f", _currentInhaleValue);

    //if inhale is on, update progress bar
    if (_reverseMode == NO || _bird.physicsBody.affectedByGravity == NO){
        [self.thisdelegate updateProgressBarDG:percentageValue];
    }
    
    if (percentOfmax >= calibratedInhaleVal && _reverseMode == NO){     ///added && _disallowNextInhale == false
        _disallowNextInhale = true;
        [self recievedBlow:@"Inhale"];
    } else if (percentOfmax >= calibratedInhaleVal && _bird.physicsBody.affectedByGravity == NO){
        _disallowNextExhale = true;
        [self recievedBlow:@"Inhale"];
    }
}

-(void)btleManager:(BTLEManager*)manager exhaleWithValue:(float)percentOfmax
{
    float calibratedExhaleVal = _currentExhaleValue*.4;
   // NSLog(@"old exhale val : %f", _currentExhaleValue);
   // NSLog(@"new exhale val : %f", calibratedExhaleVal);
    
    if (percentOfmax < _lowestExhaleValue){ _lowestExhaleValue = percentOfmax; }
    
    if (percentOfmax < (_lowestExhaleValue + 0.01)){ [self.thisdelegate  updateProgressBarDG:0];}
    
    float percentageValue = percentOfmax/calibratedExhaleVal;
    
    if (_reverseMode == YES || _bird.physicsBody.affectedByGravity == NO){
        [self.thisdelegate  updateProgressBarDG:percentageValue];
    }
    
    if (percentOfmax <= calibratedExhaleVal){
        _disallowNextExhale = false;
    }
    
    NSLog(@"exhale percentageValue %f", percentageValue);
   // NSLog(@"exhale percentOfmax %f", percentOfmax);
    
    if (percentOfmax >= calibratedExhaleVal && _reverseMode == YES){
        _disallowNextExhale = true;
        [self recievedBlow:@"Exhale"];
    }else if (percentOfmax >= calibratedExhaleVal && _bird.physicsBody.affectedByGravity == NO){
        _disallowNextExhale = true;
        [self recievedBlow:@"Exhale"];
    }
}

-(void)btleManagerConnected:(BTLEManager*)manager{
    NSLog(@"CONNECTED!!!!!!!");
   [self passToBluetoothUI: YES];
}

-(void)btleManagerDisconnected:(BTLEManager*)manager{
   NSLog(@"DISCONNECTED!!!!!!!");
   [self passToBluetoothUI: NO];
}

-(void)passToBluetoothUI:(BOOL)value{
    [self.thisdelegate updateBluetoothButtonDG:value];
}

-(void)toggleAffectedByGravity{
    
    NSLog(@"bird affected by gravity?????? %d", _affectedByG);
    
    if (_affectedByG == true){
        _bird.physicsBody.affectedByGravity = NO;
        _affectedByG = false;
        NSLog(@"Bird no longer affected by gravity");
        [self.thisdelegate  updateGravityButtonDG: NO];
        _bird.speed =1;
    }else if (_affectedByG == false){
        _bird.physicsBody.affectedByGravity = YES;
        _affectedByG = true;

        [self.thisdelegate  updateGravityButtonDG: YES];
        NSLog(@"Bird affected by gravity");
        //_currentExhaleValue = 0.25;
        //_currentInhaleValue = 0.25;
        _bird.speed =1;
        //[self.thisdelegate  passbackSliderValueDG:_currentExhaleValue];
    }
}

-(void)toggleReverseMode{
    
    if (_reverseMode == YES){
        [self.thisdelegate  passbackSliderValueDG:_currentInhaleValue];
        [self.thisdelegate  updateReverseButtonDG:YES];
        NSLog(@"Reverse mode toggled to Inhale @ %f", _currentInhaleValue);
        _exhaleTriggerToggle = false;
        _reverseMode = NO;
        _bird.speed =1;
    }else if (_reverseMode == NO){
        [self.thisdelegate  passbackSliderValueDG:_currentExhaleValue];
        [self.thisdelegate  updateReverseButtonDG:NO];
        _exhaleTriggerToggle = true;
        _reverseMode = YES;
        NSLog(@"Reverse mode toggled to Exhale @ %f", _currentExhaleValue);
        _bird.speed =1;
    }
    
    [self.thisdelegate  updateProgressBarDG:0];
}

- (void)manualReset{
    _currentLevel = 1;
    _score = 0;
    [self resetScene];
    NSLog(@"Reset scene manually");
}

//SAVE THRESHOLD PREFERENCE//
- (void)moveSlider: (float) value{

    if (_exhaleTriggerToggle == true) {
        _currentExhaleValue = value;
        [self saveFloatToUserDefaults:_currentExhaleValue forKey:@"_currentExhaleValue"];
         NSLog(@"Current exhale value changed to %f", value);
    }else if (_exhaleTriggerToggle == false){
        _currentInhaleValue = value;
        [self saveFloatToUserDefaults:_currentInhaleValue forKey:@"_currentInhaleValue"];
         NSLog(@"Current inhale value changed to %f", value);
    }
    
     NSLog(@"saving value %f", value);
}

- (void) saveFloatToUserDefaults:(float)x forKey:(NSString *)key {
    
    NSLog(@"saving float %f", x);
    userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setFloat:x forKey:key];
    [userDefaults synchronize];
}


-(float) loadFloatFromUserDefaultsForKey:(NSString *)key {
    userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults floatForKey:key];
}

//DEFAULT LEVEL INFORMATION//
- (NSMutableArray*) getLevels{

    NSLog(@"Retrieving level information");
    NSMutableArray* levelArray = [[NSMutableArray alloc] init];
    NSArray* level0 = [NSArray arrayWithObjects: @"Nothing here", nil];
    NSArray* level1 = [NSArray arrayWithObjects: [SKColor colorWithRed:113.0/255.0 green:197.0/255.0 blue:207.0/255.0 alpha:1.0], @"dragon wings down", @"dragon wings up", @"tower (lower tube)-EXTENDED1", @"Flag (upper tube)", @"floor", @"skyline2", [NSNumber numberWithFloat: 1.0], nil];
    NSArray* level2 = [NSArray arrayWithObjects: [SKColor colorWithRed:113.0/255.0 green:197.0/255.0 blue:207.0/255.0 alpha:1.0], @"dragon wings down", @"dragon wings up", @"tower (lower tube)-EXTENDED1", @"Flag (upper tube)", @"floor", @"skyline2", [NSNumber numberWithFloat: 1.0], nil];
    NSArray* level3 = [NSArray arrayWithObjects: [SKColor colorWithRed:113.0/255.0 green:197.0/255.0 blue:207.0/255.0 alpha:1.0], @"dragon wings down", @"dragon wings up", @"tower (lower tube)-EXTENDED1", @"Flag (upper tube)", @"floor", @"skyline2", [NSNumber numberWithFloat: 1.0], nil];
    NSArray* level4 = [NSArray arrayWithObjects: [SKColor colorWithRed:113.0/255.0 green:197.0/255.0 blue:207.0/255.0 alpha:1.0], @"dragon wings down", @"dragon wings up", @"tower (lower tube)-EXTENDED1", @"Flag (upper tube)", @"floor", @"skyline2", [NSNumber numberWithFloat: 1.0], nil];
    NSArray* level5 = [NSArray arrayWithObjects: [SKColor colorWithRed:113.0/255.0 green:197.0/255.0 blue:207.0/255.0 alpha:1.0], @"dragon wings down", @"dragon wings up", @"tower (lower tube)-EXTENDED1", @"Flag (upper tube)", @"floor", @"skyline2", [NSNumber numberWithFloat: 1.0], nil];
   
    [levelArray addObject: level0];
    [levelArray addObject: level1];
    [levelArray addObject: level2];
    [levelArray addObject: level3];
    [levelArray addObject: level4];
    [levelArray addObject: level5];

    return levelArray;
}

- (NSMutableArray*) getPipeHeigthInformation: (int) level{
    
    NSMutableArray* pipeArray = [[NSMutableArray alloc] init];
    NSArray* level0 = [NSArray arrayWithObjects: @"Nothing here", nil];
    NSArray* level1 = [NSArray arrayWithObjects: [NSNumber numberWithFloat: .9],[NSNumber numberWithFloat: .6],[NSNumber numberWithFloat: .3], nil];
    NSArray* level2 = [NSArray arrayWithObjects: [NSNumber numberWithFloat: .3],[NSNumber numberWithFloat: .1],[NSNumber numberWithFloat: .9],[NSNumber numberWithFloat: .1],[NSNumber numberWithFloat: .9],[NSNumber numberWithFloat: .1],[NSNumber numberWithFloat: .9],[NSNumber numberWithFloat: .1],[NSNumber numberWithFloat: .9], [NSNumber numberWithFloat: .9], nil];
    NSArray* level3 = [NSArray arrayWithObjects: [NSNumber numberWithFloat: .3],[NSNumber numberWithFloat: .1],[NSNumber numberWithFloat: .9],[NSNumber numberWithFloat: .1],[NSNumber numberWithFloat: .9],[NSNumber numberWithFloat: .1],[NSNumber numberWithFloat: .9],[NSNumber numberWithFloat: .1],[NSNumber numberWithFloat: .9], [NSNumber numberWithFloat: .9],nil];
    NSArray* level4 = [NSArray arrayWithObjects: [NSNumber numberWithFloat: .3],[NSNumber numberWithFloat: .1],[NSNumber numberWithFloat: .9],[NSNumber numberWithFloat: .1],[NSNumber numberWithFloat: .9],[NSNumber numberWithFloat: .1],[NSNumber numberWithFloat: .9],[NSNumber numberWithFloat: .1],[NSNumber numberWithFloat: .9], [NSNumber numberWithFloat: .9],nil];
    NSArray* level5 = [NSArray arrayWithObjects: [NSNumber numberWithFloat: .3],[NSNumber numberWithFloat: .1],[NSNumber numberWithFloat: .9],[NSNumber numberWithFloat: .1],[NSNumber numberWithFloat: .9],[NSNumber numberWithFloat: .1],[NSNumber numberWithFloat: .9],[NSNumber numberWithFloat: .1],[NSNumber numberWithFloat: .9], [NSNumber numberWithFloat: .9],nil];
    
    [pipeArray addObject: level0];
    [pipeArray addObject: level1];
    [pipeArray addObject: level2];
    [pipeArray addObject: level3];
    [pipeArray addObject: level4];
    [pipeArray addObject: level5];
    
    NSMutableArray* pipeHeightInfo = [pipeArray objectAtIndex: level];
    
    return pipeHeightInfo;
}

- (NSMutableArray*) getPipeGapWidthInformation: (int) level{
    
    NSMutableArray* pipeArray = [[NSMutableArray alloc] init];
    NSArray* level0 = [NSArray arrayWithObjects: @"Nothing here", nil];
    NSArray* level1 = [NSArray arrayWithObjects: [NSNumber numberWithInteger: 100], [NSNumber numberWithInteger: 200], [NSNumber numberWithInteger: 100],nil];
    NSArray* level2 = [NSArray arrayWithObjects: [NSNumber numberWithInteger: 200], [NSNumber numberWithInteger: 100],[NSNumber numberWithInteger: 200],[NSNumber numberWithInteger: 110],[NSNumber numberWithInteger: 220],[NSNumber numberWithInteger: 100],[NSNumber numberWithInteger: 210],[NSNumber numberWithInteger: 110],[NSNumber numberWithInteger: 220],[NSNumber numberWithInteger: 100], nil];
    NSArray* level3 = [NSArray arrayWithObjects: [NSNumber numberWithInteger: 200], [NSNumber numberWithInteger: 100],[NSNumber numberWithInteger: 200],[NSNumber numberWithInteger: 110],[NSNumber numberWithInteger: 220],[NSNumber numberWithInteger: 100],[NSNumber numberWithInteger: 210],[NSNumber numberWithInteger: 110],[NSNumber numberWithInteger: 220],[NSNumber numberWithInteger: 100], nil];
    NSArray* level4 = [NSArray arrayWithObjects: [NSNumber numberWithInteger: 200], [NSNumber numberWithInteger: 100],[NSNumber numberWithInteger: 200],[NSNumber numberWithInteger: 110],[NSNumber numberWithInteger: 220],[NSNumber numberWithInteger: 100],[NSNumber numberWithInteger: 210],[NSNumber numberWithInteger: 110],[NSNumber numberWithInteger: 220],[NSNumber numberWithInteger: 100], nil];
    NSArray* level5 = [NSArray arrayWithObjects: [NSNumber numberWithInteger: 200], [NSNumber numberWithInteger: 100],[NSNumber numberWithInteger: 200],[NSNumber numberWithInteger: 110],[NSNumber numberWithInteger: 220],[NSNumber numberWithInteger: 100],[NSNumber numberWithInteger: 210],[NSNumber numberWithInteger: 110],[NSNumber numberWithInteger: 220],[NSNumber numberWithInteger: 100], nil];
    
    [pipeArray addObject: level0];
    [pipeArray addObject: level1];
    [pipeArray addObject: level2];
    [pipeArray addObject: level3];
    [pipeArray addObject: level4];
    [pipeArray addObject: level5];
    
    NSMutableArray* pipeGapWidthInfo = [pipeArray objectAtIndex: level];
    
    return pipeGapWidthInfo;
}

- (void)passLevelInformation: (int)totalLevelCount speed:(NSMutableArray*)speedArray gapInfo:(NSMutableArray*)gapArray positionInfo:(NSMutableArray*) positionArray{
    
   _totalLevelCount = totalLevelCount;
    _levelSpeedArray = speedArray;
    _levelPipeGapArray = gapArray;
    _levelPipePositionArray = positionArray;
}

@end
