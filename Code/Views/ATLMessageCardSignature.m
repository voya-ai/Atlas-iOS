//
//  ATLMessageCardSignature.m
//  Pods
//
//  Created by Daniel Maness on 1/31/17.
//
//

#import "ATLMessageCardSignature.h"

@interface ATLMessageCardSignature ()

@end

@implementation ATLMessageCardSignature

+ (void)initialize
{
    
}

- (id)initWithFrame:(CGRect)frame
{
    CGSize size = [self intrinsicContentSize];
    self = [super initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    
    self = [super initWithFrame:frame];
    if (self) {
        [self lyr_commonInit];
        
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self lyr_commonInit];
    }
    return self;
}

- (void)lyr_commonInit
{
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor blueColor];
}

+ (CGSize)intrinsicContentSize
{
    CGFloat viewWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]);
    CGFloat viewHeight = 50;
    CGSize size = CGSizeMake(viewWidth * 0.75, viewHeight);
    return size;
}

- (void)resetView
{
    
}

- (void)dealloc
{
    
}

@end
