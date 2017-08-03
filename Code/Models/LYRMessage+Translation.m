//
//  LYRMessage+Translation.m
//  Events 3.0
//
//  Created by Blake Watters on 12/30/16.
//  Copyright © 2016 World Economic Forum. All rights reserved.
//

#import <objc/runtime.h>
#import "LYRMessage+Translation.h"

static NSCache *LYRMessageTranslationCache(void)
{
    static dispatch_once_t onceToken;
    static NSCache *messageTranslationCache;
    dispatch_once(&onceToken, ^{
        messageTranslationCache = [NSCache new];
    });
    return messageTranslationCache;
}

@implementation LYRMessage (Translation)

- (NSString *)translatedText
{
    return [LYRMessageTranslationCache() objectForKey:self.identifier];
}

- (void)setTranslatedText:(NSString *)translatedText
{
    [LYRMessageTranslationCache() setObject:translatedText forKey:self.identifier];
}

@end
