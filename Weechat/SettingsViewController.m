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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self
                                                                                action:@selector(savePreferences:)];
    self.navigationItem.rightBarButtonItem = doneButton;
}

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

//- (UIImageView *)errorImageView
- (BOOL)setTextFieldValid:(UITextField *)field withCondition:(BOOL)valid
{
    field.rightViewMode = UITextFieldViewModeAlways;

    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,16,16)];
    imageView.image = [UIImage imageNamed:@"warning.png"];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    if (valid) {
        field.rightView = nil;
    } else {
        field.rightView = imageView;
    }

    return valid;
}

- (BOOL)validateHostname
{
    return [self setTextFieldValid:relayHostname
                     withCondition:([[self hostname] length] > 0)];
}
- (BOOL)validatePassword
{
    return [self setTextFieldValid:relayPassword
                     withCondition:([[self password] length] > 0)];
}

- (BOOL)validate
{
    BOOL valid = YES;
    
    valid = [self validateHostname] && valid;
    valid = [self validatePassword] && valid;

    return valid;
}

- (void)savePreferences:(id)sender {
    if ([self validate]) {
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setValue:[self hostname]
                    forKey:@"relayHostname_preference"];
        [defaults setValue:[NSNumber numberWithInt:[self port]]
                    forKey:@"relayPort_preference"];
        [defaults setValue:[self password]
                    forKey:@"relayPassword_preference"];
        [defaults setValue:[NSNumber numberWithBool:[self useSSL]]
                    forKey:@"relayWeechatSsl_preference"];
        
        [self performSegueWithIdentifier:@"showBufferList" sender:self];
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


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    [self setTextFieldValid:textField withCondition:YES];
    return YES;
}
@end
