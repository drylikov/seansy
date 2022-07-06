#import "SEAWebViewController.h"

#import "SEAActivityViewController.h"
#import "SEAConstants.h"
#import "UIColor+SEAHelpers.h"
#import "UIView+AYUtils.h"
#import <Analytics/Analytics.h>
#import <ARChromeActivity/ARChromeActivity.h>
#import <NJKWebViewProgress/NJKWebViewProgressView.h>
#import <TUSafariActivity/TUSafariActivity.h>

@interface SEAWebViewController ()

@property (nonatomic) NJKWebViewProgress *progressProxy;
@property (nonatomic) NJKWebViewProgressView *progressView;
@property (nonatomic) NSURL *url;

@end

@implementation SEAWebViewController

#pragma mark Initialization

- (instancetype)initWithUrl:(NSURL *)url {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.url = url;

  return self;
}

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[SEGAnalytics sharedAnalytics] screen:@"News entry" properties:@{ @"link" : [self.url absoluteString] }];
  [self setUpNavigationBar];
  [self setUpWebView];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.progressView = [[NJKWebViewProgressView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.height - 2 - 1 / [UIScreen mainScreen].scale, self.navigationController.navigationBar.width, 2)];
  self.progressView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
  [self.navigationController.navigationBar addSubview:self.progressView];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [self.progressView removeFromSuperview];
}

#pragma mark Private

- (void)setUpNavigationBar {
  self.navigationItem.title = NSLocalizedString(@"Загружается...", nil);
  UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(share)];
  self.navigationItem.rightBarButtonItem = shareButton;
}

- (void)setUpWebView {
  self.webView = [[UIWebView alloc] initWithFrame:self.view.frame];
  self.webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

  [self.view addSubview:self.webView];

  self.progressProxy = [NJKWebViewProgress new];
  self.webView.delegate = self.progressProxy;
  self.progressProxy.webViewProxyDelegate = self;
  self.progressProxy.progressDelegate = self;

  [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
}

- (void)share {
  TUSafariActivity *safariActivity = [TUSafariActivity new];
  ARChromeActivity *chromeActivity = [ARChromeActivity new];

  SEAActivityViewController *activityViewController = [[SEAActivityViewController alloc] initWithActivityItems:@[self.webView.request.URL] applicationActivities:@[safariActivity, chromeActivity]];

  activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
  };
  [self presentViewController:activityViewController animated:YES completion:nil];
}

#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  return true;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  self.navigationItem.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  DDLogError(@"Error occured while loading web page: %@", error);
}

#pragma mark NJKWebViewProgressDelegate

- (void)webViewProgress:(NJKWebViewProgress *)webViewProgress updateProgress:(CGFloat)progress {
  [self.progressView setProgress:progress animated:YES];
  NSString *title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];

  if (title.length == 0) {
    self.navigationItem.title = NSLocalizedString(@"Загружается...", nil);
  } else {
    self.navigationItem.title = title;
  }
}

@end
