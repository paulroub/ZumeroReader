//
//  ZRAppDelegate.m
//  ZumeroReader
//
//  Created by Paul Roub on 4/2/13.
//  Copyright (c) 2013 Zumero LLC. All rights reserved.
//

#import "ZRAppDelegate.h"

#import "ZRMasterViewController.h"

#import "ZRDetailViewController.h"

@interface ZRAppDelegate()
{
	NSTimer *idleTimer;
	NSTimeInterval maxIdleTime;
	BOOL wantToSync;
	NSDate *nextSync;
	ZRMasterViewController *mvc;
	UIBackgroundTaskIdentifier bgtask;
}

@end

@implementation ZRAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
	    mvc = [[ZRMasterViewController alloc] initWithNibName:@"ZRMasterViewController_iPhone" bundle:nil];
	    self.navigationController = [[UINavigationController alloc] initWithRootViewController:mvc];
	    self.window.rootViewController = self.navigationController;
	} else {
	    mvc = [[ZRMasterViewController alloc] initWithNibName:@"ZRMasterViewController_iPad" bundle:nil];
	    UINavigationController *masterNavigationController = [[UINavigationController alloc] initWithRootViewController:mvc];
	    
	    ZRDetailViewController *detailViewController = [[ZRDetailViewController alloc] initWithNibName:@"ZRDetailViewController_iPad" bundle:nil];
	    UINavigationController *detailNavigationController = [[UINavigationController alloc] initWithRootViewController:detailViewController];
		
		mvc.detailViewController = detailViewController;
		
	    self.splitViewController = [[UISplitViewController alloc] init];
	    self.splitViewController.delegate = detailViewController;
	    self.splitViewController.viewControllers = @[masterNavigationController, detailNavigationController];
	    
	    self.window.rootViewController = self.splitViewController;
	}
	
	mvc.syncdelegate = self;
	maxIdleTime = 5;

    [self.window makeKeyAndVisible];
    return YES;
}

#pragma mark sync

// kill off out sync timer when going inactive
- (void)killTimers
{
	self.networkActivityIndicatorVisible = NO;
	
	if (idleTimer) {
        [idleTimer invalidate];
		idleTimer = nil;
    }
}

// restart sync timers when waking up
- (void)startTimers
{
	self.networkActivityIndicatorVisible = NO;
	
	if (! idleTimer) {
        [self resetIdleTimer:30];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	[self killTimers];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	[self killTimers];
	
	bgtask = [application beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundTask:bgtask];
        bgtask = UIBackgroundTaskInvalid;
    }];
	
    // Start the long-running task and return immediately.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		
		[mvc sync];
		
		// finishBackgroundTask will be called by the sync handlers
    });
}

- (BOOL) finishBackgroundTask
{
	if (bgtask && (bgtask != UIBackgroundTaskInvalid))
	{
        [self endBackgroundTask:bgtask];
        bgtask = UIBackgroundTaskInvalid;
		return YES;
	}
	
	return NO;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	[self startTimers];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	[self startTimers];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	[self killTimers];
}

// we're simulating an idle timer -- waiting for a few seconds with no touch activity
//
- (void)sendEvent:(UIEvent *)event {
    [super sendEvent:event];
	
    // Only want to reset the timer on a Began touch or an Ended touch, to reduce the number of timer resets.
    NSSet *allTouches = [event allTouches];
    if ([allTouches count] > 0) {
        UITouchPhase phase = ((UITouch *)[allTouches anyObject]).phase;
        if (phase == UITouchPhaseBegan || phase == UITouchPhaseEnded)
            [self resetIdleTimer:maxIdleTime];
    }
}

- (void)resetIdleTimer:(NSTimeInterval)secs
{
    if (idleTimer) {
        [idleTimer invalidate];
		idleTimer = nil;
    }
	
    idleTimer = [NSTimer scheduledTimerWithTimeInterval:secs target:self selector:@selector(idleTimerExceeded) userInfo:nil repeats:NO];
}

// we've found an idle moment. Is it time to sync?
//
- (void)idleTimerExceeded {
	// Has anyone asked us to sync?
	//
	if (wantToSync)
	{
		NSTimeInterval since = [nextSync timeIntervalSinceNow];
		
		// is it time yet?
		if (since <= 0)
		{
			wantToSync = FALSE;
			
			BOOL ok = FALSE;
			
			// kick off a zumero background sync
			// this class will be the ZumeroDBDelegate, so our syncFail/syncSuccess routines
			// will be called as necessary
			if (mvc)
				ok = [mvc sync];
			
			if (ok)
				self.networkActivityIndicatorVisible = YES;
			else
				// the sync call failed; try again later
				[self waitForSync:(10 * 60)];
		}
		else
		{
			// nope, check again next idle time
			[self resetIdleTimer:since];
		}
		
		return;
	}
	
	[self resetIdleTimer:maxIdleTime];
}

// note that we want to sync, and how soon.
// If we're already waiting, the nearest time wins.
//
- (void) waitForSync:(NSTimeInterval)secs
{
	if (! wantToSync)
	{
		nextSync = [NSDate dateWithTimeIntervalSinceNow:secs];
		wantToSync = TRUE;
	}
	else
	{
		NSDate *syncTime = [NSDate dateWithTimeIntervalSinceNow:secs];
		
		NSComparisonResult comp = [syncTime compare:nextSync];
		
		if (comp == NSOrderedAscending) // sooner?
			nextSync = syncTime;
	}
	
	[self resetIdleTimer:maxIdleTime];
}

// Our sync call started, but failed for some reason.
// Uncomment the ZWError to receive in-app popups about this.
//
- (void) syncFail:(NSString *)dbname err:(NSError *)err
{
	//	[ZWError reportError:@"sync failed" description:@"Zumero sync failed" error:err];
	self.networkActivityIndicatorVisible = NO;
	
	if (! [self finishBackgroundTask])
		[self waitForSync:(10 * 60)];
}

// The sync succeeded.  Schedule another one for later, reload our page list.
//
- (void) syncSuccess:(NSString *)dbname
{
	self.networkActivityIndicatorVisible = NO;
	if (! [self finishBackgroundTask])
		[self waitForSync:(5 * 60)];
}


@end
