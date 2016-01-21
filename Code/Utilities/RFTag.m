//
//  GKCategory.m
//  GifKeyboardSDK
//
//  Created by Jeff on 4/14/15.
//  Copyright (c) 2015 Jeff. All rights reserved.
//

#import "RFTag.h"

@implementation RFTag

-(instancetype)initWithDictionary:(NSDictionary *)dataDict
{
  self = [self init];
  if(self)
  {
    self.categoryTitle = dataDict[@"name"];
    self.categoryCoverGifURL = dataDict[@"image"];
    self.categoryContentStreamID = dataDict[@"stream"];
    self.additionalResultTag = dataDict[@"tag"];
    self.messageToAttachForCopy = dataDict[@"copymsg"];
    self.prioritizeOnFirstLoad = [dataDict[@"firstloadpriority"] boolValue];
  }
  return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if(self)
  {
    _categoryTitle = [aDecoder decodeObjectForKey:@"categoryTitle"];
    _categoryCoverGifURL = [aDecoder decodeObjectForKey:@"categoryCoverGIFURL"];
    _categoryContentStreamID = [aDecoder decodeObjectForKey:@"categoryContentStreamID"];
    _additionalResultTag = [aDecoder decodeObjectForKey:@"additionalResultTag"];
    _messageToAttachForCopy = [aDecoder decodeObjectForKey:@"messageToAttachForCopy"];
    _prioritizeOnFirstLoad = [aDecoder decodeBoolForKey:@"firstloadpriority"];
  }
  
  return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeObject:_categoryTitle forKey:@"categoryTitle"];
  [aCoder encodeObject:_categoryCoverGifURL forKey:@"categoryCoverGIFURL"];
  [aCoder encodeObject:_categoryContentStreamID forKey:@"categoryContentStreamID"];
  [aCoder encodeObject:_additionalResultTag forKey:@"additionalResultTag"];
  [aCoder encodeObject:_messageToAttachForCopy forKey:@"messageToAttachForCopy"];
  [aCoder encodeBool:_prioritizeOnFirstLoad forKey:@"firstloadpriority"];
}

-(NSString *)description
{
  NSString *desc = [NSString stringWithFormat:@"{\r   Title: %@ \r", self.categoryTitle];
  desc = [desc stringByAppendingFormat:@"   Cover GIF: %@\r", self.categoryCoverGifURL];
  desc = [desc stringByAppendingFormat:@"   Stream Identifier: %@\r", self.categoryContentStreamID];
  desc = [desc stringByAppendingFormat:@"   Additional Results Tag: %@\r", self.additionalResultTag];
  desc = [desc stringByAppendingFormat:@"   Message to attach: %@\r", self.messageToAttachForCopy];
  desc = [desc stringByAppendingFormat:@"   First load priority: %@\r}", self.prioritizeOnFirstLoad ? @"YES" : @"NO"];

  return desc;
}

-(BOOL)isEqual:(id)object
{
  if(self == object)
    return YES;
  
  if(![object isKindOfClass:[RFTag class]])
    return NO;
  
  return [self isEqualToRFTag:(RFTag *)object];
}

-(BOOL)isEqualToRFTag:(RFTag *)riffObject
{
  if(!riffObject) {
    return NO;
  }
  
  BOOL isEqual = [self.categoryTitle isEqualToString:riffObject.categoryTitle];
  isEqual &= [self.categoryCoverGifURL isEqualToString:riffObject.categoryCoverGifURL];
  isEqual &= [self.categoryContentStreamID isEqualToString:riffObject.categoryContentStreamID];
  isEqual &= [self.additionalResultTag isEqualToString:riffObject.additionalResultTag];
  return isEqual;
}

@end
