//
//  ATLGifPickerViewController.h
//  Atlas
//
//  Created by Jeff Sinckler on 1/14/16.
//
//

#import <UIKit/UIKit.h>

/* Riffsy API Key for access from Layer */
#define LAYER_API_KEY @"ZIUN7N8UU28W"

/**
 @abstract The `ATLGifPickerDelegate` protocol is adopted by objects that need to respond to user input from the gif picker.
 */
@protocol ATLGifPickerDelegate <NSObject>

/**
 @abstract Tells the delegate that the user tapped on an available GIF.
 @param The UIImage/GIF that the user selected.
 */
-(void)gifSelectedWithImage:(UIImage *)image;

@end

/**
 @abstract The `ATLGifPickerViewController` class provides an interface that can request and display GIFs
 */
@interface ATLGifPickerViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, NSURLSessionDownloadDelegate>

/**
 @abstract Initiates a query for GIFs based on the string input parameter.
 @param The search string to use in the query.
 */
-(void)newRequesterForQuery:(NSString *)query;

/**
 @abstract Access to the receiver's delegate.
 */
@property (nonatomic, assign) id<ATLGifPickerDelegate>gifPickerDelegate;

@end
