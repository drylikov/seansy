#import "SEAStill.h"

#import <Ottran/Ottran.h>
#import <SDWebImage/UIImageView+WebCache.h>

static NSString *const kStillUrlKey = @"url";
static NSString *const kStillSizeKey = @"size";

@interface SEAStill ()

@property (nonatomic) Ottran *scouter;

@end

@implementation SEAStill

#pragma mark Initialization

- (instancetype)initWithUrl:(NSURL *)url {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.scouter = [Ottran new];
  _url = url;
  _size = CGSizeZero;

  return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
  self = [super init];
  if (!self) {
    return nil;
  }

  _url = [decoder decodeObjectForKey:kStillUrlKey];
  _size = [[decoder decodeObjectForKey:kStillSizeKey] CGSizeValue];

  return self;
}

#pragma mark Public

- (RACSignal *)getSize {
  if (!CGSizeEqualToSize(CGSizeZero, self.size)) {
    return [RACSignal empty];
  }
  SDWebImageManager *manager = [SDWebImageManager sharedManager];
  if ([manager diskImageExistsForURL:self.url]) {
    return [self getImage];
  }
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    [self.scouter scoutImageWithURI:[self.url absoluteString] andOttranCompletion:^(NSError *error, CGSize size, OttranImageType imageType) {
      if (error) {
        DDLogError(@"%@", error);
      } else {
        self->_size = size;
      }
      [subscriber sendNext:[NSValue valueWithCGSize:size]];
      [subscriber sendCompleted];
    }];
    return nil;
  }];
}

- (RACSignal *)getImage {
  if (self.image) {
    return [RACSignal return :RACTuplePack(self.image, @YES)];
  }
  SDWebImageManager *manager = [SDWebImageManager sharedManager];
  return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    [manager downloadImageWithURL:self.url options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
      self->_image = image;
      self->_size = image.size;
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
  [coder encodeObject:[NSValue valueWithCGSize:self.size] forKey:kStillSizeKey];
}

@end
