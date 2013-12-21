//
//  WeechatRelayHandler.h
//  Weechat
//
//  Created by Wiggins on 12/20/13.
//  Copyright (c) 2013 Hlidskialf. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WeechatRelayHandler : NSObject <NSStreamDelegate>

@property NSString *password;
@property NSString *hostname;
@property int port;
@property BOOL useSSL;

@end
