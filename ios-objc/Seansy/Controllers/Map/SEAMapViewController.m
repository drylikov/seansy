#import "LMGeocoder.h"
#import "SEAConstants.h"
#import "SEADataManager.h"
#import "SEALocationManager.h"
#import "SEAMapViewController.h"
#import "SEAProgressView.h"
#import "SEATheatreViewController.h"
#import "UIColor+SEAHelpers.h"
#import "UIFont+SEASizes.h"
#import "UILabel+SEAHelpers.h"
#import "UIView+AYUtils.h"
#import <Reachability/Reachability.h>
#import <SDWebImage/UIImageView+WebCache.h>

static NSString *const kMapboxMapID = @"yenbekbay.ljee6dc2";

@interface SEAMapViewController ()

@property (nonatomic) CLLocationCoordinate2D cityCenterCoordinate;
@property (nonatomic) CLLocationCoordinate2D theatreCenterCoordinate;
@property (nonatomic) NSString *currentCity;
@property (nonatomic) RMMapView *mapView;
@property (nonatomic) SEAProgressView *progressView;
@property (nonatomic) UIView *noConnectionView;
@property (nonatomic) NSArray *theatres;

@end

@implementation SEAMapViewController

#pragma mark Initialization

- (instancetype)init {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.navigationItem.title = NSLocalizedString(@"Карта", nil);
  self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
  self.view.backgroundColor = [UIColor colorWithHexString:kOnyxColor];
  [[RMConfiguration sharedInstance] setAccessToken:@"pk.eyJ1IjoieWVuYmVrYmF5IiwiYSI6InFTQ0hjQW8ifQ.ZYPmAAaE0fZb42FcXeRADw"];
  self.cityCenterCoordinate = kCLLocationCoordinate2DInvalid;
  self.theatreCenterCoordinate = kCLLocationCoordinate2DInvalid;

  return self;
}

+ (SEAMapViewController *)sharedInstance {
  static SEAMapViewController *sharedInstance = nil;
  static dispatch_once_t oncePredicate;
  dispatch_once(&oncePredicate, ^{
    sharedInstance = [SEAMapViewController new];
  });
  return sharedInstance;
}

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [self checkConnection];
}

- (void)viewWillAppear:(BOOL)animated {
  [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
  self.navigationController.navigationBar.shadowImage = nil;
  if (self.mapView) {
    if (self.currentCity && ![self.currentCity isEqualToString:[SEALocationManager sharedInstance].currentCity]) {
      [self.mapView removeFromSuperview];
      self.mapView = nil;
      [self checkConnection];
    } else {
      [self setUpMapView];
    }
  }
  [super viewWillAppear:animated];
}

#pragma mark Private

- (void)checkConnection {
  [self setUpProgressView];
  Reachability *reachability = [Reachability reachabilityWithHostname:@"www.google.com"];
  reachability.reachableBlock = ^(Reachability *reach) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [reach stopNotifier];
      [self.noConnectionView removeFromSuperview];
      [self setUpMapView];
      [self.progressView performFinishAnimation];
    });
  };
  reachability.unreachableBlock = ^(Reachability *reach) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.mapView removeFromSuperview];
      self.mapView = nil;
      [self setUpNoConnectionView];
      [self.progressView performFinishAnimation];
    });
  };
  [reachability performSelector:@selector(startNotifier) withObject:nil afterDelay:1.0];
}

- (void)setUpNoConnectionView {
  if (!self.noConnectionView) {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"SadFace"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    imageView.tintColor = [UIColor whiteColor];
    CGSize imageSize = imageView.image.size;
    imageView.frame = CGRectMake((self.view.width - imageSize.width) / 2, (self.view.height - imageSize.height) / 2, imageSize.width, imageSize.height);

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(50, imageView.top + imageSize.height + 20, self.view.width - 100, 0)];
    label.text = NSLocalizedString(@"Произошла ошибка при загрузке данных. Возможно, что-то не так с вашим подключением или с сервером.", nil);
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    [label setFrameToFitWithHeightLimit:0];
    CGFloat verticalOffset = -(label.height + 20) / 2;
    imageView.top += verticalOffset;
    label.top += verticalOffset;

    self.noConnectionView = [[UIView alloc] initWithFrame:self.view.frame];
    [self.noConnectionView addSubview:label];
    [self.noConnectionView addSubview:imageView];
    [self.view insertSubview:self.noConnectionView belowSubview:self.progressView];
  } else if ([self.view.subviews indexOfObject:self.noConnectionView] == NSNotFound) {
    [self.view insertSubview:self.noConnectionView belowSubview:self.progressView];
  }
}

- (void)setUpProgressView {
  self.progressView = [[SEAProgressView alloc] initWithFrame:self.view.bounds];
  self.progressView.backgroundColor = [UIColor colorWithHexString:kOnyxColor];
  self.progressView.indeterminate = YES;
  [self.view addSubview:self.progressView];
}

