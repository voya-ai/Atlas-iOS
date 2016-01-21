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
  UIImageView *gifImageView;
}
@end

@implementation ATLGIFCollectionViewCell

-(void)configureCell
{
  if(!gifImageView)
    gifImageView = [[UIImageView alloc] init];
  
  [gifImageView setFrame:self.bounds];
  [gifImageView setBackgroundColor:[UIColor colorWithWhite:0.95f alpha:1.0f]];
  [self addSubview:gifImageView];
}

-(void)updateWithGIFData:(NSData *)data
{
  UIImage *image = ATLAnimatedImageWithAnimatedGIFData(data);
  [gifImageView setImage:image];
}

-(UIImage *)getCurrentlyRenderedImage
{
    return gifImageView.image;
}

-(void)prepareForReuse
{
  [gifImageView setImage:nil];
}

@end
