//
//  ZRMasterViewController.m
//  ZumeroReader
//
//  Created by Paul Roub on 4/2/13.
//  Copyright (c) 2013 Zumero LLC. All rights reserved.
//

#import "ZRMasterViewController.h"
#import "ZRDetailViewController.h"
#import "ZRCOnfig.h"

#import <Zumero/Zumero.h>

@interface ZRMasterViewController () {
    NSMutableArray *_objects;
}
@end

@implementation ZRMasterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		self.title = NSLocalizedString(@"Feeds", @"Feeds");
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		    self.clearsSelectionOnViewWillAppear = NO;
		    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
		}
    }
    return self;
}
							
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	self.navigationItem.leftBarButtonItem = self.editButtonItem;

	UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
	self.navigationItem.rightBarButtonItem = addButton;
	
	[self sync];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender
{
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    [_objects insertObject:[NSDate date] atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Sync

- (BOOL) sync
{
	NSString *path = [ZRConfig dbpath];
	NSString *host = [ZRConfig server];
	
	ZumeroDB *db = [[ZumeroDB alloc] initWithName:@"all_feeds" folder:path host:host];
	db.delegate = self;
	
	NSError *err = nil;
	BOOL ok = YES;
	
	if (! [db exists])
		ok = [db createDB:&err];
	
	ok = ok && ([db isOpen] || [db open:&err]);
	
	NSDictionary *scheme = nil;
	NSString *uname = nil;
	NSString *pwd = nil;
	
	ok = ok && [db sync:scheme user:uname password:pwd error:&err];
	
	if (! ok)
		NSLog(@"sync fail: %@", [err description]);
	
	return ok;
}

- (void) syncFeed:(NSNumber *)feedid
{
	NSString *path = [ZRConfig dbpath];
	NSString *host = [ZRConfig server];
	
	NSString *dbname = [NSString stringWithFormat:@"feed_%@", feedid];
	
	ZumeroDB *db = [[ZumeroDB alloc] initWithName:dbname folder:path host:host];
	BOOL ok = YES;
	NSError *err = nil;
	
	if (! [db exists])
		ok = [db createDB:&err];
	
	ok = ok && ([db isOpen] || [db open:&err]);

	if (ok)
	{
		db.delegate = self;
		ok = [db sync:nil user:nil password:nil error:&err];
	}
}

- (void) syncSuccess:(NSString *)dbname
{
	if ([dbname isEqualToString:@"all_feeds"])
	{
		if (!_objects) {
			_objects = [[NSMutableArray alloc] init];
		}
		[_objects removeAllObjects];
		
		NSString *path = [ZRConfig dbpath];
		NSString *host = [ZRConfig server];
		
		ZumeroDB *db = [[ZumeroDB alloc] initWithName:@"all_feeds" folder:path host:host];
		
		NSError *err = nil;
		BOOL ok = ([db isOpen] || [db open:&err]);
		
		if (ok)
		{
			NSArray *rows = nil;
			
			ok = [db selectSql:@"select feeds.feedid, url, title from feeds, about where (feeds.feedid = about.feedid)" values:nil rows:&rows error:&err];

			[db close];
			
			if (ok)
			{
				[_objects setArray:rows];
				
				for (NSDictionary *row in rows)
				{
					NSNumber *id = [row objectForKey:@"feedid"];
					
					[self syncFeed:id];
				}
			}
			else
				NSLog(@"select err: %@", [err description]);
		}
		
		[self.tableView reloadData];
		
		if (self.syncdelegate)
			[self.syncdelegate syncSuccess:dbname];
	}
}

- (void) syncFail:(NSString *)dbname err:(NSError *)err
{
	NSLog(@"error: %@", err);
	
	if (self.syncdelegate)
		[self.syncdelegate syncFail:dbname err:err];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return _objects.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }


	NSDictionary *object = _objects[indexPath.row];
	
	NSString *ttl = [object objectForKey:@"title"];
	if (! ttl)
		ttl = [object objectForKey:@"url"];
	cell.textLabel.text = ttl;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDate *object = _objects[indexPath.row];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
	    if (!self.detailViewController) {
	        self.detailViewController = [[ZRDetailViewController alloc] initWithNibName:@"ZRDetailViewController_iPhone" bundle:nil];
	    }
	    self.detailViewController.detailItem = object;
        [self.navigationController pushViewController:self.detailViewController animated:YES];
    } else {
        self.detailViewController.detailItem = object;
    }
}

@end
