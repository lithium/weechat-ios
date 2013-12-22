//
//  WeechatData.m
//  Weechat
//
//  Created by Wiggins on 12/21/13.
//  Copyright (c) 2013 Hlidskialf. All rights reserved.
//

#import "WeechatMessage.h"
#import "GZIP.h"

@implementation WeechatMessage
{
    NSUInteger _yankOffset;
    NSData *_data;
    NSString *_messageId;
    uint32_t _length;
    BOOL _compressed;
    NSMutableArray *_objects;
}

+ (id)messageWithData:(NSData*)data
{
    return [[WeechatMessage alloc] initWithData:data];
}

- (id)initWithData:(NSData*)data
{
#define kHeaderSize 5
    if (self) {
        _yankOffset = 0;
        _data = data;
        
        _length = [self yankInt];
        _compressed = [self yankChar];

        // reset _data to just past header
        _data = [NSData dataWithBytes:[_data bytes]+kHeaderSize length:_length-kHeaderSize];
        _yankOffset = 0;
    
        if (_compressed) {
            _data = [_data gunzippedData];
        }
        
        // parse message
        _messageId = [self yankString];
        _objects = [[NSMutableArray alloc] init];
        while (_yankOffset+kHeaderSize < _length) {
            NSString *type = [self yankType];
            id value = [self yankObjectWithType:type];
            [_objects addObject:value];
        }
    }
    return self;
}

- (NSString*)messageId
{
    return _messageId;
}

- (NSArray*)objects
{
    return _objects;
}

- (SInt8)yankChar
{
    SInt8 *ret = (SInt8*)[_data bytes] + _yankOffset;
    _yankOffset += 1;
    return *ret;
}
- (NSNumber*)yankCharacter
{
    return [NSNumber numberWithChar:[self yankChar]];
}

- (SInt32)yankInt
{
    uint8_t *bytes = (uint8_t*)([_data bytes] + _yankOffset);
    uint32_t ret = bytes[0] << 24 | bytes[1] << 16 | bytes[2] <<8 | bytes[3];
    _yankOffset += 4;
    return ret;
}
- (NSNumber*)yankInteger
{
    return [NSNumber numberWithInteger:[self yankInt]];
}
- (NSNumber*)yankLong
{
    SInt8 length = [self yankChar];
    NSData *data = [NSData dataWithBytesNoCopy:[_data bytes]+_yankOffset length:length];
    _yankOffset += length;
    return [NSNumber numberWithLongLong:[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] longLongValue]];
}

- (NSString*)yankString
{
    SInt32 length = [self yankInt];
    if (length == -1)
        return nil;
    NSData *data = [NSData dataWithBytes:[_data bytes]+_yankOffset length:length];
    _yankOffset += length;
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSString*)yankType
{
    NSData *data = [NSData dataWithBytesNoCopy:[_data bytes]+_yankOffset length:3];
    _yankOffset += 3;
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSData*)yankBuffer
{
    int length = [self yankInt] ;
    if (length == -1)
        return nil;
    NSData *data = [NSData dataWithBytesNoCopy:[_data bytes]+_yankOffset length:length];
    _yankOffset += length;
    return data;
}

- (NSString*)yankPointer
{
    SInt8 length = [self yankChar];
    NSData *data = [NSData dataWithBytesNoCopy:[_data bytes]+_yankOffset length:length];
    _yankOffset += length;
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return str;
}

- (NSNumber*)yankTime
{
    NSString *str = [self yankPointer];
    return [NSNumber numberWithLongLong:[str longLongValue]];
}


static NSDictionary *yankTable = nil;
- (id)yankObjectWithType:(NSString*)keyType
{
    if (yankTable == nil) {
        yankTable = [NSDictionary dictionaryWithObjectsAndKeys:
                     [NSValue valueWithPointer:@selector(yankCharacter)], @"chr",
                     [NSValue valueWithPointer:@selector(yankInteger)], @"int",
                     [NSValue valueWithPointer:@selector(yankLong)], @"lon",
                     [NSValue valueWithPointer:@selector(yankString)], @"str",
                     [NSValue valueWithPointer:@selector(yankBuffer)], @"buf",
                     [NSValue valueWithPointer:@selector(yankPointer)], @"ptr",
                     [NSValue valueWithPointer:@selector(yankTime)], @"tim",
                     [NSValue valueWithPointer:@selector(yankHashtable)], @"htb",
                     [NSValue valueWithPointer:@selector(yankHdata)], @"hda",
                     [NSValue valueWithPointer:@selector(yankInfo)], @"inf",
                     [NSValue valueWithPointer:@selector(yankInfolist)], @"inl",
                     [NSValue valueWithPointer:@selector(yankArray)], @"arr",
                     nil];
    }
    
    SEL selector = [[yankTable objectForKey:keyType] pointerValue];
    if (selector) {
        IMP imp = [self methodForSelector:selector];
        return imp(self, selector);
    }
    return nil;
}

- (NSDictionary *)yankHashtable
{
    NSString *keyType = [self yankType];
    NSString *valueType = [self yankType];
    int count = [[self yankInteger] intValue];
    NSMutableDictionary *ret = [[NSMutableDictionary alloc] initWithCapacity:count];
    for (int i=0; i < count; i++) {
        id key = [self yankObjectWithType:keyType];
        id value = [self yankObjectWithType:valueType];
        [ret setObject:value forKey:key];
    }
    return ret;
}

- (id)yankHdata
{
    NSString *hpath = [self yankString];
    int pathCount = [[hpath componentsSeparatedByString:@"/"] count];
    
    NSString *keySpecifier = [self yankString];
    NSArray *keytypes = [keySpecifier componentsSeparatedByString:@","];
    
    int count = [self yankInt];
    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:count];
    
    while (--count >= 0) {
        NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
        NSMutableArray *ppath = [[NSMutableArray alloc] initWithCapacity:pathCount];
        for (int i=0; i < pathCount; i++) {
            [ppath addObject:[self yankPointer]];
        }
        [item setObject:ppath forKey:@"p-path"];
        
        [keytypes enumerateObjectsUsingBlock:^(id keytype, NSUInteger idx, BOOL *stop) {
            NSArray *parts = [keytype componentsSeparatedByString:@":"];
            [item setObject:[self yankObjectWithType:[parts objectAtIndex:1]] forKey:[parts objectAtIndex:0]];
        }];
        
        [items addObject:item];
    }
    
    NSMutableDictionary *ret = [[NSMutableDictionary alloc] initWithCapacity:3];
    [ret setObject:hpath forKey:@"h-path"];
    [ret setObject:items forKey:@"items"];
    return ret;

}

- (id)yankInfo
{
    return nil;
}

- (NSArray*)yankInfolist
{
    //TODO: don't discard infolist name...
    NSString *infolistName = [self yankString];
    int count = [self yankInt];
    NSMutableArray *ret = [[NSMutableArray alloc] initWithCapacity:count];
    while (--count >= 0) {
        int itemCount = [self yankInt];
        NSMutableDictionary *item = [[NSMutableDictionary alloc] initWithCapacity:itemCount];
        while (--itemCount >= 0) {
            NSString *key = [self yankString];
            NSString *type = [self yankType];
            id value = [self yankObjectWithType:type];
            [item setObject:value forKey:key];
        }
        [ret addObject:item];
    }
    return ret;
}

- (NSArray*)yankArray
{
    NSString *type = [self yankType];
    int count = [self yankInt];
    NSMutableArray *ret = [[NSMutableArray alloc] initWithCapacity:count];
    while (--count >= 0) {
        [ret addObject:[self yankObjectWithType:type]];
    }
    return ret;
}
@end

