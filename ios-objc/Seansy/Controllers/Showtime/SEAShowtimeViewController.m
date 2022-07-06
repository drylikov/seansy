#import "SEAShowtimeViewController.h"

#import "SEAActionSheet.h"
#import "SEAAlertView.h"
#import "SEAAppDelegate.h"
#import "SEAConstants.h"
#import "SEADataManager.h"
#import "SEAMovie.h"
#import "SEAShowtimeInfoView.h"
#import "SEATheatre.h"
#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"
#import "UIImage+SEAHelpers.h"
#import "UIView+AYUtils.h"
#import <Analytics/Analytics.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <SDWebImage/UIImageView+WebCache.h>

UIEdgeInsets const kShowtimeViewPadding = {
  10, 10, 10, 10
};
CGFloat const kShowtimeViewSharingButtonHeight = 40;
CGFloat const kShowtimeViewSharingButtonSpacing = 10;
CGFloat const kShowtimeViewSharingButtonIconMargin = 10;
CGFloat const kShowtimeViewBackgroundViewAlpha = 0.4f;
CGFloat const kShowtimeViewDismissButtonHeight = 50;
CGFloat const kShowtimeViewSharingViewWidth = 350;
UIEdgeInsets const kShowtimeViewSharingViewPadding = {
  10, 10, 20, 10
};

@interface SEAShowtimeViewController ()

@property (nonatomic) SEAShowtimeInfoView *showtimeInfoView;
@property (nonatomic) UIButton *dismissButton;
@property (nonatomic) UIButton *imessageButton;
@property (nonatomic) UIButton *whatsappButton;
@property (nonatomic) UIDocumentInteractionController *documentInteractionController;
@property (nonatomic) UIImageView *backgroundView;
@property (nonatomic) UIView *dismissButtonSeparator;
@property (nonatomic) UIView *sharingView;
@property (weak, nonatomic) SEAMovie *movie;
@property (weak, nonatomic) SEAShowtime *showtime;
@property (weak, nonatomic) SEATheatre *theatre;

@end

@implementation SEAShowtimeViewController

#pragma mark Initialization

- (instancetype)initWithShowtime:(SEAShowtime *)showtime {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.showtime = showtime;
  self.theatre = [[SEADataManager sharedInstance] theatreForId:self.showtime.theatreId];
  self.movie = [[SEADataManager sharedInstance] movieForId:self.showtime.movieId];

  return self;
}

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[SEGAnalytics sharedAnalytics] screen:@"Showtime" properties:@{
     @"time" : [self.showtime timeString],
     @"movie" : self.movie.title,
     @"cinema" : self.theatre.name
   }];
  self.automaticallyAdjustsScrollViewInsets = NO;
  self.view.backgroundColor = [UIColor colorWithHexString:kOnyxColor];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self setUpView];
}

#pragma mark Getters

- (UIView *)sharingView {
  if (_sharingView) {
    return _sharingView;
  }

  _sharingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kShowtimeViewSharingViewWidth, 0)];
  _sharingView.backgroundColor = [UIColor blackColor];
  UIImageView *backgroundView = [[UIImageView alloc] initWithImage:self.backgroundView.image];
  backgroundView.contentMode = UIViewContentModeScaleAspectFill;
  backgroundView.alpha = kShowtimeViewBackgroundViewAlpha;

  SEAShowtimeInfoView *showtimeInfoView = [[SEAShowtimeInfoView alloc] initWithFrame:CGRectMake(0, 0, (kShowtimeViewSharingViewWidth - kShowtimeViewSharingViewPadding.left - kShowtimeViewSharingViewPadding.right), 0) showtime:self.showtime];

  self.sharingView.height = showtimeInfoView.height + kShowtimeViewSharingViewPadding.top + kShowtimeViewSharingViewPadding.bottom;
  backgroundView.frame = self.sharingView.bounds;
  showtimeInfoView.top = kShowtimeViewSharingViewPadding.top;
  showtimeInfoView.left = kShowtimeViewSharingViewPadding.left;

  [_sharingView addSubview:backgroundView];
  [_sharingView addSubview:showtimeInfoView];

  return _sharingView;
}

