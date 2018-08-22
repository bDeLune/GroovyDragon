#import <objc/message.h>
#import "ViewController.h"

@implementation ViewController

//MyScene * thisScene;
NSMutableArray *_localJSONInfo;
NSMutableArray *_levelSpeedArray;
NSMutableArray *_levelPipeGapArray;
NSMutableArray *_levelPipePositionArray;
NSNumber *_totalLevelCount;
bool _justloaded = true;
NSUserDefaults * userDefaults ;

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"ViewController loaded");
    SKView * skView = (SKView *)self.view;
    skView.showsFPS = NO;
    skView.showsNodeCount = NO;
    self.myTopNavBar.clipsToBounds = YES;

    NSLog(@"skView.bounds.size %@", self.view);
    printf("1.skView.bounds.size = %.2f, %.2f\n", skView.bounds.size.width, skView.bounds.size.height);
 
    NSLog(@"Splashing");
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:5]];
    
    UIApplication *application = [UIApplication sharedApplication];
    [application setStatusBarOrientation:UIInterfaceOrientationLandscapeRight
                                animated:YES];
  
    int currOrient = [[UIDevice currentDevice] orientation];
    CGSize mysize = skView.bounds.size;
    
    //load scene based on orientation
    if (currOrient == 1 || currOrient == 2){
         mysize = CGSizeMake(skView.bounds.size.height, skView.bounds.size.width);
        NSLog(@"inverting mysize");
        NSLog(@"curr width %f",mysize.width);
        NSLog(@"curr height %f",mysize.height );
    }
    
    //Present the scene.
    _thisScene = [MyScene sceneWithSize:mysize];
    _thisScene.scaleMode = SKSceneScaleModeAspectFill;
    _thisScene.name= @"MyGameScene";
    _thisScene.thisdelegate = self;
    
    float _currentInhaleValue = [self loadFloatFromUserDefaultsForKey:@"_currentInhaleValue"];
    
    if (_currentInhaleValue < 0.1){
        _currentInhaleValue = .15;
    }
    
    self.thresholdSlider.value = _currentInhaleValue;
  
    [skView presentScene:_thisScene];
    self.resetButton.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"ResetButton.png"]]];
    self.reverseButton.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"EXHALEButton.png"]]];
    self.gravityButton.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"GravityButton-ON.png"]]];
    self.breathProgress.progress = 0;
    [self.levelDisplay setTitle: [NSString stringWithFormat: @"Level: 1"] forState:UIControlStateNormal];
    
    //[self.myTopNavBar setBackgroundColor: [SKColor colorWithRed:113.0/255.0 green:197.0/255.0 blue:207.0/255.0 alpha:1.0]];
    //self.myTopNavBar.barTintColor = [SKColor colorWithRed:113.0/255.0 green:197.0/255.0 blue:207.0/255.0 alpha:1.0];
    [self.myTopNavBar setBackgroundImage:[UIImage new]
                             forBarMetrics:UIBarMetricsDefault];
    self.myTopNavBar.shadowImage = [UIImage new];
    self.myTopNavBar.translucent = YES;
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

- (NSUInteger)supportedInterfaceOrientations
{
   if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    NSLog(@"UIInterfaceOrientationMaskAllButUpsideDown %lu", (unsigned long)UIInterfaceOrientationMaskAllButUpsideDown);
        return UIInterfaceOrientationMaskAllButUpsideDown;
            } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO; //ADDED
}

-(BOOL)shouldAutomaticallyForwardRotationMethods:(UIInterfaceOrientation)toInterfaceOrientation{
    return YES;
}

-(BOOL)shouldAutorotate
{
    return YES;
}

- (IBAction)sliderChanged:(id)sender {
    UISlider *slider = (UISlider *)sender;
    [_thisScene moveSlider: [slider value]];
}

- (IBAction)didReset:(id)sender {
   [_thisScene manualReset];
}

- (IBAction)didToggleGravity:(id)sender {
   [_thisScene toggleAffectedByGravity];
}

- (IBAction)didToggleReverse:(id)sender {
    NSLog(@"trying to toggle reverse mode");
    [_thisScene toggleReverseMode];
}

- (void)passbackSliderValueDG:(float)value{
    self.thresholdSlider.value = value;
    NSLog(@"THRESHOLD SLIDER value should have been changed to %f", value);
}

- (void)changeThresholdSliderValue:(float)value{
    self.thresholdSlider.value = value;
    NSLog(@"THRESHOLD SLIDER value should have been changed to %f", value);
}

- (void)updateReverseButtonDG:(BOOL)value{
    
    if (value == YES){
        self.reverseButton.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"INHALEButton.png"]]];
    }else if (value == NO){
       self.reverseButton.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"EXHALEButton.png"]]];
    }
}

- (void)updateGravityButtonDG:(BOOL)value{
    
    if (value == NO){
       self.gravityButton.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"GravityButton-OFF.png"]]];
        NSLog(@"SUCCESS - GRAVITY SET TO OFF");
    }else if (value == YES){
       self.gravityButton.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"GravityButton-ON.png"]]];
        NSLog(@"SUCCESS - GRAVITY SET TO ON");
    }
}

- (void)updateBluetoothButtonDG:(BOOL)value{
    if (value == YES){
        [self.bluetoothStatus setImage:[UIImage imageNamed:@"BlueToothConnected.png"]];
    }else if (value == NO){
         [self.bluetoothStatus setImage:[UIImage imageNamed:@"BlueToothDisconnected.png"]];
    }
}

- (void)updateProgressBarDG:(float)value{
    self.breathProgress.progress = value;
}

- (void)updateLevelDG:(int)value{
    NSLog(@"Update level dg to val %d", value);
    [self.levelDisplay setTitle: [NSString stringWithFormat: @"Level: %d", value] forState:UIControlStateNormal];
}

@end
