//
//  WeechatRelayHandler.m
//  Weechat
//
//  Created by Wiggins on 12/20/13.
//  Copyright (c) 2013 Hlidskialf. All rights reserved.
//

#import "WeechatRelayHandler.h"
#import "GZIP.h"

@implementation WeechatRelayHandler
{
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
    NSMutableData *outputBuffer;
}

- (id)init
{
    if (self) {
        outputBuffer = [NSMutableData dataWithCapacity:1024];
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
        withArguments:[NSString stringWithFormat:@"password=%@,compression=zlib", [self password]]
         andMessageId:nil];
    [self sendCommand:@"hdata" withArguments:@"buffer:gui_buffers(*) number,name" andMessageId:@"bufferList"];
    
    [inputStream open];
    [outputStream open];
    
    return YES;
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    
    switch (eventCode) {
        case NSStreamEventHasBytesAvailable:
        {
            //read ready
            uint8_t *buffer;
            NSUInteger available;
            
            [inputStream getBuffer:&buffer length:&available];
            if (available > 4) {
                uint32_t *length = (uint32_t*)buffer;
                
                if (available-4 < *length) {
                    // not enough bytes to read entire message now
                    break;
                    
                }
                uint8_t *compressed = (uint8_t*)buffer+4;
                
                NSData *data = [NSData dataWithBytes:buffer+5 length:*length-5];
                if (*compressed == 1) {
                    data = [data gunzippedData];
                }
                
//                WeechatData *wd = [WeechatData withData:data];
//                NSString *messageId = wd.getString();
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


@end
