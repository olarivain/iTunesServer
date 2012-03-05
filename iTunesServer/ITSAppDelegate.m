//
//  ITSAppDelegate.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/10/11.
//  Copyright (c) 2011 kra. All rights reserved.
//
#define ITUNES_SERVER_APP_NAME @"iTunesServer"
#import <HTTPServe/HSHTTPServe.h>

#import "ITSAppDelegate.h"

#import "ITSDefaults.h"
#import "ITSConfigurationRepository.h"
#import "ITSConfiguration.h"

#import "ITSFolderScanner.h"

@interface ITSAppDelegate()
- (void) launchServices;
@end

@implementation ITSAppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{  
  // bootstrap defaults as needed.
  NSUserDefaults *defaults = [[NSUserDefaults alloc] init];
  [defaults addSuiteNamed:@"com.kra.iTunesServerShared"];
  [ITSDefaults bootstrapDefaults: defaults];
  
  // read configuration and instantiate server
  ITSConfigurationRepository *repository = [ITSConfigurationRepository sharedInstance];
  ITSConfiguration *configuration = [repository readConfiguration];
  int port = (int) configuration.port;
#if DEVELOPMENT == 1
  // override "random port" to 2048 when debugging.
  if(port == 0)
  {
    port = 2048;
  }
#endif
  server = [[HSHTTPServe alloc] initWithPort: port];
  
  folderScanner = [ITSFolderScanner folderScannerWithScannedPath: configuration.autoScanPath];
  
  // then start services as needed
  [self launchServices];
}

- (void) applicationWillTerminate:(NSNotification *)notification 
{
  [server stop];
}    

- (void) launchServices
{
  ITSConfigurationRepository *repository = [ITSConfigurationRepository sharedInstance];
  ITSConfiguration *configuration = [repository readConfiguration];
  
//  // TODO enable when port has been been made public
//  if(configuration.port != server.port)
//  {
//    [server stop];
//    server = [[HSHTTPServe alloc] initWithPort: (int) configuration.port];
//    [server start];
//  }
//  
//  NSInteger port = configuration.port;
//  server = [[HSHTTPServe alloc] initWithPort: (int) port];
  [server start];
  
  if(configuration.autoScanEnabled)
  {
    [folderScanner setScannedPath: configuration.autoScanPath];
    [folderScanner start];
  }
  else
  {
    [folderScanner stop];
  }
}

- (void) reloadConfiguration
{
  // force reload the configuration, so it's in sync with what's been updated by pref pane
  ITSConfigurationRepository *repository = [ITSConfigurationRepository sharedInstance];
  [repository forceReload];
  
  // and restart services
  [self launchServices];
}
                              
@end
