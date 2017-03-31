//
//  RFObject.m
//  Atlas
//
//  Created by Jeff on 4/6/15.
//  Copyright (c) 2015 Jeff. All rights reserved.
//

#import "RFObject.h"

@implementation RFObject

-(instancetype)initWithData:(NSDictionary *)data
{
    self = [self init];
    if(self)
    {
        _rfIdentifier = data[@"id"];
        _userPosterIdentifier = data[@"posterkey"][1];
        NSString *titleRead = data[@"title"];
        
        if(titleRead && [titleRead isKindOfClass:[NSString class]])
            _title = titleRead;
        
        _shortUrl = data[@"shorturl"];
        NSArray *tagArray = data[@"tags"];
        
        if(tagArray && [tagArray isKindOfClass:[NSArray class]])
            _tags = [NSArray arrayWithArray:tagArray];
        
        NSDictionary *riffData = data[@"riff"];
        _compositeVideoUrl = riffData[@"videourl"];
        _compositePreview = riffData[@"previewurl"];
        _audioVideoUrl = riffData[@"avurl"];
        _hasAudio = (_audioVideoUrl != nil);
        CGFloat width = [riffData[@"dims"][0] integerValue];
        CGFloat height = [riffData[@"dims"][1] integerValue];
        _dimensions = CGSizeMake(width, height);
        _embedCode = data[@"embed"];
        
        NSArray *sceneList = riffData[@"scenes"];
        _scenes = [NSMutableArray new];
        for(NSDictionary *sceneDict in sceneList)
        {
            RFMedia *media = [[RFMedia alloc] initWithDictionary:sceneDict];
            [_scenes addObject:media];
        }
    }
    return self;
}

-(instancetype)initWithNewAPIData:(NSDictionary *)data
{
    self = [self init];
    if(self)
    {
        _rfIdentifier = data[@"id"];
        _hasAudio = [data[@"hasaudio"] boolValue];
        _tags = data[@"tags"];
        _title = data[@"title"];
        _shortUrl = data[@"url"];
        
        NSArray *mediaList = data[@"media"];
        NSDictionary *mediaDictionary = mediaList[0];
        [self configureMedia:mediaDictionary];
    }
    return self;
}

-(void)configureMedia:(NSDictionary *)mediaDictionary
{
    if(mediaDictionary[@"gif"])
        _gifMedia = [[RFMediaElement alloc] initWithDictionary:mediaDictionary[@"gif"]];
    if(mediaDictionary[@"loopedmp4"])
        _loopedMP4Media = [[RFMediaElement alloc] initWithDictionary:mediaDictionary[@"loopedmp4"]];
    if(mediaDictionary[@"mp4"])
        _mp4Media = [[RFMediaElement alloc] initWithDictionary:mediaDictionary[@"mp4"]];
    if(mediaDictionary[@"nanogif"])
        _nanogifMedia = [[RFMediaElement alloc] initWithDictionary:mediaDictionary[@"nanogif"]];
    if(mediaDictionary[@"nanomp4"])
        _nanoMP4Media = [[RFMediaElement alloc] initWithDictionary:mediaDictionary[@"nanomp4"]];
    if(mediaDictionary[@"nanowebm"])
        _nanowebm = [[RFMediaElement alloc] initWithDictionary:mediaDictionary[@"nanowebm"]];
    if(mediaDictionary[@"tinygif"])
        _tinygifMedia = [[RFMediaElement alloc] initWithDictionary:mediaDictionary[@"tinygif"]];
    if(mediaDictionary[@"tinymp4"])
        _tinyMP4Media = [[RFMediaElement alloc] initWithDictionary:mediaDictionary[@"tinymp4"]];
    if(mediaDictionary[@"tinywebm"])
        _tinywebmMedia = [[RFMediaElement alloc] initWithDictionary:mediaDictionary[@"tinywebm"]];
    if(mediaDictionary[@"webm"])
        _webmMedia = [[RFMediaElement alloc] initWithDictionary:mediaDictionary[@"webm"]];
}

