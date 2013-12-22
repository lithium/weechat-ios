//
//  WeechatData.h
//  Weechat
//
//  Created by Wiggins on 12/21/13.
//  Copyright (c) 2013 Hlidskialf. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WeechatMessage : NSObject

+ (id)messageWithData:(NSData*)data;
- (id)initWithData:(NSData*)data;

- (NSString*)messageId;
- (NSArray*)objects;

- (SInt8)yankChar;
- (NSNumber*)yankCharacter;
- (SInt32)yankInt;
- (NSNumber*)yankInteger;
- (NSNumber*)yankLong;
- (NSString*)yankString;
- (NSString*)yankType;
- (NSData*)yankBuffer;
- (NSString*)yankPointer;
- (NSNumber*)yankTime;
- (id)yankObjectWithType:(NSString*)keyType;
- (NSDictionary *)yankHashtable;
- (id)yankHdata;
- (id)yankInfo;
- (NSArray*)yankInfolist;
- (NSArray*)yankArray;

@end
