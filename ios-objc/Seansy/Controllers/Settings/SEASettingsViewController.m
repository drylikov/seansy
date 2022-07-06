#import "SEASettingsViewController.h"

#import "AYAppStore.h"
#import "AYFeedback.h"
#import "SEAActivityViewController.h"
#import "SEAAlertView.h"
#import "SEAAppDelegate.h"
#import "SEAConstants.h"
#import "SEAMainTabBarController.h"
#import "SEAPromptView.h"
#import "SEASettingsViewTableCell.h"
#import "SEAWalkthroughViewController.h"
#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"
#import "UILabel+SEAHelpers.h"
#import "UIView+AYUtils.h"
#import <MessageUI/MessageUI.h>
#import <SDWebImage/SDImageCache.h>

static UIEdgeInsets const kSettingsViewPadding = {
  10, 10, 10, 10
};
static CGFloat const kSettingsViewCellLabelSpacing = 10;
static CGFloat const kSettingsViewCellIconMargin = 15;

@interface SEASettingsViewController () <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic) UITableView *tableView;
@property (nonatomic) MFMailComposeViewController *mailComposeViewController;

@end

@implementation SEASettingsViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor colorWithHexString:kOnyxColor];
  [self setUpNavigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.tableView reloadData];
}

#pragma mark Getters

- (UITableView *)tableView {
  if (_tableView) {
    return _tableView;
  }

  _tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
  _tableView.dataSource = self;
  _tableView.delegate = self;
  _tableView.backgroundColor = [UIColor colorWithHexString:kOnyxColor];
  _tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
  _tableView.separatorColor = [UIColor colorWithWhite:1 alpha:0.15f];
  _tableView.tableFooterView = [UIView new];
  _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [_tableView registerClass:[SEASettingsViewTableCell class] forCellReuseIdentifier:NSStringFromClass([SEASettingsViewTableCell class])];
  [self.view addSubview:_tableView];

  return _tableView;
}

#pragma mark Private

- (void)setUpNavigationBar {
  UIButton *walkthroughButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
  [walkthroughButton setBackgroundImage:[[UIImage imageNamed:@"QuestionIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
  [walkthroughButton addTarget:self action:@selector(startWalkthrough) forControlEvents:UIControlEventTouchUpInside];
  UIBarButtonItem *locationButtonItem = [[UIBarButtonItem alloc] initWithCustomView:walkthroughButton];
  self.navigationItem.rightBarButtonItem = locationButtonItem;
}

- (void)startWalkthrough {
  SEAWalkthroughViewController *walkthroughViewController = [[SEAWalkthroughViewController alloc] initWithCompletionHandler:^{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    [self dismissViewControllerAnimated:YES completion:nil];
  } replay:YES];
  [self presentViewController:walkthroughViewController animated:YES completion:nil];
}

- (void)showPercentRating:(UISwitch *)sender {
  [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] setBool:[sender isOn] forKey:kShowPercentRatingsKey];
  [[SEAMainTabBarController sharedInstance] refreshNowPlayingMovies];
}

- (void)saveFilters:(UISwitch *)sender {
  [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] setBool:[sender isOn] forKey:kSaveFiltersKey];
}

- (void)parallax:(UISwitch *)sender {
  [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] setBool:[sender isOn] forKey:kParallaxKey];
  [[SEAMainTabBarController sharedInstance] refreshNews];
}

- (void)clearCache {
  [[SDImageCache sharedImageCache] clearMemory];
  [[SDImageCache sharedImageCache] clearDisk];
}

- (void)recommend {
  NSString *itunesLink = [NSString stringWithFormat:@"http://itunes.apple.com/app/id%@", kAppId];
  SEAActivityViewController *activityViewController = [[SEAActivityViewController alloc] initWithActivityItems:@[[NSString stringWithFormat:@"Взгляни на Сеансы, лучшее приложение для походов в кино: %@", itunesLink]] applicationActivities:nil];

  activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
  };
  [self presentViewController:activityViewController animated:YES completion:nil];
}

