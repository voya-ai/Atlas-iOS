//
//  RFRequester.m
//  Atlas
//
//  Created by Jeff on 4/22/15.
//  Copyright (c) 2015 Jeff. All rights reserved.
//

#import "RFRequester.h"

@implementation RFRequester

-(instancetype)init
{
    self = [super init];
    if(self)
    {
        genericParameters = [NSMutableDictionary new];
        mode = APIModeBest;
    }
    return self;
}

-(void)setMode:(APIMode)newMode
{
    mode = newMode;
}

-(NSString *)getModeParameterString
{
    switch (mode) {
        case APIModeBest:
            return @"best";
            break;
        case APIModeText:
            return @"text";
            break;
        case APIModeFeatured:
            return @"featured";
            break;
        default:
            return @"text";
            break;
    }
}

-(BOOL)canFetchMore
{
    //Default implementation. Override in subclass.
    return NO;
}

-(BOOL)shouldFetchExtra
{
    //Default implementation. Override in subclass.
    return NO;
}

-(NSString *)getStreamID
{
    return streamID;
}

-(void)addGenericParameters:(NSDictionary *)generics
{
    [genericParameters addEntriesFromDictionary:generics];
}

-(void)fetch:(RFRequesterCallback)callback
{
    //Default implementation. Override in subclass.
    NSAssert(YES, @"This method should only be called from a subclass override.");
}

-(void)cancelRequest
{
    //Default implementation. Override in subclass.
    NSAssert(YES, @"This method should only be called from a subclass override.");
}

-(void)reset
{
    //Default implementation. Override in subclass.
    NSAssert(YES, @"This method should only be called from a subclass override.");
}
@end
