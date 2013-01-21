//
//  ITSApplication.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/11/11.
//  Copyright (c) 2011 kra. All rights reserved.
//

#import "ITSApplication.h"

#import "ITSConfigurationRepository.h"
#import "ITSAppDelegate.h"

@implementation NSApplication (ITSApplication)

-(id) reloadConfiguration:(NSScriptCommand *)command
{
	ITSAppDelegate *theDelegate = (ITSAppDelegate *) self.delegate;
	[theDelegate reloadConfiguration];
	return nil;
}

- (ITSConfiguration *) configuration
{
	ITSConfigurationRepository *repository = [ITSConfigurationRepository sharedInstance];
	return [repository readConfiguration];
}

@end
