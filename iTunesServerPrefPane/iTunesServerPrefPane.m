//
//  iTunesServerPrefPane.m
//  iTunesServerPrefPane
//
//  Created by Larivain, Olivier on 12/10/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import <KraCommons/KCBlocks.h>
#import "iTunesServerPrefPane.h"

#import "ITSDefaults.h"
#import "iTunesServer.h"

#define ITUNES_SERVER_APP_NAME @"iTunesServer"

@interface iTunesServerPrefPane()
- (void) updateRunningLabel;

- (NSRunningApplication *) iTunesServerRunningApplication;
@end

@implementation iTunesServerPrefPane

- (id) initWithBundle:(NSBundle *)bundle
{
  self = [super initWithBundle: bundle];
  if(self)
  {    
    [ITSDefaults bootstrapDefaults: defaults];
  }
  return self;
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  // status didn't change
  BOOL isRunningNow = [self iTunesServerRunningApplication] != nil;
  if(isRunningNow == isRunning)
  {
    return;
  }
  
  // figure out if process is running
  isRunning = isRunningNow;
  
  [self updateRunningLabel];
}

#pragma mark - Lifecycle
- (void) didSelect
{
  // don't forget to bootsrap user defaults, this might be the first thing the user starts
  defaults = [NSUserDefaults standardUserDefaults];
  [defaults addSuiteNamed:@"com.kra.iTunesServer"];

  // figure out if process is running
  isRunning = [self iTunesServerRunningApplication] != nil;
  
  [self updateRunningLabel];
  
  workspace = [NSWorkspace sharedWorkspace];
  [workspace addObserver: self forKeyPath: @"runningApplications" options:NSKeyValueObservingOptionNew context: nil];
}

- (void) willUnselect
{
  // release unneeded resources
  defaults = nil;
  [workspace removeObserver: self forKeyPath: @"runningApplications"];
}

#pragma mark - Update the status label
- (void) updateRunningLabel 
{
  // now we know if it's on or off, update the UI accordingly
  NSString *runningLabelValue = isRunning ? @"Running" : @"Stopped";
  [runningLabel setStringValue: runningLabelValue];
  
  runningLabel.textColor = isRunning ? [NSColor colorWithSRGBRed: 51.0/255.0 green:153.0/255.0 blue: 0.0/255.0 alpha:1] : [NSColor colorWithSRGBRed:191.0/255.0 green:47.0/255.0 blue:55.0/255.0 alpha:1.0];
  
  NSString *buttonLabel = isRunning ? @"Stop" : @"Start";
  startStopButton.title = buttonLabel;
  
  // make sure progrss indicators are not 
  [progressIndicator setHidden: YES];
  [startStopButton setEnabled: YES];
}

#pragma mark - starting stop server
- (IBAction) startStopServer:(id)sender
{
  // start or stop server depending on current state
  if(!isRunning && [self iTunesServerRunningApplication] != nil) 
  {
    return;
  } 

  // start animation
  [progressIndicator setHidden: NO];
  [progressIndicator startAnimation: self];
  
  [startStopButton setEnabled: NO];
  
  if(!isRunning)
  {
    // ask workspace to start app and then refresh ui.
    // this might take some time to refresh, so throw this out on a background thread
    [workspace launchApplication: ITUNES_SERVER_APP_NAME];
  }
  else
  {
    // ask workspace to stop app
    // Workspace notifications will kick in when app is started and update the ui properly
    NSRunningApplication *runningApp = [self iTunesServerRunningApplication];
    [runningApp terminate];
  }
}

#pragma mark - changing auto import path
- (IBAction) changeAutomaticImportFolder:(id)sender
{
  iTunesServerApplication *theApp = [SBApplication applicationWithBundleIdentifier: @"com.kra.iTunesServer"];
  NSLog(@"the app %@", theApp);
  [theApp updateConfig];
}

#pragma mark - Running app instance
- (NSRunningApplication *) iTunesServerRunningApplication
{
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