#pragma mark Private

- (void)setUpView {
  if (!self.showtimeInfoView) {
    self.imessageButton = [[UIButton alloc] initWithFrame:CGRectMake(kShowtimeViewPadding.left, CGRectGetHeight([UIApplication sharedApplication].statusBarFrame) + kShowtimeViewPadding.top, (self.view.width - kShowtimeViewPadding.left - kShowtimeViewPadding.right - kShowtimeViewSharingButtonSpacing) / 2, kShowtimeViewSharingButtonHeight)];
    [self.imessageButton setImage:[[UIImage imageNamed:@"MessageIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.imessageButton addTarget:self action:@selector(imessage) forControlEvents:UIControlEventTouchUpInside];
    [self.imessageButton setTitle:NSLocalizedString(@"Сообщение", nil) forState:UIControlStateNormal];

    self.whatsappButton = [[UIButton alloc] initWithFrame:CGRectMake(self.imessageButton.right + kShowtimeViewSharingButtonSpacing, CGRectGetHeight([UIApplication sharedApplication].statusBarFrame) + kShowtimeViewPadding.top, self.imessageButton.width, self.imessageButton.height)];
    [self.whatsappButton setImage:[[UIImage imageNamed:@"WhatsAppIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.whatsappButton addTarget:self action:@selector(whatsapp) forControlEvents:UIControlEventTouchUpInside];
    [self.whatsappButton setTitle:NSLocalizedString(@"WhatsApp", nil) forState:UIControlStateNormal];

    for (UIButton *button in @[self.imessageButton, self.whatsappButton]) {
      button.adjustsImageWhenHighlighted = NO;
      button.tintColor = [UIColor colorWithHexString:kAmberColor];
      [button setTitleColor:[UIColor colorWithHexString:kAmberColor] forState:UIControlStateNormal];
      button.titleLabel.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
      button.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, kShowtimeViewSharingButtonIconMargin);
      button.titleEdgeInsets = UIEdgeInsetsMake(0, kShowtimeViewSharingButtonIconMargin, 0, 0);
      button.layer.borderColor = [UIColor colorWithHexString:kAmberColor].CGColor;
      button.layer.borderWidth = 1;
      button.layer.cornerRadius = button.height / 2;
      button.clipsToBounds = YES;
      [button setBackgroundImage:[UIImage imageWithColor:[[UIColor colorWithHexString:kAmberColor] colorWithAlphaComponent:0.1f]] forState:UIControlStateHighlighted];
    }

    self.backgroundView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    self.backgroundView.alpha = kShowtimeViewBackgroundViewAlpha;
    [self.movie.backdrop getOriginalImageWithProgressBlock:nil
     completionBlock:^(UIImage *originalImage, BOOL fromCache) {
      if (originalImage) {
        self.backgroundView.image = originalImage;
      }
    }];

    self.showtimeInfoView = [[SEAShowtimeInfoView alloc] initWithFrame:CGRectMake(0, 0, self.view.width - kShowtimeViewPadding.left - kShowtimeViewPadding.right, 0) showtime:self.showtime];
    self.showtimeInfoView.center = CGPointMake(self.view.centerX, self.view.centerY + CGRectGetHeight([UIApplication sharedApplication].statusBarFrame) / 2);

    self.dismissButtonSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.height - kShowtimeViewDismissButtonHeight, self.view.width, 1 / [UIScreen mainScreen].scale)];
    self.dismissButtonSeparator.backgroundColor = [UIColor colorWithWhite:1 alpha:0.25f];

    self.dismissButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.dismissButtonSeparator.bottom, self.view.width, kShowtimeViewDismissButtonHeight)];
    self.dismissButton.titleLabel.font = [UIFont regularFontWithSize:[UIFont largeTextFontSize]];
    [self.dismissButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self.dismissButton setTitle:NSLocalizedString(@"Назад", nil) forState:UIControlStateNormal];
    [self.dismissButton setTitleColor:[UIColor colorWithHexString:kAmberColor] forState:UIControlStateNormal];
    [self.dismissButton setBackgroundImage:[UIImage imageWithColor:[[UIColor colorWithHexString:kAmberColor] colorWithAlphaComponent:0.1f]] forState:UIControlStateHighlighted];

    [self.view addSubview:self.backgroundView];
    [self.view addSubview:self.showtimeInfoView];
    [self.view addSubview:self.imessageButton];
    [self.view addSubview:self.whatsappButton];
    [self.view addSubview:self.dismissButtonSeparator];
    [self.view addSubview:self.dismissButton];

    self.view.clipsToBounds = YES;
  }
}

- (void)whatsapp {
  if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"whatsapp://app"]]) {
    SEAActionSheet *actionSheet = [[SEAActionSheet alloc] initWithTitle:NSLocalizedString(@"Поделиться через WhatsApp", nil)];
    actionSheet.cancelButtonTitle = NSLocalizedString(@"Отмена", nil);

    [actionSheet addButtonWithTitle:NSLocalizedString(@"Текст", nil) image:[UIImage imageNamed:@"NoteIcon"] handler:^{
      NSString *message = [NSString stringWithFormat:@"Пойдем?\n\"%@\" в %@ в %@", self.movie.title, [self.showtime timeString], self.theatre.name];
      NSString *escapedMessage = [message stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
      NSURL *whatsappURL = [NSURL URLWithString:[NSString stringWithFormat:@"whatsapp://send?text=%@", escapedMessage]];
      [[UIApplication sharedApplication] openURL:whatsappURL];
    }];

    [actionSheet addButtonWithTitle:NSLocalizedString(@"Изображение", nil) image:[UIImage imageNamed:@"PhotoIcon"] handler:^{
      UIImage *image = [UIImage convertViewToImage:self.sharingView];
      NSString *imagePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/tempImage.wai"];
      [UIImageJPEGRepresentation(image, 1) writeToFile:imagePath atomically:YES];

      self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:imagePath]];
      self.documentInteractionController.UTI = @"net.whatsapp.image";
      self.documentInteractionController.delegate = self;
      [self.documentInteractionController presentOpenInMenuFromRect:CGRectZero inView:self.view animated:YES];
    }];
    [actionSheet show];
  } else {
    NSURL *appStoreURL = [NSURL URLWithString:@"https://itunes.apple.com/kz/app/whatsapp-messenger/id310633997?mt=8"];
    [[UIApplication sharedApplication] openURL:appStoreURL];
  }
}

