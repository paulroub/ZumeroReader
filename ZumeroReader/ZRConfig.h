//
//  ZRConfig.h
//  ZumeroReader
//
//  Created by Paul Roub on 4/8/13.
//  Copyright (c) 2013 Zumero LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZRConfig : NSObject


+ (NSString *)dbpath;
+ (NSString *)server;
+ (NSString *)username;
+ (NSString *)password;
+ (NSDictionary *)scheme;

@end
