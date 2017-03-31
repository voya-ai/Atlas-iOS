//
//  LocalDiskDataCache.h
//  Atlas
//
//  Created by Jeff Sinckler on 3/15/16.
//
//

#import <Foundation/Foundation.h>

/**
 @abstract The `LocalDiskDataCache` class provides an API that stores serializable objects on disk. Objects stored are mapped to and accessed via a key.
 */
@interface LocalDiskDataCache : NSObject

/**
 @abstract Returns a singleton instance of LocalDiskDataCache. This instance is configured to save data to the iOS default caches directory.
 */
+(LocalDiskDataCache *)defaultCache;

/**
 @abstract Initiates a query for GIFs based on the string input parameter.
 @param The search string to use in the query.
 */
-(void)setObject:(NSData *)data forKey:(NSString *)key;

-(void)transferObjectAtFileLocation:(NSURL *)fileLocation
                     toCacheWithKey:(NSString *)key
                  withFileExtension:(NSString *)extension;
/**
 @abstract Initiates a query for GIFs based on the string input parameter.
 @param The search string to use in the query.
 */
-(NSData *)lookupObjectAtKey:(NSString *)key;

-(NSURL *)fileLocationForDataStoredAtKey:(NSString *)key;


@end
