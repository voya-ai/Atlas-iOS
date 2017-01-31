//
//  ATLSignatureInputView.m
//  Pods
//
//  Created by Andrew Mcknight on 1/31/17.
//
//

#import "ATLSignatureInputView.h"

const CGFloat height = 200;

@interface ATLSignatureInputView()

@property (copy, nonatomic) NSMutableOrderedSet<NSMutableOrderedSet<NSValue *> *> *touchPoints; // set of sets of NSValues containing CGPoints, as separate paths of a signature

@end

@implementation ATLSignatureInputView

- (instancetype)init {
    self = [super initWithFrame:CGRectMake(0, 0, CGRectGetWidth([[UIScreen mainScreen] bounds]), height)];
    if (!self) { return nil; }

    _touchPoints = [NSMutableOrderedSet orderedSet];
    self.backgroundColor = [UIColor whiteColor];
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();

    [self drawSignatureLineWithContext:context];
    [self drawSignatureWithContext:context];
}

- (void)drawSignatureLineWithContext:(CGContextRef)context {
    CGContextSetRGBStrokeColor(context, 0, 0, 0, 1);
    CGContextSetLineWidth(context, 1);
    CGContextSetLineCap(context, kCALineCapSquare);

    CGFloat y = 150;
    CGFloat xPad = 20;

    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, nil, xPad, y);
    CGPathAddLineToPoint(path, nil, CGRectGetWidth(self.bounds) - xPad, y);

    CGContextAddPath(context, path);
    CGContextStrokePath(context);
}

- (void)drawSignatureWithContext:(CGContextRef)context {
    CGContextSetRGBStrokeColor(context, 0, 0, 0, 1);
    CGContextSetLineWidth(context, 3);
    CGContextSetLineCap(context, kCALineCapRound);

    [self.touchPoints enumerateObjectsUsingBlock:^(NSMutableOrderedSet * _Nonnull pointSet, NSUInteger idx, BOOL * _Nonnull stop) {

        CGMutablePathRef path = CGPathCreateMutable();
        [pointSet enumerateObjectsUsingBlock:^(NSValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGPoint point = obj.CGPointValue;

            if (idx == 0) {
                CGPathMoveToPoint(path, nil, point.x, point.y);
                return;
            }

            CGPathAddLineToPoint(path, nil, point.x, point.y);
        }];

        CGContextAddPath(context, path);
        CGContextStrokePath(context);
    }];

}

#pragma mark - Touch capture

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.touchPoints addObject:[NSMutableOrderedSet orderedSet]];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = touches.anyObject;
    CGPoint location = [touch locationInView:self];
    NSValue *value = [NSValue valueWithCGPoint:location];
    [self.touchPoints.lastObject addObject:value];
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {}

@end
