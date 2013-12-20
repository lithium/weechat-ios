//
//  SettingsViewController.h
//  Weechat
//
//  Created by Wiggins on 12/20/13.
//  Copyright (c) 2013 Hlidskialf. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kDefaultPort 8201

@interface SettingsViewController : UITableViewController <UITableViewDelegate, UITextFieldDelegate>


@property (weak, nonatomic) IBOutlet UITextField *relayHostname;
@property (weak, nonatomic) IBOutlet UITextField *relayPort;
@property (weak, nonatomic) IBOutlet UITextField *relayPassword;
@property (weak, nonatomic) IBOutlet UISwitch *relayWeechatSsl;

- (IBAction)clickConnect:(id)sender;
@end
