//
//  ITSAppDelegate.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/10/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//
#define ITUNES_SERVER_APP_NAME @"iTunesServer"
#import <HTTPServe/HSHTTPServe.h>

#import "ITSAppDelegate.h"

#import "ITSDefaults.h"

@interface ITSAppDelegate()
- (NSRunningApplication *) iTunesServerRunningApplication;
@end

@implementation ITSAppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [ITSDefaults bootstrapDefaults: defaults];
  
  NSInteger port = [defaults integerForKey: @"port"];
  server = [[HSHTTPServe alloc] initWithPort: (int) port];
  [server start];

  // start file manager monitor here if needed
}

- (void) applicationWillTerminate:(NSNotification *)notification 
{
  [server stop];
}

- (NSRunningApplication *) iTunesServerRunningApplication
{
  NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
  // browse through list of running processes and search for iTunesServer
  NSArray *runningApps = [workspace runningApplications];
  for(NSRunningApplication *runningApp in runningApps)
  {
    if([ITUNES_SERVER_APP_NAME caseInsensitiveCompare: runningApp.localizedName] == NSOrderedSame) 
    {
      return runningApp;
    }
  }
  
  return nil;
}                    
                              
@end
