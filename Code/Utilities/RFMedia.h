//
//  RFMedia.h
//  GifKeyboardSDK
//
//  Created by Jeff on 4/22/15.
//  Copyright (c) 2015 Jeff. All rights reserved.
//

#import <Foundation/Foundation.h>

@import UIKit;

@interface RFMediaElement : NSObject

@property (nonatomic, retain) NSString *assetUrl;
@property (nonatomic, retain) NSString *previewUrl;
@property CGFloat duration;
@property CGSize dimensions;

-(instancetype)initWithDictionary:(NSDictionary *)dataDict;

@end

@interface RFMedia : NSObject

@property (nonatomic, retain) RFMediaElement *smallGif;
@property (nonatomic, retain) RFMediaElement *gif;

//TODO name these video properties something better?
@property (nonatomic, retain) RFMediaElement *mp4;
@property (nonatomic, retain) RFMediaElement *webm;

-(instancetype)initWithDictionary:(NSDictionary *)dataDict;
@end
