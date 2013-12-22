//
//  MasterViewController.h
//  Weechat
//
//  Created by Wiggins on 12/19/13.
//  Copyright (c) 2013 Hlidskialf. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

@interface BufferListViewController : UITableViewController

@property (strong, nonatomic) DetailViewController *detailViewController;

@end
