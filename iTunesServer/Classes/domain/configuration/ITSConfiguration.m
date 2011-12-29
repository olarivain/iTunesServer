//
//  ITSConfiguration.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/11/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import "ITSConfiguration.h"

@implementation ITSConfiguration

+ (ITSConfiguration *) configuration
{
  return [[ITSConfiguration alloc] init];
}

@synthesize port;
@synthesize startOnLogin;
@synthesize autoScanEnabled;
@synthesize autoScanPath;
@synthesize encodingResourcePath;

- (id) objectSpecifier
{ 
  NSApplication *application = [NSApplication sharedApplication];
  NSScriptClassDescription *classDescription = (NSScriptClassDescription*) [application classDescription];
  NSScriptObjectSpecifier *objectSpecifier = [application objectSpecifier];
  
  NSPropertySpecifier *specifier = [[NSPropertySpecifier alloc] initWithContainerClassDescription: classDescription containerSpecifier: objectSpecifier key:@"configuration"];
  return specifier;
}

@end
