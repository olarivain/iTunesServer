//
//  ITSApplication.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/11/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import "ITSApplication.h"

#import "ITSConfigurationRepository.h"
#import "ITSConfiguration.h"

@implementation NSApplication (ITSApplication)

- (ITSConfiguration *) configuration
{
  ITSConfigurationRepository *repository = [ITSConfigurationRepository sharedInstance];
  return [repository readConfiguration];
}

@end
