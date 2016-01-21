//
//  GKRequester.h
//  GifKeyboardSDK
//
//  Created by Jeff on 4/14/15.
//  Copyright (c) 2015 Jeff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RFTag.h"
#import "RFObject.h"
#import "RFRequester.h"

#define USERID_EXCLUSION_KEY @"usernameExclusion"

typedef enum {
  StreamTypeStream = 0,
  StreamTypeSearch,
} StreamType;

typedef enum {
  APITargetOld = 0,
  APITargetNew,
} APITarget;

@interface RFStreamRequester : RFRequester {
  NSUInteger numberItemsFetched;
  NSString *streamEndPosition;
  StreamType currentStreamType;
  
  //general parameters
  BOOL shouldFetchExtra;
  
  //stream parameters
  NSString *streamPosition;
  
  //search parameters
  NSUInteger skipAmount;
  BOOL endOfStream;
  
  //related stream parameters
  NSString *relatedRiffID;
    
  //dictionaty that holds values used for exclusion
  NSDictionary *exclusionParameters;
}

@property (nonatomic, readonly) APITarget apiTarget;

/** Returns an instance of RFStreamRequester that is configured to return content for the given tag
 * @param tag the tag that the requester should retrieve content for.
 */
+(instancetype)getRequesterForTag:(RFTag *)tag;
/** Returns an instance of RFStreamRequester that is configured to return content related to the given object
 * @param object the RFObject that the requester should fetch related content for.
 */
+(instancetype)getRequesterRelatedTo:(RFObject *)object;
/** Returns an instance of RFStreamRequester that is configured to return content for a search term
 * @param term the search term to get content for.
 */
+(instancetype)getRequesterForSearchTerm:(NSString *)term;
/** Instantiate an RFStreamRequester configured to return intersection search results
 * @param terms list of terms to intersect
 */
+(instancetype)getRequesterForTerms:(NSArray *)terms;

-(instancetype)initWithStreamID:(NSString *)sid;
-(instancetype)initWithStreamID:(NSString *)sid andRelatedRiffID:(NSString *)rrid;
-(instancetype)initWithStreamID:(NSString *)sid andGenericParameters:(NSDictionary *)extraParameters andAPITarget:(APITarget)target;

/** Determines whether additional content should be pulled.
 */
-(BOOL)shouldFetchExtra;
/*
 */
-(NSDictionary *)constructParameters;
/** Configurable dictionary containing parameters for exclusion
 */
-(void)setExclusionParameters:(NSDictionary *)exclData;
/**
 */
-(NSMutableArray *)applyExclusionToContent:(NSArray *)content;

-(void)parseResultsType:(NSDictionary *)streamDictionary;
-(void)parseNextStreamData:(NSDictionary *)streamDictionary;
-(void)parseExtraData:(NSDictionary *)streamDictionary;

@end
