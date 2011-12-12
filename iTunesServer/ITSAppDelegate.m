//
//  ITSAppDelegate.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/10/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import "ITSAppDelegate.h"

#import <HTTPServe/HSHTTPServe.h>

@implementation ITSAppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  server = [[HSHTTPServe alloc] initWithPort: 2048];
  [server start];
}

- (void) applicationWillTerminate:(NSNotification *)notification 
{
  [server stop];
}

@end
