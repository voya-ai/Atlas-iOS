//
//  RFTag.h
//  Atlas
//
//  Created by Jeff on 4/14/15.
//  Copyright (c) 2015 Jeff. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RFTag : NSObject<NSCoding>

@property (nonatomic, retain) NSString *categoryTitle;
@property (nonatomic, retain) NSString *categoryCoverGifURL;
@property (nonatomic, retain) NSString *categoryContentStreamID;
@property (nonatomic, retain) NSString *additionalResultTag;
@property (nonatomic, retain) NSString *messageToAttachForCopy;
@property (nonatomic) BOOL prioritizeOnFirstLoad;

-(instancetype)initWithDictionary:(NSDictionary *)dataDict;

@end
