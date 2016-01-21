//
//  GKObject.h
//  GifKeyboardSDK
//
//  Created by Jeff on 4/6/15.
//  Copyright (c) 2015 Jeff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RFMedia.h"

@import UIKit;

@interface RFObject : NSObject {
    @protected
    NSString *_rfIdentifier;
    NSString *_userPosterIdentifier;
    NSString *_title;
    NSString *_shortUrl;
    NSString *_compositeVideoUrl;
    NSString *_compositePreview;
    NSString *_audioVideoUrl;
    NSString *_embedCode;
    BOOL _hasAudio;
    NSArray *_tags;
    CGSize _dimensions;
    NSMutableArray *_scenes;
}

@property(nonatomic,readonly) NSString *rfIdentifier;
@property(nonatomic,readonly) NSString *userPosterIdentifier;
@property(nonatomic,readonly) NSString *title;
@property(nonatomic,readonly) NSString *shortUrl;
@property(nonatomic,readonly) NSString *compositeVideoUrl;
@property(nonatomic,readonly) NSString *compositePreview;
@property(nonatomic,readonly) NSString *audioVideoUrl;
@property(nonatomic,readonly) NSString *embedCode;
@property(nonatomic,readonly) BOOL hasAudio;
@property(nonatomic,readonly) NSArray *tags;
@property(nonatomic,readonly) CGSize dimensions;
@property(nonatomic,readonly) NSMutableArray *scenes; //array of RFMedia

//new API values
@property(nonatomic,readonly) RFMediaElement *gifMedia;
@property(nonatomic,readonly) RFMediaElement *loopedMP4Media;
@property(nonatomic,readonly) RFMediaElement *mp4Media;
@property(nonatomic,readonly) RFMediaElement *nanogifMedia;
@property(nonatomic,readonly) RFMediaElement *nanoMP4Media;
@property(nonatomic,readonly) RFMediaElement *nanowebm;
@property(nonatomic,readonly) RFMediaElement *tinygifMedia;
@property(nonatomic,readonly) RFMediaElement *tinyMP4Media;
@property(nonatomic,readonly) RFMediaElement *tinywebmMedia;
@property(nonatomic,readonly) RFMediaElement *webmMedia;

/* Instantiation from a dictionary
 */
-(instancetype)initWithData:(NSDictionary *)data;

/* Instantiation from a dictionary from the new API
 */
-(instancetype)initWithNewAPIData:(NSDictionary *)data;

/* Basic URL pulling
 */
-(NSString *)getSmallGifUrl;
-(NSString *)getLargeGifUrl;
-(NSString *)getVideoUrl;

/* NSCoding methods
 */
- (void)encodeWithCoder:(NSCoder *)encoder;
- (id)initWithCoder:(NSCoder *)decoder;

@end
