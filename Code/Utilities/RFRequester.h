//
//  RFRequester.h
//  Atlas
//
//  Created by Jeff on 4/22/15.
//  Copyright (c) 2015 Jeff. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    APIModeBest = 0,
    APIModeText,
    APIModeFeatured,
} APIMode;

typedef void (^RFRequesterCallback)(BOOL success,
NSArray *contentList,
NSDictionary *fullDictionary);

@interface RFRequester : NSObject {
    NSString *streamID;
    APIMode mode;
    
    NSURLSessionDataTask *fetchTask;
    
    //general purpose parameters dictionary
    NSMutableDictionary *genericParameters;
}

-(BOOL)canFetchMore;
-(BOOL)shouldFetchExtra;
-(NSString *)getStreamID;
-(void)fetch:(RFRequesterCallback)callback;
-(void)cancelRequest;
-(void)reset;
-(void)addGenericParameters:(NSDictionary *)generics;

-(void)setMode:(APIMode)newMode;
-(NSString *)getModeParameterString;

@end
