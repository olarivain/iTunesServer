//
//  ITSScriptCommand.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/11/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import "ITSScriptCommand.h"

#import "ITSApplication.h"

@implementation ITSScriptCommand

- (id) initWithCommandDescription:(NSScriptCommandDescription *)commandDef
{
  self = [super initWithCommandDescription: commandDef];
  return self;
}

- (id) performDefaultImplementation
{
  NSApplication *app = [NSApplication sharedApplication];
  [app updateConfig: self];
  return nil;
}

@end
