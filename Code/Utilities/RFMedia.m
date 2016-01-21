//
//  RFMedia.m
//  GifKeyboardSDK
//
//  Created by Jeff on 4/22/15.
//  Copyright (c) 2015 Jeff. All rights reserved.
//

#import "RFMedia.h"

@implementation RFMediaElement

-(instancetype)initWithDictionary:(NSDictionary *)dataDict
{
  self = [self init];
  if(self)
  {
    _assetUrl = dataDict[@"url"];
    _previewUrl = dataDict[@"preview"];
    _duration = [dataDict[@"duration"] floatValue];
    
    NSArray *dimensionsArray = dataDict[@"dims"];
    if(dimensionsArray.count > 1)
      _dimensions = CGSizeMake([dimensionsArray[0] integerValue], [dimensionsArray[1] integerValue]);
    else
      _dimensions = CGSizeZero;
  }
  return self;
}

-(NSString *)description
{
  NSString *desc = [NSString stringWithFormat:@"{\r   GIF URL: %@ \r", self.assetUrl];
  desc = [desc stringByAppendingFormat:@"   Preview URL: %@\r}", self.previewUrl];
  return desc;
}

#pragma mark - <NSCoding> methods
- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_assetUrl forKey:@"assetUrl"];
  [encoder encodeObject:_previewUrl forKey:@"previewUrl"];
}

-(id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if(self)
  {
    _assetUrl = [decoder decodeObjectForKey:@"assetUrl"];
    _previewUrl = [decoder decodeObjectForKey:@"previewUrl"];
  }
  
  return self;
}

@end

@implementation RFMedia

-(instancetype)initWithDictionary:(NSDictionary *)dataDict
{
  self = [self init];
  if(self)
  {
    NSString *gifUrl = dataDict[@"uncappedsupertinygifurl"];
    if(!gifUrl)
      gifUrl = dataDict[@"supertinygifurl"];
    if(!gifUrl)
      gifUrl = dataDict[@"tinygifurl"];
    if(!gifUrl)
      gifUrl = dataDict[@"gifurl"];
    
    _smallGif = [[RFMediaElement alloc] initWithDictionary:@{@"url" : gifUrl}];
    _gif = [[RFMediaElement alloc] initWithDictionary:@{@"url" : dataDict[@"gifurl"]}];
    _mp4 = [[RFMediaElement alloc] initWithDictionary:@{@"url" : dataDict[@"mp4url"]}];
    _webm = [[RFMediaElement alloc] initWithDictionary:@{@"url" : dataDict[@"webmurl"] ? dataDict[@"webmurl"] : @""}];;
  }
  return self;
}

-(NSString *)description
{
  NSString *desc = [NSString stringWithFormat:@"{\r   Small GIF: %@ \r", self.smallGif];
  desc = [desc stringByAppendingFormat:@"   Standard GIF: %@\r", self.gif];
  desc = [desc stringByAppendingFormat:@"   MP4: %@\r", self.mp4];
  desc = [desc stringByAppendingFormat:@"   webm: %@\r}", self.webm];
  return desc;
}

#pragma mark - <NSCoding> methods
- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_smallGif forKey:@"smallGif"];
  [encoder encodeObject:_gif forKey:@"gif"];
  [encoder encodeObject:_mp4 forKey:@"mp4"];
  [encoder encodeObject:_webm forKey:@"webm"];
}

-(id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if(self)
  {
    _smallGif = [decoder decodeObjectForKey:@"smallGif"];
    _gif = [decoder decodeObjectForKey:@"gif"];
    _mp4 = [decoder decodeObjectForKey:@"mp4"];
    _webm = [decoder decodeObjectForKey:@"webm"];
  }
  
  return self;
}

@end
