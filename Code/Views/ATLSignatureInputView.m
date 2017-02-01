//
//  ATLSignatureInputView.m
//  Pods
//
//  Created by Andrew Mcknight on 1/31/17.
//
//

#import <QuartzCore/QuartzCore.h>

#import "ATLSignatureInputView.h"

@interface ATLSignatureInputView()

@property (copy, nonatomic) NSMutableOrderedSet<NSMutableOrderedSet<NSValue *> *> *touchPoints; // set of sets of NSValues containing CGPoints. each subset is a path where the user has picked up their finger and then started drawing another part of their signature

@property (weak, nonatomic) id<ATLSignatureInputViewDelegate> delegate;

@property (assign, nonatomic) BOOL shouldDrawBaseline;

@end

@implementation ATLSignatureInputView

- (instancetype)initWithDelegate:(id<ATLSignatureInputViewDelegate>)delegate {
    CGFloat viewWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]);
    CGFloat viewHeight = 200;
    self = [super initWithFrame:CGRectMake(0, 0, viewWidth, viewHeight)];
    if (!self) { return nil; }

    _delegate = delegate;
    _shouldDrawBaseline = YES;

    _touchPoints = [NSMutableOrderedSet orderedSet];
    self.backgroundColor = [UIColor whiteColor];

    CGFloat buttonWidth = 50;
    CGFloat buttonHeight = 30;
    UIButton *doneButton = [[UIButton alloc] initWithFrame:CGRectMake(viewWidth - buttonWidth - 20, 10, buttonWidth, buttonHeight)];
    [doneButton addTarget:self action:@selector(done) forControlEvents:UIControlEventTouchUpInside];
    [doneButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [doneButton setTitle:@"Done" forState:UIControlStateNormal];
    [self addSubview:doneButton];
    return self;
}

#pragma mark - Overrides

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();

    if (self.shouldDrawBaseline) {
        [self drawSignatureLineWithContext:context];
    }
    [self drawSignatureWithContext:context];
}

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

#pragma mark - Actions

- (void)done {
    self.shouldDrawBaseline = NO;
    [self setNeedsDisplay];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate signatureInputView:self didCaptureSignature:[self captureImage]];
    });
}

#pragma mark - Private

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

- (UIImage *)captureImage {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return screenshot;
}

@end
