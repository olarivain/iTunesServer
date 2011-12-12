//
//  ITSApplication.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/11/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import "ITSApplication.h"

#import "ITSAppDelegate.h"

@implementation NSApplication (ITSApplication)

-(void) updateConfig:(NSScriptCommand *)command
{
  ITSAppDelegate *theDelegate = (ITSAppDelegate *) self.delegate;
  [theDelegate updateConfig];
  return nil;
}

@end
