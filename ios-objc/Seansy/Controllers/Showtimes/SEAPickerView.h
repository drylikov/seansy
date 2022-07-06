//
//  Copyright (c) 2014 Akio Yasui, 2015 Ayan Yenbekbay.
//

@class SEAPickerView;

@protocol SEAPickerViewDataSource <NSObject>
@required
- (NSDate *)pickerView:(SEAPickerView *)pickerView dateForItem:(NSInteger)item;
- (NSUInteger)numberOfItemsInPickerView:(SEAPickerView *)pickerView;
@end

@protocol SEAPickerViewDelegate <UIScrollViewDelegate>
@optional
- (void)pickerView:(SEAPickerView *)pickerView didSelectItem:(NSInteger)item;
@end

@interface SEAPickerView : UIView

#pragma mark Properties

@property (nonatomic) CGFloat interitemSpacing;
@property (nonatomic) NSString *city;
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) UIColor *selectedTextColor;
@property (nonatomic) UIColor *textColor;
@property (nonatomic) UIFont *font;
@property (nonatomic) UIFont *selectedFont;
@property (nonatomic, getter = isMaskDisabled) BOOL maskDisabled;
@property (nonatomic, getter = shouldSelectOnScroll) BOOL selectOnScroll;
@property (nonatomic, readonly) CGPoint contentOffset;
@property (nonatomic, readonly) NSUInteger selectedItem;
@property (weak, nonatomic) id <SEAPickerViewDataSource> dataSource;
@property (weak, nonatomic) id <SEAPickerViewDelegate> delegate;
@property (nonatomic) BOOL didMoveManually;

#pragma mark Methods

- (void)reloadData;
- (void)scrollToItem:(NSUInteger)item animated:(BOOL)animated;
- (void)selectItem:(NSUInteger)item animated:(BOOL)animated;

@end
