#import "SEASettingsViewTableCell.h"

#import "SEAConstants.h"
#import "UIFont+SEASizes.h"

static CGRect const kSettingsViewTableCellImageFrame = { { 15, 15 }, { 20, 20 } };

@implementation SEASettingsViewTableCell

#pragma mark Initialization

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (!self) {
    return nil;
  }

  self.backgroundColor = [UIColor colorWithWhite:1 alpha:0.025f];
  self.selectionStyle = UITableViewCellSelectionStyleNone;

  self.label = [UILabel new];
  self.label.textColor = [UIColor colorWithWhite:1 alpha:kSecondaryTextAlpha];
  self.label.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];

  self.sublabel = [UILabel new];
  self.sublabel.textColor = [UIColor colorWithWhite:1 alpha:kDisabledAlpha];
  self.sublabel.font = [UIFont regularFontWithSize:[UIFont mediumTextFontSize]];
  self.sublabel.textAlignment = NSTextAlignmentRight;
  self.sublabel.hidden = YES;

  self.toggle = [UISwitch new];
  self.toggle.hidden = YES;

  self.control = [UISegmentedControl new];
  self.control.hidden = YES;

  self.image = [[UIImageView alloc] initWithFrame:kSettingsViewTableCellImageFrame];
  self.image.tintColor = [UIColor whiteColor];
  self.image.hidden = YES;

  [self.contentView addSubview:self.label];
  [self.contentView addSubview:self.sublabel];
  [self.contentView addSubview:self.toggle];
  [self.contentView addSubview:self.control];
  [self.contentView addSubview:self.image];

  return self;
}

#pragma mark Lifecycle

- (void)prepareForReuse {
  [super prepareForReuse];
  self.label.text = @"";
  self.sublabel.text = @"";
  self.sublabel.hidden = YES;
  self.toggle.hidden = YES;
  self.control.hidden = YES;
  self.image.hidden = YES;
  self.accessoryType = UITableViewCellAccessoryNone;
}

@end
