//
//  ZRDetailViewController.m
//  ZumeroReader
//
//  Created by Paul Roub on 4/2/13.
//  Copyright (c) 2013 Zumero LLC. All rights reserved.
//

#import "ZRDetailViewController.h"
#import "ZRConfig.h"
#import <Zumero/Zumero.h>

@interface ZRDetailViewController ()

{
	UIWebView *content;
}
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation ZRDetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

- (void)configureView
{
    // Update the user interface for the detail item.

	if (self.detailItem) {
		NSDictionary *dict = self.detailItem;
		
		NSString *ttl = [dict objectForKey:@"title"];
		if (! ttl)
			ttl = [dict objectForKey:@"url"];
		
		self.title = ttl;
		
		NSString *path = [ZRConfig dbpath];
		NSString *host = [ZRConfig server];
		NSString *dbname = [NSString stringWithFormat:@"feed_%@", [dict objectForKey:@"feedid"]];
		
		ZumeroDB *db = [[ZumeroDB alloc] initWithName:dbname folder:path host:host];
		
		NSArray *rows = nil;
		NSError *err = nil;
		
		BOOL ok = [db open:&err];
		
		ok = [db select:@"items" criteria:nil columns:nil orderby:@"pubdate_unix_time desc" rows:&rows error:&err];

		[self listItems:rows];
		
		[db close];
		
		[self checkLayout];
	}
	
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	CGRect frame = [self.view bounds];
	
	content = [[UIWebView alloc] initWithFrame:frame];
	[self.view addSubview:content];
	content.delegate = self;
	
	[self configureView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		self.title = NSLocalizedString(@"Items", @"Items");
    }
    return self;
}

- (void) checkLayout
{
	CGRect frame = [self.view frame];
	[content setFrame:frame];
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[self checkLayout];
}
							
#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Feeds", @"Feeds");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

#pragma mark - Render

- (void) listItems:(NSArray *)rows
{
	NSString *header =  @"<!DOCTYPE html>\n\n<html><head><title>feed</title>"
						"<link rel='stylesheet' type='text/css' href='rss.css' />"
						"</head><body>\n";
	NSString *footer = @"\n</body></html>";

	NSMutableString *st = [[NSMutableString alloc] initWithString:header];
	NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
	[fmt setDateFormat:@"MMM dd, yyyy"];
	
	for ( NSDictionary *item in rows )
	{
		NSNumber *utime = [item objectForKey:@"pubdate_unix_time"];
		NSString *title = [self escape:[item objectForKey:@"title"]];
		NSString *iid = [self escape:[item objectForKey:@"id"]];
		NSString *url = [self escape:[item objectForKey:@"permalink"]];
		NSString *summary = [item objectForKey:@"summary"];
		
		NSDate *dt = [NSDate dateWithTimeIntervalSince1970:[utime longLongValue]];
		NSString *stamp = [fmt stringFromDate:dt];
		
		NSString *section = [NSString stringWithFormat:
							 @"<article><h2><a href=\"%@\">%@</a></h2>"
							 "<p class='date'>%@</p>"
							 "<div class='summary'>%@</div>",
							 url ? url : iid, title, stamp, summary];
		
		[st appendString:section];
	}
	
	[st appendString:footer];
	
	NSURL *base = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
	
	[content loadHTMLString:st baseURL:base];
}

- (NSString *)escape:(NSString *)html
{
	NSString *h = [html stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
	h = [h stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
	h = [h stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
	h = [h stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
	h = [h stringByReplacingOccurrencesOfString:@"'" withString:@"&apos;"];
	return h;
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{
    NSURL *requestURL = [ request URL ];
    if ( ( [ [ requestURL scheme ] isEqualToString: @"http" ] || [ [ requestURL scheme ] isEqualToString: @"https" ] || [ [ requestURL scheme ] isEqualToString: @"mailto" ])
        && ( navigationType == UIWebViewNavigationTypeLinkClicked ) ) {
        return ![ [ UIApplication sharedApplication ] openURL: requestURL ];
    }
    return YES;
}

@end