-(NSString *)description
{
    NSString *desc = [NSString stringWithFormat:@"{\r   Riff Identifier: %@ \r", self.rfIdentifier];
    desc = [desc stringByAppendingFormat:@"   Riff Title: %@\r", self.title];
    desc = [desc stringByAppendingFormat:@"   Short URL: %@\r", self.shortUrl];
    desc = [desc stringByAppendingFormat:@"   Video URL: %@\r", self.compositeVideoUrl];
    desc = [desc stringByAppendingFormat:@"   Preview URL: %@\r", self.compositePreview];
    desc = [desc stringByAppendingFormat:@"   Riff Has Audio: %@\r", self.hasAudio ? @"YES" : @"NO"];
    desc = [desc stringByAppendingFormat:@"   Riff Tags: %@\r", self.tags];
    desc = [desc stringByAppendingFormat:@"   Riff Dimensions: (%f,%f)\r", self.dimensions.width, self.dimensions.height];
    desc = [desc stringByAppendingFormat:@"   Scenes: %@\r", self.scenes];
    desc = [desc stringByAppendingFormat:@"   Small Gif URL: %@\r", [self getSmallGifUrl]];
    desc = [desc stringByAppendingFormat:@"   Large GIF URL: %@\r", [self getLargeGifUrl]];
    desc = [desc stringByAppendingFormat:@"   Video URL: %@\r}", [self getVideoUrl]];
    
    return desc;
}

#pragma mark - <NSCoding> methods
- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_rfIdentifier forKey:@"rfIdentifier"];
    [encoder encodeObject:_title forKey:@"title"];
    [encoder encodeObject:_shortUrl forKey:@"shortUrl"];
    [encoder encodeObject:_compositeVideoUrl forKey:@"compositeVideoUrl"];
    [encoder encodeObject:_compositePreview forKey:@"compositePreview"];
    [encoder encodeObject:_audioVideoUrl forKey:@"audioVideoUrl"];
    [encoder encodeBool:_hasAudio forKey:@"hasAudio"];
    [encoder encodeObject:_tags forKey:@"tags"];
    [encoder encodeObject:[NSValue valueWithCGSize:_dimensions] forKey:@"dimensions"];
    [encoder encodeObject:_embedCode forKey:@"embedCode"];
    [encoder encodeObject:_scenes forKey:@"scenes"];
}

-(id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if(self)
    {
        _rfIdentifier = [decoder decodeObjectForKey:@"rfIdentifier"];
        _title = [decoder decodeObjectForKey:@"title"];
        _shortUrl = [decoder decodeObjectForKey:@"shortUrl"];
        _compositeVideoUrl = [decoder decodeObjectForKey:@"compositeVideoUrl"];
        _compositePreview = [decoder decodeObjectForKey:@"compositePreview"];
        _audioVideoUrl = [decoder decodeObjectForKey:@"audioVideoUrl"];
        _hasAudio = [decoder decodeBoolForKey:@"hasAudio"];
        _tags = [decoder decodeObjectForKey:@"tags"];
        _dimensions = [(NSValue *)[decoder decodeObjectForKey:@"dimensions"] CGSizeValue];
        _scenes = [decoder decodeObjectForKey:@"scenes"];
        _embedCode = [decoder decodeObjectForKey:@"embedCode"];
    }
    
    return self;
}

#pragma mark - Getter Overrides
-(CGSize)dimensions
{
    if(_tinygifMedia)
        return _tinygifMedia.dimensions;
    else if(_gifMedia)
        return _gifMedia.dimensions;
    else
        return CGSizeMake(180, 90);
}

#pragma mark - URL Helpers
-(NSString *)getSmallGifUrl
{
    if(_tinygifMedia)
        return _tinygifMedia.assetUrl;
    else if(_gifMedia)
        return _gifMedia.assetUrl;
    else
        return nil;
}

-(NSString *)getLargeGifUrl
{
    RFMedia *media = (RFMedia *)self.scenes[0];
    return media.gif.assetUrl;
}

-(NSString *)getVideoUrl
{
    RFMedia *media = (RFMedia *)self.scenes[0];
    return media.mp4.assetUrl;
}

@end
