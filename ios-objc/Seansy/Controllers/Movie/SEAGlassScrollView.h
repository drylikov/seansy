//
//  Copyright (c) 2013 Byte, 2014 Ayan Yenbekbay.
//

#import "SEAMovie.h"
#import "SEAMovieDetailsInfoView.h"
#import "SEAMovieShowtimesView.h"
#import "UIColor+SEAHelpers.h"
#import "UIImage+SEAHelpers.h"

@protocol SEAGlassScrollViewDelegate <NSObject>
@required
- (void)playTrailerForMovie:(SEAMovie *)movie;
- (CGFloat)topHeight;
@end

@interface SEAGlassScrollView : UIView <UIScrollViewDelegate>

#pragma mark Properties

@property (nonatomic) NSUInteger currentPageIndex;
@property (weak, nonatomic) id<SEAGlassScrollViewDelegate> delegate;
@property (weak, nonatomic) SEAMovie *movie;

#pragma mark Methods

- (instancetype)initWithFrame:(CGRect)frame infoView:(SEAMovieDetailsInfoView *)infoView showtimesView:(SEAMovieShowtimesView *)showtimesView;
- (void)setUpBackdropProgressView;

@end
