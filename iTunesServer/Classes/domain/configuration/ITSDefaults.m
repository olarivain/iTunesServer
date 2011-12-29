//
//  ITSDefaults.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/11/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#define BOOSTRAPPED_KEY @"bootstrapped"

#import "ITSDefaults.h"

@implementation ITSDefaults

+ (void) bootstrapDefaults: (NSUserDefaults *) defaults
{
  // bootstrap did fire once, get the hell out of here
  if([defaults boolForKey: BOOSTRAPPED_KEY])
  {
    return;
  }
  
  NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity: 4];
  [dictionary setObject: [NSNumber numberWithInteger: 0] forKey: ITUNES_SERVER_PORT_KEY];
  [dictionary setObject: [NSNumber numberWithInteger: 0] forKey: AUTO_IMPORT_KEY];
  [dictionary setObject: [NSNumber numberWithInteger: 1] forKey: START_ON_LOGIN_KEY];
  
  [defaults registerDefaults: dictionary];
  [defaults setObject: [NSNumber numberWithInteger: 1] forKey: BOOSTRAPPED_KEY];
  
}

@end
