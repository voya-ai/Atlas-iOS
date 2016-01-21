//
//  ATLGifPickerViewController.m
//  Atlas
//
//  Created by Jeff Sinckler on 1/14/16.
//
//

#import "ATLGifPickerViewController.h"
#import "RFStreamRequester.h"
#import "ATLGIFCollectionViewCell.h"

static NSString *const GIF_CELL_REUSE_IDENTIFIER = @"gifCellReuseID";

@interface ATLGifPickerViewController () {
    RFStreamRequester *gifDataRequester;
    
    NSMutableArray *gifList;
    NSMutableDictionary *downloadIndexMapping;
    NSURLSession *gifDownloadSession;
}
@property (nonatomic, retain) UICollectionView *gifPickerCollectionView;

@end

@implementation ATLGifPickerViewController

-(void)viewDidLoad
{
    [self.view setBackgroundColor:[UIColor clearColor]];
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view setAutoresizingMask:UIViewAutoresizingNone];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    gifDownloadSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    
    gifList = [NSMutableArray new];
    downloadIndexMapping = [NSMutableDictionary new];
    
    UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    
    _gifPickerCollectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds
                                                  collectionViewLayout:flowLayout];
    [_gifPickerCollectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_gifPickerCollectionView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [_gifPickerCollectionView registerClass:[ATLGIFCollectionViewCell class]
                 forCellWithReuseIdentifier:GIF_CELL_REUSE_IDENTIFIER];
    [_gifPickerCollectionView setDelegate:self];
    [_gifPickerCollectionView setDataSource:self];
    [_gifPickerCollectionView setBackgroundColor:[UIColor clearColor]];
    [_gifPickerCollectionView setShowsHorizontalScrollIndicator:NO];
    [self.view addSubview:_gifPickerCollectionView];
}

#pragma mark - <UICollectionViewDelegateFlowLayout> methods
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    RFObject *targetObject = gifList[indexPath.row];
    CGSize dimensions = targetObject.dimensions;
    CGFloat contentAspectRatio = dimensions.width / dimensions.height;
    return CGSizeMake(collectionView.frame.size.height * contentAspectRatio, collectionView.frame.size.height);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 1;
}

- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ATLGIFCollectionViewCell *cell = (ATLGIFCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    UIImage *gifImage = [cell getCurrentlyRenderedImage];
    [_gifPickerDelegate gifSelectedWithImage:gifImage];
}

#pragma mark - <UICollectionViewDataSource> methods
- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    return gifList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ATLGIFCollectionViewCell *cell = (ATLGIFCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:GIF_CELL_REUSE_IDENTIFIER
                                                                                                           forIndexPath:indexPath];
    [cell configureCell];
    
    RFObject *gif = gifList[indexPath.row];
    [self beginDownloadForGIFatURL:[gif getSmallGifUrl] andIndexPath:indexPath];
    
    return cell;
}

#pragma mark - Requester Modifications
-(void)newRequesterForQuery:(NSString *)query
{
    [gifDataRequester cancelRequest];
    gifDataRequester = [RFStreamRequester getRequesterForSearchTerm:query];
    [gifDataRequester addGenericParameters:@{@"key" : LAYER_API_KEY}];
    
    //clear all items
    [gifList removeAllObjects];
    [downloadIndexMapping removeAllObjects];
    [_gifPickerCollectionView reloadData];
    
    [gifDataRequester fetch:^(BOOL success, NSArray *contentList, NSDictionary *fullDictionary) {
        if(!success)
            return;
        
        [gifList addObjectsFromArray:contentList];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_gifPickerCollectionView.collectionViewLayout invalidateLayout];
            [_gifPickerCollectionView reloadData];
        });
    }];
}

#pragma mark - Functionality
-(void)beginDownloadForGIFatURL:(NSString *)string andIndexPath:(NSIndexPath *)path
{
    NSURLSessionDownloadTask *task = [gifDownloadSession downloadTaskWithURL:[NSURL URLWithString:string]];
    [task resume];
    
    downloadIndexMapping[string] = path;
}

#pragma mark - <NSURLSessionDownloadDelegate> methods
-(void)URLSession:(NSURLSession *)session
     downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    //Update the cell with the GIF data
    NSString *downloadUrl = downloadTask.originalRequest.URL.absoluteString;
    
    NSError *error;
    NSData *gifData = [NSData dataWithContentsOfURL:location options:0 error:&error];
    ATLGIFCollectionViewCell *cell = (ATLGIFCollectionViewCell *)[_gifPickerCollectionView cellForItemAtIndexPath:downloadIndexMapping[downloadUrl]];
    if(!cell)
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [cell updateWithGIFData:gifData];
    });
    
    //remove the index path <-> url mapping for this URL
    downloadIndexMapping[downloadUrl] = nil;
}
@end
