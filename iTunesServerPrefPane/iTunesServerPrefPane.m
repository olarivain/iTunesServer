//
//  iTunesServerPrefPane.m
//  iTunesServerPrefPane
//
//  Created by Larivain, Olivier on 12/10/11.
//  Copyright (c) 2011 kra. All rights reserved.
//

#import <KraCommons/KCBlocks.h>
#import <KraCommons/NSArray+BoundSafe.h>
#import <KraCommons/NSDictionary+NilSafe.h>
#import "iTunesServerPrefPane.h"

#import "ITSDefaults.h"
#import "iTunesServer.h"

#import "ITSConfiguration.h"
#import "ITSConfigurationRepository.h"

#define ITUNES_SERVER_APP_NAME @"iTunesServer"
#define ITUNES_SERVER_BUNDLE_ID @"com.kra.iTunesServer"

@interface iTunesServerPrefPane()
- (void) updateRunningLabel;

- (NSRunningApplication *) iTunesServerRunningApplication;
- (void) updateAccordingToConfiguration;
- (void) didPickFolder: (NSInteger) result withPanel: (NSOpenPanel *) panel;
- (void) didPickEncodingFolder: (NSInteger) result withPanel: (NSOpenPanel *) panel;

- (void) saveConfiguration;
@end

@implementation iTunesServerPrefPane

- (id) initWithBundle:(NSBundle *)bundle
{
  self = [super initWithBundle: bundle];
  if(self)
  {    
    NSUserDefaults *defaults = [[[NSUserDefaults alloc] init] autorelease];
    [defaults addSuiteNamed: @"com.kra.iTunesShared"];
    [ITSDefaults bootstrapDefaults: defaults];
  }
  return self;
}

// we observe workspace's runningApplications key
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
  configuration = [[ITSConfigurationRepository sharedInstance] readConfiguration];
  

  workspace = [NSWorkspace sharedWorkspace];
  [workspace addObserver: self forKeyPath: @"runningApplications" options:NSKeyValueObservingOptionNew context: nil];
  
  // figure out if process is running
  isRunning = [self iTunesServerRunningApplication] != nil;
  
  [self updateRunningLabel];
  [self updateAccordingToConfiguration];
}

- (void) willUnselect
{
  // release unneeded resources
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

#pragma mark - initialize UI according to configuration
- (void) updateAccordingToConfiguration 
{
  // figure out if we're using auto import
  BOOL autoImport = configuration.autoScanEnabled;
  autoImportCheckBox.state = autoImport ? NSOnState : NSOffState;
  
  // update text field accordingly
  [automaticImportTextField setEnabled: autoImport];
  NSString *path = configuration.autoScanPath;
  path = path == nil ? @"" : path;
  [automaticImportTextField setStringValue: path];
  
  // and enable button accordingly
  [autoImportPathButton setEnabled: autoImport];
  
  // update text field accordingly
  NSString *encodingPath = configuration.encodingResourcePath;
  encodingPath = encodingPath == nil ? @"" : encodingPath;
  [encodingResourceTextField setStringValue: encodingPath];
}

#pragma mark - Auto Import
#pragma mark toggle
- (IBAction) toggleAutoImport:(id)sender
{ 
  // trigger folder picker if on and no path defined
  BOOL autoImport = autoImportCheckBox.state == NSOnState;
  
  [autoImportPathButton setEnabled: autoImport];
  [automaticImportTextField setEnabled: autoImport];
  
  NSString *path = configuration.autoScanPath;
  if(autoImport && [path length] == 0)
  {
    [self changeAutomaticImportFolder: nil];
    // and return here, we don't wan't the code after that running
    return;
  }
  
  configuration.autoScanEnabled = autoImport;
  [self saveConfiguration];
}
#pragma mark path
- (IBAction) changeAutomaticImportFolder:(id)sender
{
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.canChooseFiles = NO;
  panel.canChooseDirectories = YES;
  panel.canCreateDirectories = YES;
  panel.allowsMultipleSelection = NO;
  
  
  NSString *currentPath = configuration.autoScanPath;
  if([currentPath length] == 0)
  {
    currentPath = @"~/";
  }
  
  NSString *urlScheme = [NSString stringWithFormat: @"file://%@", [currentPath stringByExpandingTildeInPath]];
  [panel setDirectoryURL: [NSURL URLWithString: urlScheme]];
  
  KCIntegerBlock completion = ^(NSInteger result){
    [self didPickFolder: result withPanel: panel];
  };
  
  NSWindow *window = [NSApplication sharedApplication].keyWindow;
  [panel beginSheetModalForWindow: window  completionHandler: completion];
}

- (void) didPickFolder: (NSInteger) result withPanel: (NSOpenPanel *) panel
{
  if(result != NSFileHandlingPanelOKButton)
  {
    return;
  }
  NSArray *urls = panel.URLs;
  NSURL *url = [urls boundSafeObjectAtIndex: 0];
  NSString *path = [url path];
  // configuration is enabled if we got here
  configuration.autoScanEnabled = YES;
  configuration.autoScanPath = path;
  
  [self saveConfiguration];
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

#pragma mark - Encoding resource folder
- (IBAction) changeEncodingResourceFolder:(id)sender
{
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.canChooseFiles = NO;
  panel.canChooseDirectories = YES;
  panel.canCreateDirectories = YES;
  panel.allowsMultipleSelection = NO;
  
  
  NSString *currentPath = configuration.encodingResourcePath;
  if([currentPath length] == 0)
  {
    currentPath = @"~/";
  }
  
  NSString *urlScheme = [NSString stringWithFormat: @"file://%@", [currentPath stringByExpandingTildeInPath]];
  [panel setDirectoryURL: [NSURL URLWithString: urlScheme]];
  
  KCIntegerBlock completion = ^(NSInteger result){
    [self didPickEncodingFolder: result withPanel: panel];
  };
  
  NSWindow *window = [NSApplication sharedApplication].keyWindow;
  [panel beginSheetModalForWindow: window  completionHandler: completion];
}

- (void) didPickEncodingFolder: (NSInteger) result withPanel: (NSOpenPanel *) panel
{
  if(result != NSFileHandlingPanelOKButton)
  {
    return;
  }
  NSArray *urls = panel.URLs;
  NSURL *url = [urls boundSafeObjectAtIndex: 0];
  NSString *path = [url path];

  configuration.encodingResourcePath = path;
  
  [self saveConfiguration];
}

#pragma mark - Scripting Bridge
- (void) saveConfiguration
{
//  BOOL autoImport = autoImportCheckBox.state == NSOnState;
//  NSString *path = [automaticImportTextField stringValue];
////  NSInteger port = 
//  [defaults setBool: autoImport  forKey: AUTO_IMPORT_KEY];
//  [defaults setObject: path forKey: AUTO_IMPORT_PATH_KEY];
//  [defaults synchronize];
  [[ITSConfigurationRepository sharedInstance] saveConfiguration];
  iTunesServerApplication *application = (iTunesServerApplication *) [SBApplication applicationWithBundleIdentifier: ITUNES_SERVER_BUNDLE_ID];
  if(!application.isRunning)
  {
    return;
  }
  
  [application reloadConfiguration];
}

@end
