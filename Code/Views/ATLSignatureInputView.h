//
//  ATLSignatureInputView.h
//  Pods
//
//  Created by Andrew Mcknight on 1/31/17.
//
//

#import <UIKit/UIKit.h>

@class ATLSignatureInputView;

@protocol ATLSignatureInputViewDelegate <NSObject>

- (void)signatureInputView:(ATLSignatureInputView *)signatureInputView didCaptureSignature:(UIImage *)signature;

@end

@interface ATLSignatureInputView : UIView

- (instancetype)initWithDelegate:(id<ATLSignatureInputViewDelegate>)delegate NS_DESIGNATED_INITIALIZER;

@end
