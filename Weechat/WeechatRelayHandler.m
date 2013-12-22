//
//  WeechatRelayHandler.m
//  Weechat
//
//  Created by Wiggins on 12/20/13.
//  Copyright (c) 2013 Hlidskialf. All rights reserved.
//

#import "WeechatRelayHandler.h"
#import "GZIP.h"
#import "WeechatMessage.h"

@implementation WeechatRelayHandler
{
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
    NSMutableData *outputBuffer;
    NSMutableData *inputBuffer;
}

- (id)init
{
    if (self) {
        outputBuffer = [NSMutableData dataWithCapacity:1024];
        inputBuffer = [NSMutableData dataWithCapacity:4096];
    }
    return self;
}

- (BOOL)connect
{
    NSString *hostname = [self hostname];
    NSString *password = [self password];
    if ([hostname length] < 1 || [password length] < 1) {
        return NO;
    }
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)hostname, [self port], &readStream, &writeStream);
    inputStream = (__bridge_transfer NSInputStream*)readStream;
    outputStream = (__bridge_transfer NSOutputStream*)writeStream;
    
    [inputStream setDelegate:self];
    [outputStream setDelegate:self];
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    //ssl
    if ([self useSSL]) {
        [inputStream setProperty:NSStreamSocketSecurityLevelTLSv1 forKey:NSStreamSocketSecurityLevelKey];
    }
    
    //queue up init message to immediately send after connecting
    [self sendCommand:@"init"
        withArguments:[NSString stringWithFormat:@"password=%@,compression=off", [self password]]
         andMessageId:nil];
    
    [self sendCommand:@"hdata"
        withArguments:@"buffer:gui_buffers(*) number,name"
          andSelector:@selector(bufferList:)];

    
    [inputStream open];
    [outputStream open];
    
    return YES;
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    
    switch (eventCode) {
        case NSStreamEventHasBytesAvailable:
        {
            //read available into inputBuffer
            while ([inputStream hasBytesAvailable]) {
                uint8_t buffer[1024];
                int read = [inputStream read:buffer maxLength:1024];
                [inputBuffer appendBytes:buffer length:read];
            }
            
            
            //dispatch all messages present in inputBuffer
            int available;
            while ((available = [inputBuffer length]) > 4) {
                uint8_t *bytes = (uint8_t*)[inputBuffer bytes];
                uint32_t length = bytes[0] << 24 | bytes[1] << 16 | bytes[2] <<8 | bytes[3];
                
                if (available < length) {
                    return; // not enough bytes yet
                }
                
                uint8_t compressed = *(uint8_t*)(bytes+4);
                NSData *data = [NSData dataWithBytes:bytes+5 length:length - 5];
                if (compressed == 1) {
                    data = [data gunzippedData];
                }
                
                //dispatch
                WeechatMessage *msg = [WeechatMessage messageWithData:inputBuffer];
                [self dispatchMessage:msg];
                
                // shift message out of buffer
                int remaining = available - length;
                [inputBuffer replaceBytesInRange:NSMakeRange(0, remaining)
                                       withBytes:[inputBuffer bytes]+length
                                          length:remaining];
                [inputBuffer setLength:remaining];
            }
            
            break;
        }
            
        case NSStreamEventHasSpaceAvailable:
        {
            //write ready
            if ([outputBuffer length] > 0) {
                [outputStream write:[outputBuffer bytes] maxLength:[outputBuffer length]];
                [outputBuffer setLength:0];
            }
            break;
        }

            
    }
}

- (void)dispatchMessage:(WeechatMessage*)message
{
    NSString *msgid = [message messageId];
    if ([msgid hasPrefix:@"SEL:"]) {
        SEL selector = NSSelectorFromString([msgid substringFromIndex:4]);
        if (selector) {
            id target = _delegate;
            if (target == nil || ![target respondsToSelector:selector]) {
                target = self;
            }
            IMP imp = [target methodForSelector:selector];
            void (*func)(id, SEL, WeechatMessage*) = (void*)imp;
            if (func) {
                func(target, selector, message);
            }
        }
    }
}

- (void)enqueueString:(NSString*)string
{
    [outputBuffer appendData:[string dataUsingEncoding:NSASCIIStringEncoding]];
}

- (void)sendCommand:(NSString*)command withArguments:(NSString *)arguments
{
    [self sendCommand:command withArguments:arguments andMessageId:nil];
}
- (void)sendCommand:(NSString*)command withArguments:(NSString *)arguments andMessageId:(NSString *)messageId
{
    if ([messageId length] > 0) {
        [self enqueueString:[NSString stringWithFormat:@"(%@) %@ %@\n", messageId, command, arguments]];
    }
    else {
        [self enqueueString:[NSString stringWithFormat:@"%@ %@\n", command, arguments]];
    }
}
- (void)sendCommand:(NSString*)command withArguments:(NSString *)arguments andSelector:(SEL)selector
{
    [self sendCommand:command withArguments:arguments andMessageId:[NSString stringWithFormat:@"SEL:%@", NSStringFromSelector(selector)]];
}


- (void)bufferList:(WeechatMessage*)message
{
//    NSLog(@"hdata: %@", message);
    NSDictionary *hdata = [[message objects] objectAtIndex:0];
    NSArray *buffers = [hdata objectForKey:@"items"];
    NSLog(@"buffers: %@", buffers);
    
    if (_delegate && [_delegate respondsToSelector:@selector(bufferList:)]) {
        [_delegate bufferList:message];
    }
}

@end