- (void)sendFeedback {
  if ([MFMailComposeViewController canSendMail]) {
    AYFeedback *feedback = [AYFeedback new];
    self.mailComposeViewController = [MFMailComposeViewController new];
    self.mailComposeViewController.mailComposeDelegate = self;
    self.mailComposeViewController.toRecipients = @[@"ayan.yenb@gmail.com"];
    self.mailComposeViewController.subject = feedback.subject;
    [self.mailComposeViewController setMessageBody:feedback.messageWithMetaData isHTML:NO];
    [self presentViewController:self.mailComposeViewController animated:YES completion:nil];
  } else {
    SEAAlertView *alertView = [[SEAAlertView alloc] initWithTitle:NSLocalizedString(@"Настройте ваш почтовый сервис", nil) body:NSLocalizedString(@"Чтобы отправить нам письмо, вам необходим настроенный почтовый аккаунт.", nil)];
    [alertView show];
  }
}

- (void)rate {
  [SEAPromptView setHasHadInteractionForCurrentVersion];
  [AYAppStore openAppStoreReviewForApp:kAppId];
}

- (void)myApps {
  [AYAppStore openAppStoreForMyApps];
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  switch (section) {
    case 0: return 2;
    case 1: return 1;
    case 2: return 1;
    case 3: return 4;
    default: return 0;
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return kModalViewCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  if (section == 0) {
    return [self footerViewWithText:NSLocalizedString(@"Фильтры для фильмов будут сохраняться при каждом выходе из приложения", nil) center:NO].height;
  } else if (section == 3) {
    return [self footerViewWithText:[NSString stringWithFormat:NSLocalizedString(@"Сеансы %@\r© Аян Енбекбай", nil), [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]] center:YES].height;
  }
  return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
  if (section == 0) {
    return [self footerViewWithText:NSLocalizedString(@"Фильтры для фильмов будут сохраняться при каждом выходе из приложения", nil) center:NO];
  } else if (section == 3) {
    return [self footerViewWithText:[NSString stringWithFormat:NSLocalizedString(@"Сеансы %@\r© Аян Енбекбай", nil), [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]] center:YES];
  }
  return nil;
}

- (UIView *)footerViewWithText:(NSString *)text center:(BOOL)center {
  UILabel *footerText = [[UILabel alloc] initWithFrame:CGRectMake(kSettingsViewPadding.left, kSettingsViewPadding.top, self.tableView.width - kSettingsViewPadding.left - kSettingsViewPadding.right, 0)];

  footerText.font = [UIFont regularFontWithSize:[UIFont smallTextFontSize]];
  footerText.textColor = [UIColor colorWithWhite:1 alpha:kDisabledAlpha];
  footerText.text = text;
  footerText.numberOfLines = 0;
  footerText.textAlignment = NSTextAlignmentCenter;
  [footerText setFrameToFitWithHeightLimit:100];
  if (center) {
    footerText.textAlignment = NSTextAlignmentCenter;
  }
  UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.width, footerText.height + 20)];
  [footerView addSubview:footerText];

  return footerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  SEASettingsViewTableCell *cell = (SEASettingsViewTableCell *)[self.tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SEASettingsViewTableCell class]) forIndexPath:indexPath];

  if (indexPath.section == 0) {
    cell.label.frame = CGRectMake(kSettingsViewPadding.left, 0, cell.width - kSettingsViewPadding.left - kSettingsViewPadding.right, cell.height);
    if (indexPath.row == 0) {
      cell.label.text = NSLocalizedString(@"Рейтинг в процентах", nil);
      cell.toggle.frame = CGRectMake(cell.width - cell.toggle.width - kSettingsViewPadding.right, (cell.height - cell.toggle.height) / 2, cell.toggle.width, cell.toggle.height);
      cell.toggle.on = [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] boolForKey:kShowPercentRatingsKey];
      cell.toggle.hidden = NO;
      [cell.toggle addTarget:self action:@selector(showPercentRating:) forControlEvents:UIControlEventValueChanged];
    } else if (indexPath.row == 1) {
      cell.label.text = NSLocalizedString(@"Сохранять фильтры", nil);
      cell.toggle.frame = CGRectMake(cell.width - cell.toggle.width - kSettingsViewPadding.right, (cell.height - cell.toggle.height) / 2, cell.toggle.height, cell.toggle.height);
      cell.toggle.on = [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] boolForKey:kSaveFiltersKey];
      cell.toggle.hidden = NO;
      [cell.toggle addTarget:self action:@selector(saveFilters:) forControlEvents:UIControlEventValueChanged];
    }
  } else if (indexPath.section == 1) {
    cell.label.frame = CGRectMake(kSettingsViewPadding.left, 0, cell.width - kSettingsViewPadding.left - kSettingsViewPadding.right, cell.height);
    cell.toggle.frame = CGRectMake(cell.width - cell.toggle.width - kSettingsViewPadding.right, (cell.height - cell.toggle.height) / 2, cell.toggle.width, cell.toggle.height);
    cell.toggle.hidden = NO;
    if (indexPath.row == 0) {
      cell.label.text = NSLocalizedString(@"Параллакс", nil);
      cell.toggle.on = [[[NSUserDefaults alloc] initWithSuiteName:kAppGroup] boolForKey:kParallaxKey];
      [cell.toggle addTarget:self action:@selector(parallax:) forControlEvents:UIControlEventValueChanged];
    }
  } else if (indexPath.section == 2) {
    NSString *cacheSize = [NSString stringWithFormat:NSLocalizedString(@"%.1f МБ", @"{Size} МБ"), [[SDImageCache sharedImageCache] getSize] / 1024.0 / 1024.0];
    CGFloat sublabelWidth = [self stringWidth:cacheSize font:cell.sublabel.font];
    cell.label.frame = CGRectMake(kSettingsViewPadding.left, 0, cell.width - sublabelWidth - kSettingsViewPadding.left - kSettingsViewPadding.right - kSettingsViewCellLabelSpacing, cell.height);
    cell.sublabel.frame = CGRectMake(cell.label.right + kSettingsViewCellLabelSpacing, 0, sublabelWidth, cell.height);
    cell.sublabel.hidden = NO;
    cell.label.text = NSLocalizedString(@"Очистить кэш", nil);
    cell.sublabel.text = cacheSize;
  } else {
    cell.label.frame = CGRectMake(cell.image.right + kSettingsViewCellIconMargin, 0, cell.width - cell.image.right - kSettingsViewCellIconMargin - kSettingsViewPadding.right, cell.height);
    cell.image.hidden = NO;
    switch (indexPath.row) {
      case 0:
        cell.label.text = NSLocalizedString(@"Написать нам", nil);
        cell.image.image = [[UIImage imageNamed:@"MailIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        break;
      case 1:
        cell.label.text = NSLocalizedString(@"Поставить рейтинг в App Store", nil);
        cell.image.image = [[UIImage imageNamed:@"RateIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        break;
      case 2:
        cell.label.text = NSLocalizedString(@"Порекомендовать другу", nil);
        cell.image.image = [[UIImage imageNamed:@"RecommendIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        break;
      case 3:
        cell.label.text = NSLocalizedString(@"Другие мои приложения", nil);
        cell.image.image = [[UIImage imageNamed:@"iPhoneIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        break;
      default:
        break;
    }
  }
  return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section == 2) {
    [self clearCache];
    [self.tableView reloadData];
  } else if (indexPath.section == 3) {
    switch (indexPath.row) {
      case 0:
        [self sendFeedback];
        break;
      case 1:
        [self rate];
        break;
      case 2:
        [self recommend];
        break;
      case 3:
        [self myApps];
        break;
      default:
        break;
    }
  }
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
  if ((indexPath.section == 0 && indexPath.row == 0) || indexPath.section == 2 || indexPath.section == 3) {
    return YES;
  }
  return NO;
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
  SEASettingsViewTableCell *cell = (SEASettingsViewTableCell *)[self.tableView cellForRowAtIndexPath:indexPath];
  cell.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1f];
}

- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath {
  SEASettingsViewTableCell *cell = (SEASettingsViewTableCell *)[self.tableView cellForRowAtIndexPath:indexPath];
  cell.backgroundColor = [UIColor colorWithWhite:1 alpha:0.025f];
}

#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
  [self dismissViewControllerAnimated:YES completion:^{
    if (result == MFMailComposeResultSent) {
      SEAAlertView *alertView = [[SEAAlertView alloc] initWithTitle:NSLocalizedString(@"Спасибо!", nil) body:NSLocalizedString(@"Ваш отзыв был получен, и мы скоро с вами свяжемся.", nil)];
      [alertView show];
    }
  }];
}

#pragma mark Helpers

- (CGFloat)stringWidth:(NSString *)string font:(UIFont *)font {
  return [string boundingRectWithSize:CGSizeMake(0, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName : font } context:nil].size.width;
}

@end
