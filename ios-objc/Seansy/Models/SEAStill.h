#import <NYTPhotoViewer/NYTPhoto.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface SEAStill : NSObject <NYTPhoto, NSCoding>

#pragma mark Properties

@property (nonatomic, readonly) NSURL *url;
@property (nonatomic, readonly) CGSize size;
@property (nonatomic, readonly) UIImage *image;

#pragma mark Methods

- (instancetype)initWithUrl:(NSURL *)url;
- (RACSignal *)getSize;
- (RACSignal *)getImage;

@end
