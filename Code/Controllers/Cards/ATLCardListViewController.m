//
//  ATLCardListViewController.m
//  Pods
//
//  Created by Daniel Maness on 2/1/17.
//
//

#import "ATLCardListViewController.h"
#import "LayerKit/LayerKit.h"

@interface ATLCardListViewController () <UITableViewDelegate>

//@property (nonatomic) ATLMessageCardListView *cardView;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) NSMutableArray *imageArray;
@property (nonatomic) LYRMessage *message;

@end

@implementation ATLCardListViewController

- (id)initWithMessage:(LYRMessage *)message withFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        _message = message;
        
        self.scrollView = [[UIScrollView alloc] initWithFrame:frame];
        [self.view addSubview:self.scrollView];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.imageArray = [[NSMutableArray alloc]init];
    
    for (LYRMessagePart *messagePart in self.message.parts) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:messagePart.data
                                                             options:NSJSONReadingMutableContainers
                                                               error:nil];
        for (NSDictionary *data in json) {
            NSString *img = data[@"img"];
            if (img != (id)[NSNull null]) {
                NSURL *url = [NSURL URLWithString:img];
                if (url) {
                    NSData *data = [NSData dataWithContentsOfURL:url];
                    if (data) {
                        UIImage *image = [[UIImage alloc] initWithData:data];
                        CGSize size = image.size;
                        [self.imageArray addObject:image];
                    }
                }
            }
        }
    }
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setupScrollView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)setupScrollView
{
    for (int i = 0; i < self.imageArray.count; i++) {
        CGRect frame;
        frame.origin.x = self.scrollView.frame.size.height * i;
        frame.origin.y = 0;
        frame.size = self.scrollView.frame.size;
        UIView *subview = [[UIView alloc] initWithFrame:frame];
        
        UIImage *image = [self.imageArray objectAtIndex:i];
        UIImageView *imageView = [[UIImageView alloc] initWithImage: image];
        [imageView setFrame:CGRectMake(0, 0, frame.size.height - 10,frame.size.height )];
        
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
        singleTap.cancelsTouchesInView = NO;
        [self.scrollView addGestureRecognizer:singleTap];
        
        UITapGestureRecognizer *imageTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
        imageTap.numberOfTapsRequired = 1;
        [imageView addGestureRecognizer:imageTap];
        [imageView setUserInteractionEnabled:YES];
        [imageView setExclusiveTouch:YES];
        
        [subview addSubview:imageView];
        
        [self.scrollView addSubview:subview];

    }
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * self.imageArray.count, self.scrollView.frame.size.height);
    
    self.scrollView.contentOffset=CGPointMake (0, 0);
}

- (void)imageTapped:(UITapGestureRecognizer *)tap
{
    UIImageView *imageView = tap.view;
    imageView.backgroundColor = [UIColor blackColor];
}
@end
