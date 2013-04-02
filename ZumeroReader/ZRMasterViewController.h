//
//  ZRMasterViewController.h
//  ZumeroReader
//
//  Created by Paul Roub on 4/2/13.
//  Copyright (c) 2013 Zumero LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZRDetailViewController;

@interface ZRMasterViewController : UITableViewController

@property (strong, nonatomic) ZRDetailViewController *detailViewController;

@end
