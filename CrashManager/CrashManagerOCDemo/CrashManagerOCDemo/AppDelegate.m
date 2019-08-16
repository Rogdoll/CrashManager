//
//  AppDelegate.m
//  CrashManagerOCDemo
//
//  Created by Pikachu on 2019/8/16.
//  Copyright © 2019 Rogdoll. All rights reserved.
//

#import "AppDelegate.h"
#import <CrashManager/CrashManager.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSSetUncaughtExceptionHandler(&a);
    [NSJSONSerialization JSONObjectWithData:nil options:kNilOptions error:nil];
    return YES;
}

void a(NSException *exception) {
    printf("%s\n",[exception.description cStringUsingEncoding:NSUTF8StringEncoding]);
}

@end
