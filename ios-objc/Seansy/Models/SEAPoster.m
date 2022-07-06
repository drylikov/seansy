#import "SEAPoster.h"

#import <SDWebImage/UIImageView+WebCache.h>

static NSString *const kStillUrlKey = @"url";

@implementation SEAPoster

#pragma mark Initialization

- (instancetype)initWithUrl:(NSURL *)url {
  self = [super init];
  if (!self) {
    return nil;
  }

  _url = url;

  return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
  self = [super init];
  if (!self) {
    return nil;
  }

  _url = [decoder decodeObjectForKey:kStillUrlKey];

  return self;
}

- (RACSignal *)getImage {
  if (!self.url) {
    _image = [UIImage imageNamed:@"PosterPlaceholder"];
  }
  if (self.image) {
    return [RACSignal return :RACTuplePack(self.image, @YES)];
  }
  SDWebImageManager *manager = [SDWebImageManager sharedManager];
  return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    [manager downloadImageWithURL:self.url options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
      self->_image = image ? : [UIImage imageNamed:@"PosterPlaceholder"];
      [subscriber sendNext:RACTuplePack(self.image, @(cacheType != SDImageCacheTypeNone))];
      [subscriber sendCompleted];
    }];
    return nil;
  }] deliverOn:RACScheduler.mainThreadScheduler];
}

#pragma mark NYPhoto

- (NSAttributedString *)attributedCaptionSummary {
  return nil;
}

- (NSAttributedString *)attributedCaptionTitle {
  return nil;
}

- (NSAttributedString *)attributedCaptionCredit {
  return nil;
}

- (UIImage *)placeholderImage {
  return nil;
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.url forKey:kStillUrlKey];
}

@end
