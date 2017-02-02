//
//  ATLMessageCardListView.h
//  Pods
//
//  Created by Daniel Maness on 1/31/17.
//
//

#import <UIKit/UIKit.h>
#import <LayerKit/LYRMessage.h>

@class ATLMessageCardListView;

@interface ATLMessageCardListView : UIScrollView

- (id)initWithMessage:(LYRMessage *)message withFrame:(CGRect)frame;

+ (CGSize)intrinsicContentSize;

@end
