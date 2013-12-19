//
//  DetailViewController.h
//  Weechat
//
//  Created by Wiggins on 12/19/13.
//  Copyright (c) 2013 Hlidskialf. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
