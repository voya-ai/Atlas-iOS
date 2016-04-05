//
//  ATLGIFCollectionViewCell.m
//  Atlas
//
//  Created by Jeff Sinckler on 1/14/16.
//
//

#import "ATLGIFCollectionViewCell.h"
#import "ATLUIImageHelper.h"

@interface ATLGIFCollectionViewCell () {
  UIActivityIndicatorView *loadingSpinner;
  UIImageView *gifImageView;
}
@end

@implementation ATLGIFCollectionViewCell

-(void)configureCell
{
  if(!gifImageView)
    gifImageView = [[UIImageView alloc] init];
  if(!loadingSpinner)
    loadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  
  [loadingSpinner setCenter:CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))];
  [loadingSpinner setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
  [loadingSpinner setTranslatesAutoresizingMaskIntoConstraints:YES];
  [loadingSpinner startAnimating];
  
  [gifImageView setFrame:self.bounds];
  [gifImageView setBackgroundColor:[UIColor colorWithWhite:0.95f alpha:1.0f]];
  [self addSubview:gifImageView];
  
  [self addSubview:loadingSpinner];
}

-(void)updateWithGIFData:(NSData *)data
{
  UIImage *image = ATLAnimatedImageWithAnimatedGIFData(data);
  [gifImageView setImage:image];
  
  [loadingSpinner stopAnimating];
}

-(void)prepareForReuse
{
  [gifImageView setImage:nil];
}

@end
