#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>
#import "MyScene.h"


@interface ViewController : UIViewController <SKSceneDelegate, MySceneProtocol>{
   // MyScene * _thisScene;
}

@property (weak, nonatomic) IBOutlet UINavigationBar *myTopNavBar;
@property (weak, nonatomic) IBOutlet UIProgressView *breathProgress;
@property (weak, nonatomic) IBOutlet UISlider *thresholdSlider;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;
@property (weak, nonatomic) IBOutlet UIButton *levelDisplay;
@property (weak, nonatomic) IBOutlet UINavigationBar *bottomNavBar;
@property (weak, nonatomic) IBOutlet UIButton *gravityButton;
@property (weak, nonatomic) IBOutlet UIButton *reverseButton;
@property (weak, nonatomic) IBOutlet UIImageView *bluetoothStatus;
@property (nonatomic, retain) MyScene * thisScene;

- (IBAction)didReset:(id)sender;
- (IBAction)didToggleReverse:(id)sender;
- (IBAction)didToggleGravity:(id)sender;

@end


