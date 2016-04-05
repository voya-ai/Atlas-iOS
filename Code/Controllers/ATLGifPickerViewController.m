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
#import "LocalDiskDataCache.h"

static NSString *const GIF_CELL_REUSE_IDENTIFIER = @"gifCellReuseID";

@interface ATLGifPickerViewController () {
    RFStreamRequester *gifDataRequester;
    
    NSMutableArray *gifList;
    NSMutableDictionary *downloadIndexMapping;
    NSURLSession *gifDownloadSession;
    dispatch_semaphore_t gifSendLock;
}
@property (nonatomic, retain) UICollectionView *gifPickerCollectionView;

@end

@implementation ATLGifPickerViewController

#pragma mark - Initializers
-(instancetype)init
{
  self = [super init];
  if(self)
  {
    gifSendLock = dispatch_semaphore_create(1);
  }
  
  return self;
}

-(void)dealloc
{
    [gifDownloadSession invalidateAndCancel];
}

#pragma mark - <UIViewController> overrides
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
    RFObject *gif = gifList[indexPath.row];
    [_gifPickerDelegate gifSelectedAtURL:[gif getSmallGifUrl]];
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
    [self beginDownloadForGIFatURL:[gif getSmallGifUrl] andIndexPath:indexPath andGIFCell:cell];
    
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
-(void)beginDownloadForGIFatURL:(NSString *)string
                   andIndexPath:(NSIndexPath *)path
                     andGIFCell:(ATLGIFCollectionViewCell *)cell
{
    NSData *gifData = [[LocalDiskDataCache defaultCache] lookupObjectAtKey:string];

    if(gifData)
    {
        [self updateCellWithRemoteGIFURL:string withGIFData:gifData andCell:cell];
    }
    else
    {
        NSURLSessionDownloadTask *task = [gifDownloadSession downloadTaskWithURL:[NSURL URLWithString:string]];
        [task resume];
        
        downloadIndexMapping[string] = path;
    }
}

-(void)updateCellWithRemoteGIFURL:(NSString *)downloadUrl
                      withGIFData:(NSData *)gifData
                          andCell:(ATLGIFCollectionViewCell *)gifCell
{
    ATLGIFCollectionViewCell *targetCell = gifCell;
    if(!gifCell)
    {
        targetCell = (ATLGIFCollectionViewCell *)[_gifPickerCollectionView cellForItemAtIndexPath:downloadIndexMapping[downloadUrl]];
        if(!targetCell)
            return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [targetCell updateWithGIFData:gifData];
    });
    
    //remove the index path <-> url mapping for this URL
    downloadIndexMapping[downloadUrl] = nil;
}

-(void)clearAllCells
{
  [gifList removeAllObjects];
  [_gifPickerCollectionView reloadData];
}

#pragma mark - <NSURLSessionDownloadDelegate> methods
-(void)URLSession:(NSURLSession *)session
     downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    //Update the cell with the GIF data
    NSString *downloadUrl = downloadTask.originalRequest.URL.absoluteString;
    
    NSError *error;
    [[LocalDiskDataCache defaultCache] transferObjectAtFileLocation:location
                                                     toCacheWithKey:downloadUrl
                                                  withFileExtension:@"gif"];
    
    NSData *gifData = [NSData dataWithContentsOfURL:location options:0 error:&error];
    [self updateCellWithRemoteGIFURL:downloadUrl withGIFData:gifData andCell:nil];
}
@end
