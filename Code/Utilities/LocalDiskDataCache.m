//
//  LocalDiskDataCache.m
//  Atlas
//
//  Created by Jeff Sinckler on 3/15/16.
//
//

#import "LocalDiskDataCache.h"

#define MAPPING_FILE_NAME @"gif_cache_map"
#define ORDERING_FILE_NAME @"cache_ordering"

static NSUInteger const CACHE_SIZE_MAX = 30;

@implementation LocalDiskDataCache {
    NSMutableDictionary *keyToFileMapping;
    
    //most recently used files are at the end of the array
    NSMutableArray *keyOrdering;
}

+(LocalDiskDataCache *)defaultCache
{
    static LocalDiskDataCache *defaultCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ defaultCache = [[self alloc] init]; });
    return defaultCache;
}

-(instancetype)init
{
    self = [super init];
    if(self)
    {
        NSArray *filePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSLocalDomainMask, YES);
        NSString *cachesDirectory = filePaths[0];
        NSString *genericCacheFullPath = [cachesDirectory stringByAppendingPathComponent:MAPPING_FILE_NAME];
        NSString *cacheKeyOrdering = [cachesDirectory stringByAppendingString:ORDERING_FILE_NAME];
        
        if([[NSFileManager defaultManager] fileExistsAtPath:genericCacheFullPath])
        {
            NSDictionary *tempDict = [NSKeyedUnarchiver unarchiveObjectWithFile:genericCacheFullPath];
            if(tempDict && [tempDict isKindOfClass:[NSDictionary class]])
                keyToFileMapping = [NSMutableDictionary dictionaryWithDictionary:tempDict];
            else
                keyToFileMapping = [NSMutableDictionary new];
            
        }
        else
            keyToFileMapping = [NSMutableDictionary new];
        
        if([[NSFileManager defaultManager] fileExistsAtPath:cacheKeyOrdering])
        {
            NSArray *tempDict = [NSKeyedUnarchiver unarchiveObjectWithFile:cacheKeyOrdering];
            if(tempDict && [tempDict isKindOfClass:[NSArray class]])
                keyOrdering = [NSMutableArray arrayWithArray:tempDict];
            else
                keyOrdering = [NSMutableArray new];
        }
        else
            keyOrdering = [NSMutableArray new];
    }
    
    return self;
}

- (NSURL *)cacheDirectoryURL
{
    NSArray *filePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSLocalDomainMask, YES);
    if(filePaths.count > 0)
        return [NSURL URLWithString:[NSString stringWithFormat:@"file://%@", filePaths[0]]];
    else
        return nil;
}

-(NSURL *)cacheMappingFileURL
{
    return [[self cacheDirectoryURL] URLByAppendingPathComponent:MAPPING_FILE_NAME];
}

-(void)setObject:(NSData *)data
          forKey:(NSString *)key
{
    if(data == nil || key == nil)
        return;
    
    NSURL *fileURL = [[self cacheDirectoryURL] URLByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    if([data writeToURL:fileURL atomically:YES])
    {
        keyToFileMapping[key] = fileURL;
        [keyOrdering addObject:key];
        [self saveCache];
    }
    
    [self purgeCache];
}

-(void)transferObjectAtFileLocation:(NSURL *)fileLocation
                     toCacheWithKey:(NSString *)key
                  withFileExtension:(NSString *)extension
{
    if(fileLocation == nil || key == nil)
        return;
    
    NSURL *transferLocationURL = [[self cacheDirectoryURL] URLByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    if(extension)
        transferLocationURL = [transferLocationURL URLByAppendingPathExtension:extension];
    NSError *fileTransferError;
    if([[NSFileManager defaultManager] copyItemAtURL:fileLocation toURL:transferLocationURL error:&fileTransferError])
    {
        if(fileTransferError)
            return;
        
        keyToFileMapping[key] = transferLocationURL;
        [keyOrdering addObject:key];
        [self saveCache];
    }
    
    [self purgeCache];
}

-(NSData *)lookupObjectAtKey:(NSString *)key
{
    NSURL *fileURL = keyToFileMapping[key];
    if(fileURL)
    {
        [keyOrdering removeObject:key];
        [keyOrdering addObject:key];
    }
    return [NSData dataWithContentsOfURL:fileURL];
}

-(NSURL *)fileLocationForDataStoredAtKey:(NSString *)key
{
    NSURL *fileURL = keyToFileMapping[key];
    return fileURL;
}

#pragma mark - Saving and Loading
-(BOOL)saveCache
{
    NSArray *filePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSLocalDomainMask, YES);
    NSString *cachesDirectory = filePaths[0];
    NSString *genericCacheFullPath = [cachesDirectory stringByAppendingPathComponent:MAPPING_FILE_NAME];
    NSString *cacheKeyOrdering = [cachesDirectory stringByAppendingString:ORDERING_FILE_NAME];
    
    BOOL mappingSuccess = [NSKeyedArchiver archiveRootObject:keyToFileMapping toFile:genericCacheFullPath];
    BOOL orderingSuccess = [NSKeyedArchiver archiveRootObject:keyOrdering toFile:cacheKeyOrdering];
    return mappingSuccess && orderingSuccess;
}

-(void)purgeCache
{
    if(keyOrdering.count < CACHE_SIZE_MAX)
        return;
    
    NSInteger itemsToRemove = keyOrdering.count - CACHE_SIZE_MAX;
    itemsToRemove += 20; //trim the cache down below the threshold to prevent rapid purging
    for(int i = 0; i < itemsToRemove; i++)
    {
        [self deleteKeyFromCache:keyOrdering[0]];
    }
}

-(void)deleteKeyFromCache:(NSString *)key
{
    NSURL *fileLocationToDelete = keyToFileMapping[key];
    
    keyToFileMapping[key] = nil;
    [keyOrdering removeObject:key];
    [[NSFileManager defaultManager] removeItemAtURL:fileLocationToDelete error:nil];
}

@end
