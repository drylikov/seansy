#import "SEATheatre.h"
#import <Mapbox-iOS-SDK/Mapbox.h>

@interface SEAMapViewController : UIViewController <RMMapViewDelegate>

#pragma mark Methods

+ (SEAMapViewController *)sharedInstance;

#pragma mark Properties

/**
 * The theatre the map will me centered at. Also, for this theatre a callout will be displayed.
 */
@property (weak, nonatomic) SEATheatre *selectedTheatre;

@end
