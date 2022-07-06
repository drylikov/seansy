#import "SEAWalkthroughViewController.h"

#import "AYMacros.h"
#import "SEAConstants.h"
#import "SEAOnboardingContentViewController.h"
#import "SEASplashView.h"
#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"

static NSString *const kContentTitleKey = @"title";
static NSString *const kContentSubtitleKey = @"subtitle";
static NSString *const kContentImageKey = @"image";
static NSString *const kContentLightBackgroundKey = @"lightBackground";

static NSString *const kSeenWidgetFeatureKey = @"seenWidgetFeature";
static NSString *const kSeenSpotlightFeatureKey = @"seenSpotlightFeature";

@implementation SEAWalkthroughViewController

#pragma mark Initialization

- (instancetype)initWithCompletionHandler:(dispatch_block_t)completionHandler {
  return [self initWithCompletionHandler:completionHandler replay:NO];
}

- (instancetype)initWithCompletionHandler:(dispatch_block_t)completionHandler replay:(BOOL)replay {
  self = [super initWithContents:nil];
  if (!self) {
    return nil;
  }

  NSMutableArray *content = [NSMutableArray new];
  if (![[NSUserDefaults standardUserDefaults] boolForKey:kSeenWalkthroughKey] || replay) {
    [content addObject:@{
       kContentTitleKey : NSLocalizedString(@"Добро пожаловать!", nil),
       kContentSubtitleKey : NSLocalizedString(@"Для более продуктивной работы с приложением посмотрите, пожалуйста, очень краткую инструкцию по применению.\n←", nil),
       kContentImageKey : [UIImage imageNamed:@"PopcornIconBig"],
       kContentLightBackgroundKey : @YES
     }];
    [content addObject:@{
      kContentTitleKey: NSLocalizedString(@"На экране сеансов", nil),
      kContentSubtitleKey: NSLocalizedString(@"Нажмите на время сеанса, чтобы увидеть дополнительную информацию. Затем нажмите на появившееся всплывающее окно, чтобы поделиться деталями сеанса.", nil),
      kContentImageKey: IS_IPHONE_6P ? [UIImage imageNamed : @"WalkthroughScreenshot1~5.5"]:[UIImage imageNamed:@"WalkthroughScreenshot1"],
      kContentLightBackgroundKey: @NO
    }];
    [content addObject:@{
      kContentTitleKey: NSLocalizedString(@"Любимые кинотеатры", nil),
      kContentSubtitleKey: NSLocalizedString(@"Чтобы добавить кинотеатр в избранное, проведите пальцем по выбранному кинотеатру слева направо.", nil),
      kContentImageKey: IS_IPHONE_6P ? [UIImage imageNamed : @"WalkthroughScreenshot2~5.5"]:[UIImage imageNamed:@"WalkthroughScreenshot2"],
      kContentLightBackgroundKey: @NO
    }];
  } else {
    self.titleText = NSLocalizedString(@"Что нового?", nil);
  }
  if ((![[NSUserDefaults standardUserDefaults] boolForKey:kSeenSpotlightFeatureKey] || replay) && SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
    [content addObject:@{
       kContentTitleKey: NSLocalizedString(@"Поиск через Spotlight", nil),
       kContentSubtitleKey: NSLocalizedString(@"Ищите фильмы через Spotlight, просто введя \"кино\" или название фильма в строку поиска.", nil),
       kContentImageKey: [UIImage imageNamed : @"WalkthroughScreenshot4"],
       kContentLightBackgroundKey: @NO
    }];
    completionHandler = ^{
      [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kSeenSpotlightFeatureKey];
      if (completionHandler) {
        completionHandler();
      }
    };
  }
  if ((![[NSUserDefaults standardUserDefaults] boolForKey:kSeenWidgetFeatureKey] || replay) && SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
    [content addObject:@{
       kContentTitleKey: NSLocalizedString(@"Виджет в центре уведомлений", nil),
       kContentSubtitleKey: NSLocalizedString(@"Быстро узнайте, какие фильмы идут в кино, и перейдите к приложению нажав на выбранный фильм.", nil),
       kContentImageKey: [UIImage imageNamed : @"WalkthroughScreenshot3"],
       kContentLightBackgroundKey: @NO
    }];
    completionHandler = ^{
      [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kSeenWidgetFeatureKey];
      if (completionHandler) {
        completionHandler();
      }
    };
  }
  
  NSMutableArray *pages = [NSMutableArray new];
  for (NSDictionary *dictionary in content) {
    SEAOnboardingContentViewController *page = [[SEAOnboardingContentViewController alloc] initWithTitleText:dictionary[kContentTitleKey] subtitleText:dictionary[kContentSubtitleKey] image:dictionary[kContentImageKey] showButton:dictionary == [content lastObject]];
    page.titleFontSize = [UIFont walkthroughTitleFontSize];
    page.subtitleFontSize = [UIFont mediumTextFontSize];
    BOOL lightBackground = [dictionary[kContentLightBackgroundKey] boolValue];
    page.backgroundColor = lightBackground ? [UIColor colorWithHexString:kAmberColor] : [UIColor colorWithHexString:kOnyxColor];
    page.titleColor =  page.subtitleColor =  page.continueButtonColor = lightBackground ? [UIColor colorWithHexString:kOnyxColor] : [UIColor whiteColor];
    page.newFeature = !!self.titleText;
    page.viewWillAppearBlock = ^{
      [[UIApplication sharedApplication] setStatusBarStyle:lightBackground ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent animated:NO];
      self.backgroundColor = lightBackground ? [UIColor colorWithHexString:kAmberColor] : [UIColor colorWithHexString:kOnyxColor];
      self.pageControlColor = lightBackground ? [UIColor clearColor] : [UIColor colorWithWhite:0 alpha:0.1f];
      self.pageIndicatorTintColor = lightBackground ? [[UIColor colorWithHexString:kOnyxColor] colorWithAlphaComponent:0.5f] : [UIColor colorWithWhite:1 alpha:0.5f];
      self.currentPageIndicatorTintColor = lightBackground ? [UIColor colorWithHexString:kOnyxColor] : [UIColor whiteColor];
      self.skipButtonColor = self.titleLabelColor = lightBackground ? [UIColor colorWithHexString:kOnyxColor] : [UIColor whiteColor];
    };
    [pages addObject:page];
  }

  self.viewControllers = pages;

  self.shouldFadeTransitions = NO;
  self.allowSkipping = YES;
  self.skipButtonText = NSLocalizedString(@"Пропустить", nil);
  self.skipHandler = completionHandler;

  return self;
}

#pragma mark Public

+ (BOOL)hasUnseenNewFeatures {
  return (![[NSUserDefaults standardUserDefaults] boolForKey:kSeenSpotlightFeatureKey] && SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) || (![[NSUserDefaults standardUserDefaults] boolForKey:kSeenWidgetFeatureKey] && SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"));
}

@end
