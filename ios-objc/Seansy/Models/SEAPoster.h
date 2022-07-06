#import <NYTPhotoViewer/NYTPhoto.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface SEAPoster : NSObject <NYTPhoto, NSCoding>

#pragma mark Properties

@property (nonatomic, readonly) NSURL *url;
@property (nonatomic, readonly) UIImage *image;

#pragma mark Methods

- (instancetype)initWithUrl:(NSURL *)url;
- (RACSignal *)getImage;

@end
