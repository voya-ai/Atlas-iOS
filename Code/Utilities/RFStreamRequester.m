//
//  GKRequester.m
//  GifKeyboardSDK
//
//  Created by Jeff on 4/14/15.
//  Copyright (c) 2015 Jeff. All rights reserved.
//

#import "RFStreamRequester.h"
#import "RFUtilities.h"

@implementation RFStreamRequester

#pragma mark - Class Initializers
+(instancetype)getRequesterForTag:(RFTag *)tag
{
  RFStreamRequester *streamRequester = [[RFStreamRequester alloc] initWithStreamID:tag.categoryContentStreamID];
  return streamRequester;
}

+(instancetype)getRequesterRelatedTo:(RFObject *)object
{
  NSString *streamID = [RFUtilities apiurl:@"/stream/special/related"];
  RFStreamRequester *streamRequester = [[RFStreamRequester alloc] initWithStreamID:streamID andRelatedRiffID:object.rfIdentifier];
  return streamRequester;
}

+(instancetype)getRequesterForSearchTerm:(NSString *)term
{
  NSString *streamID = [RFUtilities newApiUrl:[NSString stringWithFormat:@"/v1/search"]];
    RFStreamRequester *streamRequester = [[RFStreamRequester alloc] initWithStreamID:streamID
                                                                andGenericParameters:@{@"tag" : term}];
  return streamRequester;
}

+(instancetype)getRequesterForTerms:(NSArray *)terms
{
  NSString *searchRequestUrl = @"/v1/intersection";
  NSString *streamID = [RFUtilities newApiUrl:searchRequestUrl];
  RFStreamRequester *streamRequester = [[RFStreamRequester alloc] initWithStreamID:streamID
                                                              andGenericParameters:@{@"tag1" : terms[0],
                                                                                     @"tag2" : terms[1],
                                                                                     @"responsetype" : @"iosgk"} andAPITarget:APITargetNew];
  return streamRequester;
}

#pragma mark - Init Functions
-(instancetype)init
{
  self = [super init];
  if(self)
  {
    relatedRiffID = nil;
    streamPosition = @"";
    shouldFetchExtra = NO;
    _apiTarget = APITargetOld;
  }
  
  return self;
}

-(instancetype)initWithStreamID:(NSString *)sid
{
  self = [self init];
  if(self)
  {
    streamID = [sid stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  }
  return self;
}

-(instancetype)initWithStreamID:(NSString *)sid andGenericParameters:(NSDictionary *)extraParameters
{
  self = [self initWithStreamID:sid];
  if(self)
  {
    genericParameters = [NSMutableDictionary dictionaryWithDictionary:extraParameters];
  }
  
  return self;
}

-(instancetype)initWithStreamID:(NSString *)sid
           andGenericParameters:(NSDictionary *)extraParameters
                   andAPITarget:(APITarget)target
{
  self = [self initWithStreamID:sid andGenericParameters:extraParameters];
  if(self)
  {
    _apiTarget = target;
  }
  
  return self;
}

-(instancetype)initWithStreamID:(NSString *)sid andRelatedRiffID:(NSString *)rrid
{
  self = [self initWithStreamID:sid];
  if(self)
  {
    relatedRiffID = rrid;
  }
  return self;
}

#pragma mark - Setter Methods
-(void)setExclusionParameters:(NSDictionary *)exclData
{
  exclusionParameters = exclData;
}

#pragma mark - Functionality
-(void)fetch:(RFRequesterCallback)callback
{
  NSDictionary *requestParameters = [self constructParameters];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[RFUtilities sessionConfiguration:nil]];
    NSString *fullUrl = [RFUtilities constructUrlWithBaseURL:streamID andParameters:requestParameters];
    fetchTask = [session dataTaskWithURL:[NSURL URLWithString:fullUrl] completionHandler:^(NSData * _Nullable data,
                                                                                           NSURLResponse * _Nullable response,
                                                                                           NSError * _Nullable error) {
        if(error || !data)
            callback(NO, nil, nil);
        else
        {
            NSMutableArray *content = [NSMutableArray new];
            
            NSError *jsonError = nil;
            NSDictionary *parsedResponse = [NSJSONSerialization JSONObjectWithData:data
                                                                           options:NSJSONReadingMutableContainers
                                                                             error:&jsonError];
            if(jsonError)
                callback(NO, nil, nil);
            
            NSArray *rawContentDataList = parsedResponse[@"results"];
            for(NSDictionary *dataDictionary in rawContentDataList)
            {
                RFObject *gif = [[RFObject alloc] initWithNewAPIData:dataDictionary];
                [content addObject:gif];
            }
          
          callback(YES, content, parsedResponse);
        }
    }];
    [fetchTask resume];
}

