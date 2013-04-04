//
//  main.m
//  ZumeroReader
//
//  Created by Paul Roub on 4/2/13.
//  Copyright (c) 2013 Zumero LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ZRAppDelegate.h"

int main(int argc, char *argv[])
{
	@autoreleasepool {
		NSString *cname = NSStringFromClass([ZRAppDelegate class]);

	    return UIApplicationMain(argc, argv, cname, cname);
	}
}
