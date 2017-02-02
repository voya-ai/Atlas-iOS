//
//  ATLMessageCardListView.m
//  Pods
//
//  Created by Daniel Maness on 1/31/17.
//
//

#import "ATLMessageCardListView.h"

@interface ATLMessageCardListView ()

@property (nonatomic) LYRMessage *message;

@end

@implementation ATLMessageCardListView

+ (void)initialize
{
    [super initialize];
}

- (id)initWithMessage:(LYRMessage *)message withFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _message = message;
        [self updateList];
    }
    return self;
}

+ (CGSize)intrinsicContentSize
{
    CGFloat viewWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]);
    CGFloat viewHeight = 200;
    CGSize size = CGSizeMake(viewWidth * 0.9, viewHeight);
    return size;
}

- (void)updateList
{
//    NSArray *list = self.message.parts;
//    self.dataSource = list;
//    [self reloadData];
}

@end
