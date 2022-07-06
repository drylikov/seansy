@interface SEAAppCoordinator : NSObject

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController;
- (void)start;
- (void)restore;
- (BOOL)handleUserActivity:(NSUserActivity *)userActivity;
- (BOOL)handleOpenURL:(NSURL *)url;

@end
