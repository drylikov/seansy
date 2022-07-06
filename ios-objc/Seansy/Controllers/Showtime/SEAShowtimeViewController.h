#import "SEAShowtime.h"
#import <MessageUI/MessageUI.h>

@interface SEAShowtimeViewController : UIViewController <UIDocumentInteractionControllerDelegate, MFMessageComposeViewControllerDelegate>

- (instancetype)initWithShowtime:(SEAShowtime *)showtime;

@end