-(void)cancelRequest
{
  if(fetchTask)
    [fetchTask cancel];
}

-(void)reset
{
  streamPosition = @"";
  skipAmount = 0;
}

#pragma mark - Data Constructing
-(NSDictionary *)constructParameters
{
  NSMutableDictionary *parametersDictionary = [NSMutableDictionary new];
  if(self.apiTarget == APITargetOld)
  {
    if(currentStreamType == StreamTypeStream)
      [parametersDictionary addEntriesFromDictionary:@{@"begin" : streamPosition,
                                                       @"mode" : [self getModeParameterString]}];
    else
      [parametersDictionary addEntriesFromDictionary:@{@"skip" : [NSString stringWithFormat:@"%lu", (unsigned long)skipAmount],
                                                       @"mode" : [self getModeParameterString],
                                                       @"showdupes" : @"false"}];
  }
  else
  {
    [parametersDictionary addEntriesFromDictionary:@{@"pos" : [NSString stringWithFormat:@"%lu", (unsigned long)skipAmount]}];
  }
  
  if(relatedRiffID)
    parametersDictionary[@"relatedpostid"] = relatedRiffID;
  
  if(genericParameters)
    [parametersDictionary addEntriesFromDictionary:genericParameters];
  
  return parametersDictionary;
}

#pragma mark - RFRequester Overrides
-(BOOL)canFetchMore
{
  return !endOfStream;
}

#pragma mark - Data Parsing
-(void)parseResultsType:(NSDictionary *)streamDictionary
{
  NSString *resultType = streamDictionary[@"resulttype"];
  resultType = [resultType lowercaseString];
  if([resultType isEqualToString:@"stream"])
    currentStreamType = StreamTypeStream;
  else if([resultType isEqualToString:@"search"])
    currentStreamType = StreamTypeSearch;
}

-(void)parseNextStreamData:(NSDictionary *)streamDictionary
{
  if(currentStreamType == StreamTypeStream)
    streamPosition = streamDictionary[@"end"];
  else if(currentStreamType == StreamTypeSearch)
  {
    NSArray *ids = streamDictionary[@"ids"];
    skipAmount += [ids count];
  }
  
  endOfStream = ![streamDictionary[@"moreafter"] boolValue];
}

-(void)parseExtraData:(NSDictionary *)streamDictionary
{
  shouldFetchExtra = [[streamDictionary objectForKey:@"fetchextra"] boolValue];
}

-(NSMutableArray *)applyExclusionToContent:(NSArray *)content
{
  NSMutableArray *modifiedContent = [NSMutableArray arrayWithArray:content];
  
  NSString *usernameExlusionIdentifier = exclusionParameters[USERID_EXCLUSION_KEY];
  if(usernameExlusionIdentifier)
  {
    for(RFObject *obj in content)
    {
      if([obj.userPosterIdentifier isEqualToString:usernameExlusionIdentifier])
        [modifiedContent removeObject:obj];
    }
  }
  
  return modifiedContent;
}

#pragma mark - Data Wrappers/Helpers
-(BOOL)shouldFetchExtra
{
  return shouldFetchExtra;
}

@end