- (void)setUpMapView {
  if (!self.mapView) {
    RMMapboxSource *tileSource = [[RMMapboxSource alloc] initWithMapID:kMapboxMapID];
    self.mapView = [[RMMapView alloc] initWithFrame:self.view.bounds andTilesource:tileSource];
    self.mapView.delegate = self;
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.mapView.tintColor = [UIColor colorWithHexString:kAmberColor];
    self.mapView.showLogoBug = NO;
    self.mapView.hideAttribution = YES;
    [self.view insertSubview:self.mapView belowSubview:self.progressView];
  }
  BOOL needsLocation = [SEALocationManager sharedInstance].actualCity && [[SEALocationManager sharedInstance].actualCity isEqualToString:[SEALocationManager sharedInstance].currentCity];
  self.mapView.showsUserLocation = needsLocation;
  if (needsLocation) {
    self.navigationItem.rightBarButtonItem = [[RMUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor whiteColor];
  } else {
    self.navigationItem.rightBarButtonItem = nil;
  }
  [self updateCity];
}

- (void)updateCity {
  self.theatres = [[SEADataManager sharedInstance] sortedTheatres:[[SEADataManager sharedInstance] theatresForCity:[SEALocationManager sharedInstance].currentCity]];
  if (self.selectedTheatre) {
    self.theatreCenterCoordinate = self.selectedTheatre.location.coordinate;
  } else {
    SEATheatre *firstTheatre = self.theatres[0];
    self.theatreCenterCoordinate = firstTheatre.location.coordinate;
  }
  if (![self.currentCity isEqualToString:[SEALocationManager sharedInstance].currentCity]) {
    self.currentCity = [SEALocationManager sharedInstance].currentCity;
    [self addMarkers];
    [[LMGeocoder sharedInstance] geocodeAddressString:self.currentCity service:kLMGeocoderGoogleService completionHandler:^(LMAddress *address, NSError *error) {
      if (address && !error) {
        self.cityCenterCoordinate = address.coordinate;
        [self setConstraints:self.cityCenterCoordinate];
      } else {
        self.cityCenterCoordinate = kCLLocationCoordinate2DInvalid;
        [self setConstraints:self.theatreCenterCoordinate];
      }
      [self updateCenterCoordinate];
    }];
  } else {
    [self updateCenterCoordinate];
  }
}

- (void)addMarkers {
  [self.mapView removeAllAnnotations];
  for (SEATheatre *theatre in self.theatres) {
    RMAnnotation *annotation = [[RMAnnotation alloc] initWithMapView:self.mapView coordinate:theatre.location.coordinate andTitle:theatre.name];
    annotation.userInfo = @(theatre.id);
    [self.mapView addAnnotation:annotation];
  }
}

- (void)updateCenterCoordinate {
  if (!self.selectedTheatre && !self.mapView.selectedAnnotation) {
    self.mapView.zoom = 10;
    if (CLLocationCoordinate2DIsValid(self.cityCenterCoordinate)) {
      self.mapView.centerCoordinate = self.cityCenterCoordinate;
    } else {
      self.mapView.centerCoordinate = self.theatreCenterCoordinate;
    }
  } else if (self.selectedTheatre && (!self.mapView.selectedAnnotation || [self.mapView.selectedAnnotation.userInfo integerValue] != self.selectedTheatre.id)) {
    self.mapView.zoom = 12;
    self.mapView.centerCoordinate = self.theatreCenterCoordinate;
    for (RMPointAnnotation *annotation in self.mapView.annotations) {
      if ([annotation.userInfo integerValue] == self.selectedTheatre.id) {
        [self.mapView selectAnnotation:annotation animated:YES];
        self.selectedTheatre = nil;
        break;
      }
    }
  }
}

- (void)setConstraints:(CLLocationCoordinate2D)coordinate {
  CGFloat degreeRadius = 30000.f / 110000.f; // (30km / 110km per degree latitude)
  CLLocationCoordinate2D southWest = CLLocationCoordinate2DMake(coordinate.latitude - degreeRadius, coordinate.longitude - degreeRadius);
  CLLocationCoordinate2D northEast = CLLocationCoordinate2DMake(coordinate.latitude  + degreeRadius, coordinate.longitude + degreeRadius);
  [self.mapView setConstraintsSouthWest:southWest northEast:northEast];
}

#pragma mark RMMapViewDelegate

- (RMMapLayer *)mapView:(RMMapView *)mapView layerForAnnotation:(RMAnnotation *)annotation {
  if (annotation.isUserLocationAnnotation) {
    return nil;
  }
  RMMarker *marker = [[RMMarker alloc] initWithMapboxMarkerImage:@"cinema" tintColor:[UIColor colorWithHexString:kAmberColor]];
  marker.canShowCallout = YES;

  SEATheatre *theatre = [[SEADataManager sharedInstance] theatreForId:[annotation.userInfo integerValue]];

  if (theatre.backdrop.url) {
    marker.leftCalloutAccessoryView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetHeight(marker.frame), CGRectGetHeight(marker.frame))];
    marker.leftCalloutAccessoryView.contentMode = UIViewContentModeScaleAspectFill;
    marker.leftCalloutAccessoryView.clipsToBounds = YES;
    [theatre.backdrop getOriginalImageWithProgressBlock:nil completionBlock:^(UIImage *originalImage, BOOL fromCache) {
      if (originalImage) {
        [(UIImageView *)marker.leftCalloutAccessoryView setImage:originalImage];
      }
    }];
  }

  marker.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
  marker.rightCalloutAccessoryView.tintColor = [UIColor colorWithHexString:kOnyxColor];

  return marker;
}

- (void)tapOnCalloutAccessoryControl:(UIControl *)control forAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map {
  SEATheatre *theatre = [[SEADataManager sharedInstance] theatreForId:[annotation.userInfo integerValue]];
  SEATheatreViewController *theatreViewController = [[SEATheatreViewController alloc] initWithTheatre:theatre];
  [self.navigationController pushViewController:theatreViewController animated:YES];
}

@end
