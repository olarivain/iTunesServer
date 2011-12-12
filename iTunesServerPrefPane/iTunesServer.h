/*
 * iTunesServer.h
 */

#import <AppKit/AppKit.h>
#import <ScriptingBridge/ScriptingBridge.h>


@class iTunesServerApplication;



/*
 * iTunesServer Config Suite
 */

// Our simple application class.
@interface iTunesServerApplication : SBApplication

- (void) updateConfig;  // ReloadConfig

@end

