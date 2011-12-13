//
//  ITSAppDelegate.h
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/10/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HSHTTPServe;

@interface ITSAppDelegate : NSObject <NSApplicationDelegate> {
  __strong HSHTTPServe *server;
}

@property (assign) IBOutlet NSWindow *window;

- (void) reloadConfiguration;

@end
