@protocol SEAPromptViewDelegate <NSObject>
@required
- (void)promptForReview;
- (void)promptForFeedback;
- (void)promptClose;
@end

@interface SEAPromptView : UIView

#pragma mark Properties

@property (weak) id<SEAPromptViewDelegate> delegate;

#pragma mark Methods

+ (BOOL)hasHadInteractionForCurrentVersion;
+ (void)setHasHadInteractionForCurrentVersion;

@end
