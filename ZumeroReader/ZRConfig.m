//
//  ZRConfig.m
//  ZumeroReader
//
//  Created by Paul Roub on 4/8/13.
//  Copyright (c) 2013 Zumero LLC. All rights reserved.
//

#import "ZRConfig.h"

@implementation ZRConfig


+ (NSString *)server
{
	return @"https://zinst393e9343b87.s.zumero.net";
}

+ (NSString *)username
{
	return nil;
}

+ (NSString *)password
{
	return nil;
}

+ (NSDictionary *)scheme
{
	return nil;
}

+ (NSString *)dbpath
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *path = [paths objectAtIndex:0];
	return path;
}


@end
