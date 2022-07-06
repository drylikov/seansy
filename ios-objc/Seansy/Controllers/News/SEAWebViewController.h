#import <NJKWebViewProgress/NJKWebViewProgress.h>
#import <WebKit/WebKit.h>

@interface SEAWebViewController : UIViewController <UIWebViewDelegate, NJKWebViewProgressDelegate>

#pragma mark Properties

@property (nonatomic) UIWebView *webView;

#pragma mark Methods

- (instancetype)initWithUrl:(NSURL *)url;

@end
