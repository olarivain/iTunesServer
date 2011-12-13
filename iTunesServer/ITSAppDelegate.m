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
#import "ITSConfigurationRepository.h"
#import "ITSConfiguration.h"

@interface ITSAppDelegate()
@end

@implementation ITSAppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{  
  NSUserDefaults *defaults = [[NSUserDefaults alloc] init];
  [defaults addSuiteNamed:@"com.kra.iTunesServerShared"];
  
  [ITSDefaults bootstrapDefaults: defaults];
  
    ITSConfigurationRepository *repository = [ITSConfigurationRepository sharedInstance];
  ITSConfiguration *configuration = [repository readConfiguration];
  
  NSInteger port = configuration.port;
  server = [[HSHTTPServe alloc] initWithPort: (int) port];
  [server start];


  // start file manager monitor here if needed
}

- (void) applicationWillTerminate:(NSNotification *)notification 
{
  [server stop];
}    

- (void) reloadConfiguration
{
  ITSConfigurationRepository *repository = [ITSConfigurationRepository sharedInstance];
  ITSConfiguration *configuration = [repository forceReload];
  
  // TODO enable
//  if(configuration.port != server.port)
//  {
//    [server stop];
//    server = [[HSHTTPServe alloc] initWithPort: (int) port];
//    [server start];
//  }

  
  NSLog(@"ok %i %@.", configuration.autoScanEnabled, configuration.autoScanPath);
  
}
                              
@end
