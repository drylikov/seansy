@interface SEAAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic) UIWindow *window;
@property (nonatomic) UINavigationController *navigationController;
@property (nonatomic) UIInterfaceOrientationMask orientationMask;

/**
 *  Disables autorotation by setting orientation mask to the current orientation.
 */
- (void)blockOrientation;
/**
 *  Enables autorotation and restores orientation mask to the default.
 */
- (void)restoreOrientation;

@end
