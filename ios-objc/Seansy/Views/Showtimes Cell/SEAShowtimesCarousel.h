#import "SEAConstants.h"
#import "SEAMovie.h"
#import "SEATheatre.h"
#import "SEAShowtimesCell.h"

@interface SEAShowtimesCarousel : SEAShowtimesCell

@property (nonatomic) SEAShowtimesLayout currentLayout;
@property (weak, nonatomic) SEAMovie *movie;
@property (weak, nonatomic) SEATheatre *theatre;

@end