- (void)imessage {
  if ([MFMessageComposeViewController canSendText]) {
    MFMessageComposeViewController *picker = [MFMessageComposeViewController  new];
    picker.messageComposeDelegate = self;

    if ([MFMessageComposeViewController canSendAttachments]) {
      picker.body = @"Пойдем?";
      UIImage *image = [UIImage convertViewToImage:self.sharingView];
      NSData *imageData = UIImagePNGRepresentation(image);
      [picker addAttachmentData:imageData typeIdentifier:(NSString *)kUTTypePNG filename:@"tempImage.png"];
    } else {
      picker.body = [NSString stringWithFormat:@"Пойдем?\n\"%@\" в %@ в %@", self.movie.title, [self.showtime timeString], self.theatre.name];
    }
    [self presentViewController:picker animated:YES completion:nil];
  } else {
    NSString *title = NSLocalizedString(@"Ошибка", nil);
    NSString *body = NSLocalizedString(@"Кажется, у вас выключены сообщения.", nil);
    SEAAlertView *alertView = [[SEAAlertView alloc] initWithTitle:title body:body];
    [alertView show];
  }
}

#pragma mark Helpers

- (void)dismiss {
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UIDocumentInteractionControllerDelegate

- (void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application {
  [[SEGAnalytics sharedAnalytics] track:@"Shared" properties:@{
     @"through" : @"whatsapp",
     @"movie" : self.movie.title,
     @"cinema" : self.theatre.name
   }];
}

#pragma mark MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
  [self dismissViewControllerAnimated:YES completion:nil];
  if (result == MessageComposeResultSent) {
    [[SEGAnalytics sharedAnalytics] track:@"Shared" properties:@{
       @"through" : @"imessage",
       @"movie" : self.movie.title,
       @"cinema" : self.theatre.name
     }];
  }
}

@end
