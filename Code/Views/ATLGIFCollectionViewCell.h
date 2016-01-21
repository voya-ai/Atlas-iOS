//
//  ATLGIFCollectionViewCell.h
//  Atlas
//
//  Created by Jeff Sinckler on 1/14/16.
//
//

#import <UIKit/UIKit.h>
#import "ATLGifPickerViewController.h"

/**
 @abstract The `ATLGIFCollectionViewCell` class provides a cell for UICollectionViews that can render GIFs.
 */
@interface ATLGIFCollectionViewCell : UICollectionViewCell

/**
 @abstract Initializes additional views and configures the view's visual elements.
 */
-(void)configureCell;

/**
 @abstract Produces a GIF from the parameter and displays the content inside of the cell's image view.
 */
-(void)updateWithGIFData:(NSData *)data;

/**
 @abstract Gets the UIImage that is currently displayed inside of the cell's UIImageView.
 @return The UIImage representation of the GIF.
 */
-(UIImage *)getCurrentlyRenderedImage;

@end
