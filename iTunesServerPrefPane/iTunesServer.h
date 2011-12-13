/*
 * iTunesServer.h
 */

#import <AppKit/AppKit.h>
#import <ScriptingBridge/ScriptingBridge.h>


@class iTunesServerApplication, iTunesServerConfiguration;



/*
 * iTunesServer Config Suite
 */

// Our simple application class.
@interface iTunesServerApplication : SBApplication

@property (copy) iTunesServerConfiguration *configuration;  // Configuration singleton

- (void) reloadConfiguration;  // Reloads the config, restarting the server if needed

@end

// iTunes Configuration Object
@interface iTunesServerConfiguration : SBObject

@property NSInteger port;  // The port on which iTunes Server runs.
@property NSInteger autoScanEnabled;  // Whether Auto Import is enabled
@property (copy) NSString *autoScanPath;  // The folder monitored for autoimport.
@property NSInteger startOnLogin;  // Whether server should start when user logs in.


@end

