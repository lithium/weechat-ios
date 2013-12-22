//
//  BufferListViewController.m
//  Weechat
//
//  Created by Wiggins on 12/19/13.
//  Copyright (c) 2013 Hlidskialf. All rights reserved.
//

#import "BufferListViewController.h"
#import "DetailViewController.h"
#import "WeechatRelayHandler.h"
#import "WeechatMessage.h"

@interface BufferListViewController () {
    NSArray *_buffers;
    WeechatRelayHandler *_relay;
}
@end

@implementation BufferListViewController

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
    
    [super awakeFromNib];
    
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
   
   
    _relay = [[WeechatRelayHandler alloc] init];
    [_relay setDelegate:self];
    
    // load preferences
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *relayHost = [defaults stringForKey:@"relayHostname_preference"];
    NSString *relayPassword = [defaults stringForKey:@"relayPassword_preference"];
    int relayPort = [defaults integerForKey:@"relayPort_preference"];
    BOOL useSSL = [defaults integerForKey:@"relayWeechatSsl_preference"];
    
    // missing preferences, show settings
    if ([relayHost length] < 1 || [relayPassword length] < 1) {
        [self performSegueWithIdentifier:@"showConnectionSettings" sender:self];
    }
    else {
        // connect using existing settings
        [_relay setHostname:relayHost];
        [_relay setPassword:relayPassword];
        [_relay setPort:relayPort];
        [_relay setUseSSL:useSSL];
        [_relay connect];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _buffers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    NSDictionary *buf = _buffers[indexPath.row];
    cell.textLabel.text = [buf objectForKey:@"name"];
    return cell;
}




- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
//        NSDate *object = _objects[indexPath.row];
//        self.detailViewController.detailItem = object;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
//        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
//        NSDate *object = _objects[indexPath.row];
//        [[segue destinationViewController] setDetailItem:object];
    }
}


- (void)bufferList:(WeechatMessage*)message
{
    NSDictionary *hdata = [[message objects] objectAtIndex:0];
    _buffers = [hdata objectForKey:@"items"];
    
    NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:[_buffers count]];
    [_buffers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
    }];
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];

    
}
@end
