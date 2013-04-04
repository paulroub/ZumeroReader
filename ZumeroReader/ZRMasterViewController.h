//
//  ZRMasterViewController.h
//  ZumeroReader
//
//  Created by Paul Roub on 4/2/13.
//  Copyright (c) 2013 Zumero LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Zumero/Zumero.h>

@class ZRDetailViewController;

@interface ZRMasterViewController : UITableViewController <ZumeroDBDelegate>

- (BOOL) sync;

@property (strong, nonatomic) ZRDetailViewController *detailViewController;
@property (strong, nonatomic) id<ZumeroDBDelegate> syncdelegate;

@end
