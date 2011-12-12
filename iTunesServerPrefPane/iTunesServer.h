/*
 * iTunesServer.h
 */

#import <AppKit/AppKit.h>
#import <ScriptingBridge/ScriptingBridge.h>


@class iTunesServerApplication, iTunesServerITunesServerConfiguration;



/*
 * iTunesServer Config Suite
 */

// Our simple application class.
@interface iTunesServerApplication : SBApplication

@property (copy) iTunesServerITunesServerConfiguration *configuration;  // the weight of all of the items in the application

@end

// iTunes Configuration Object
@interface iTunesServerITunesServerConfiguration : SBObject

@property NSInteger port;  // The port on which iTunes Server runs.
@property NSInteger autoScanEnabled;  // Whether Auto Import is enabled
@property (copy) NSString *autoScanPath;  // The folder monitored for autoimport.
@property NSInteger startOnLogin;  // Whether server should start when user logs in.

@end

