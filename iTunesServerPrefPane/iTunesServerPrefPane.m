//
//  iTunesServerPrefPane.m
//  iTunesServerPrefPane
//
//  Created by Larivain, Olivier on 12/10/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import <KraCommons/KCBlocks.h>
#import "iTunesServerPrefPane.h"

#import "iTunesServer.h"

@interface iTunesServerPrefPane()
- (void) lookUpProcess;
- (void) startServer;
- (void) stopServer;
- (NSRunningApplication *) iTunesServerRunningApplication;

@end

@implementation iTunesServerPrefPane

- (id) initWithBundle:(NSBundle *)bundle
{
  self = [super initWithBundle: bundle];
  if(self)
  {
    operationQueue = [[NSOperationQueue alloc] init];
    operationQueue.maxConcurrentOperationCount = 1;
  }
  return self;
}

- (void)mainViewDidLoad
{
  workspace = [NSWorkspace sharedWorkspace];
  iTunesServerApplication *anApp = [SBApplication applicationWithBundleIdentifier:@"com.kra.iTunesServer"];
  iTunesServerITunesServerConfiguration *config = anApp.configuration;
  NSLog(@"config %@", config.autoScanPath);

  config.port = 4567;
  config.autoScanPath = @"meh?";
//  anApp.configuration = config;
}

- (void) didSelect
{
  [self lookUpProcess];
}

- (void) lookUpProcess 
{
  // figure out if process is running
  isRunning = [self iTunesServerRunningApplication] != nil;
  
  // now we know if it's on or off, update the UI accordingly
  NSString *runningLabelValue = isRunning ? @"Running" : @"Stopped";
  [runningLabel setStringValue: runningLabelValue];
  
  runningLabel.textColor = isRunning ? [NSColor colorWithSRGBRed: 51.0/255.0 green:153.0/255.0 blue: 0.0/255.0 alpha:1] : [NSColor colorWithSRGBRed:191.0/255.0 green:47.0/255.0 blue:55.0/255.0 alpha:1.0];
  
  NSString *buttonLabel = isRunning ? @"Stop" : @"Start";
  startStopButton.title = buttonLabel;
}

- (NSRunningApplication *) iTunesServerRunningApplication
{
  // browse through list of running processes and search for iTunesServer
  NSArray *runningApps = [workspace runningApplications];
  for(NSRunningApplication *runningApp in runningApps)
  {
    if([@"iTunesServer" caseInsensitiveCompare: runningApp.localizedName] == NSOrderedSame) 
    {
      return runningApp;
    }
  }

  return nil;
}

#pragma mark - starting stop server
- (IBAction) startStopServer:(id)sender
{
  // start or stop server depending on current state
  if(isRunning) 
  {
    [self stopServer];
  } 
  else 
  {
    [self startServer];
  }
}

- (void) startServer
{
  // cancel if server is already running
  if([self iTunesServerRunningApplication] != nil)
  {
    return;
  }
  
  // start animation
  [progressIndicator setHidden: NO];
  [progressIndicator startAnimation: self];
  
  [startStopButton setEnabled: NO];
  
  // ask workspace to start app and then refresh ui.
  // this might take some time to refresh, so throw this out on a background thread
  KCVoidBlock block = ^{
    [workspace launchApplication: @"iTunesServer"];
    [NSThread sleepForTimeInterval: 2];
    
    // dispatch UI update on main thread
    KCVoidBlock uiBlock = ^{
      [progressIndicator setHidden: YES];
      
      [startStopButton setEnabled: YES];
      [self lookUpProcess];    
    };
    
    DispatchMainThread(uiBlock);
  };
  
  [operationQueue addOperationWithBlock: block];

}

- (void) stopServer
{
  // start animation and disable button
  [progressIndicator setHidden: NO];
  [progressIndicator startAnimation: self];
  
  [startStopButton setEnabled: NO];
 
#warning this stuff will be much more suited as an NSWorkspaceDelegate or wahtever the protocol is
  // ask workspace to stop app and then refresh ui.
  // this might take some time to refresh, so throw this out on a background thread
  KCVoidBlock block = ^{
    // grab reference to running app and terminate it
    NSRunningApplication *runningApp = [self iTunesServerRunningApplication];
    [runningApp terminate];
    
    // sleep to be sure UI catches updates
    [NSThread sleepForTimeInterval: 2];
    
    KCVoidBlock uiBlock = ^{
      [progressIndicator setHidden: YES];
      [startStopButton setEnabled: YES];
      [self lookUpProcess];    
    };
    
    DispatchMainThread(uiBlock);
  };
  
  [operationQueue addOperationWithBlock: block];
}

#pragma mark - changing automatic import folder
- (IBAction) changeAutomaticImportFolder:(id)sender
{
  NSLog(@"wouhou");
}

@end
