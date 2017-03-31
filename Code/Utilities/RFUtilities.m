//
//  RFUtilities.m
//  Pods
//
//  Created by Jeff Sinckler on 1/19/16.
//
//

#import "RFUtilities.h"
#import <sys/utsname.h>

@implementation RFUtilities
+ (NSString *)scripturl
{
    return @"https://www.riffsy.com";
}

+ (NSString *)messageUrl
{
    return @"https://msg.riffsy.com";
}

+(NSString *)newApiUrlBase
{
    return @"https://api.riffsy.com";
}

+ (NSString *)pageurl:(NSString *)path
{
    if(![path containsString:[self scripturl]])
        return [[self scripturl] stringByAppendingString:path];
    else
        return path;
}

+ (NSString *)messagingUrl:(NSString *)path
{
    return [[self messageUrl] stringByAppendingString:path];
}

+ (NSString *)apiurl:(NSString *)path
{
    return [[self scripturl] stringByAppendingFormat:@"/api/v1%@", path];
}

+ (NSString *)newApiUrl:(NSString *)path
{
    return [[self newApiUrlBase] stringByAppendingString:path];
}

+(NSString *)constructUrlWithBaseURL:(NSString *)base andParameters:(NSDictionary *)parameters
{
    NSString *query = base;
    if (parameters && [parameters count]) {
        NSMutableArray *ps = [NSMutableArray new];
        NSCharacterSet *allowedCharacters = [self allowedQueryCharacters];
        for (NSString *key in parameters) {
            [ps addObject:[NSString stringWithFormat:@"%@=%@",
                           [key stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters],
                           [parameters[key] stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters]]];
        }
        query = [query stringByAppendingFormat:@"?%@",[ps componentsJoinedByString:@"&"]];
    }
    
    return query;
}

+ (NSCharacterSet *)allowedQueryCharacters {
    NSMutableCharacterSet *URLQueryPartAllowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [URLQueryPartAllowedCharacterSet removeCharactersInRange:NSMakeRange('&', 1)];
    [URLQueryPartAllowedCharacterSet removeCharactersInRange:NSMakeRange('=', 1)];
    [URLQueryPartAllowedCharacterSet removeCharactersInRange:NSMakeRange('?', 1)];
    [URLQueryPartAllowedCharacterSet removeCharactersInRange:NSMakeRange('+', 1)];
    return URLQueryPartAllowedCharacterSet;
}

+ (NSURLSessionConfiguration *)sessionConfiguration:(NSDictionary *)headers {
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSMutableDictionary *httpHeaders = [NSMutableDictionary dictionaryWithDictionary:@{@"User-Agent":[RFUtilities userAgent]}];
    if (headers) {
        [httpHeaders addEntriesFromDictionary:headers];
        config.HTTPAdditionalHeaders = httpHeaders;
    }
    config.HTTPAdditionalHeaders = httpHeaders;
    return config;
}

+ (NSString *)userAgent {
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *deviceName = [NSString stringWithCString:systemInfo.machine
                                              encoding:NSUTF8StringEncoding];
    
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    return [NSString stringWithFormat:@"%@/%@ (%@; iOS %@)",info[@"CFBundleName"],info[@"CFBundleShortVersionString"],deviceName,info[@"DTPlatformVersion"]];
}

@end
