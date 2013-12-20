//
//  SettingsViewController.m
//  Weechat
//
//  Created by Wiggins on 12/20/13.
//  Copyright (c) 2013 Hlidskialf. All rights reserved.
//

#import "SettingsViewController.h"


@implementation SettingsViewController
@synthesize relayHostname;
@synthesize relayPassword;
@synthesize relayPort;
@synthesize relayWeechatSsl;

- (NSString*)hostname
{
    return [relayHostname text];
}

- (int)port
{
    NSString *portStr = [relayPort text];
    if ([portStr length] < 1)
        return kDefaultPort;
    return [portStr intValue];
}

- (NSString*)password
{
    return [relayPassword text];
}

- (BOOL)useSSL
{
    return relayWeechatSsl.on;
}


- (BOOL)validate {
    
    if ([[self hostname] length] > 0 && [[self password] length] > 0)
        return YES;
    
    return NO;
}

- (IBAction)clickConnect:(id)sender {
    if ([self validate]) {
        [self performSegueWithIdentifier:@"connectToRelay" sender:self];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == relayHostname) {
        [relayPort becomeFirstResponder];
    }
    else if (textField == relayPort) {
        [relayPassword becomeFirstResponder];
    }
    else if (textField == relayPassword) {
        [textField resignFirstResponder];
    }
    
    return YES;
}
@end
