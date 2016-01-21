//
//  RFUtilities.h
//  Pods
//
//  Created by Jeff Sinckler on 1/19/16.
//
//

#import <Foundation/Foundation.h>

@interface RFUtilities : NSObject

+ (NSString *)pageurl:(NSString *)path;
+ (NSString *)messagingUrl:(NSString *)path;
+ (NSString *)apiurl:(NSString *)path;
+ (NSString *)newApiUrl:(NSString *)path;
+ (NSURLSessionConfiguration *)sessionConfiguration:(NSDictionary *)headers;
+(NSString *)constructUrlWithBaseURL:(NSString *)base andParameters:(NSDictionary *)parameters;

@end
