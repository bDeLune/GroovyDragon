#import "BTLEManager.h"
#import <SpriteKit/SpriteKit.h>

@protocol MySceneProtocol <NSObject>
- (void)passbackSliderValueDG:(float)value;
- (void)updateProgressBarDG: (float)value;
- (void)updateReverseButtonDG: (BOOL)value;
- (void)updateGravityButtonDG:(BOOL)value;
- (void)updateBluetoothButtonDG:(BOOL)value;
- (void)updateLevelDG:(int)value;
- (void)testDelegate;
- (void)changeThresholdSliderValue:(float)value;
@end

@interface MyScene : SKScene <SKPhysicsContactDelegate, BTLEManagerDelegate>

@property(nonatomic,strong)BTLEManager  *btleMager;
@property(nonatomic,strong)id<MySceneProtocol> thisdelegate;

- (void)toggleAffectedByGravity;
- (void)toggleReverseMode;
- (void)changeThresholdSliderValue:(float)value;
- (void)manualReset;
- (void)moveSlider: (float) value;
- (void)passToBluetoothUI:(BOOL)value;
- (void)passLevelInformation: (int )totalLevelCount speed:(NSMutableArray*)speedArray gapInfo:(NSMutableArray*)gapArray positionInfo:(NSMutableArray*) positionArray;
@end




