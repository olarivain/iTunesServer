//
//  ITSConfigurationRepository.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/10/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import "ITSConfigurationRepository.h"

#import "ITSConfiguration.h"

static ITSConfigurationRepository *sharedInstance;

@implementation ITSConfigurationRepository

+ (ITSConfigurationRepository *) sharedInstance
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[ITSConfigurationRepository alloc] init];
  });
  
  return sharedInstance;
}

- (ITSConfiguration *) readConfiguration 
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    configuration = [ITSConfiguration configuration];
    configuration.port = 6969;
    configuration.autoScanPath = @"Mes couilles sur ton nez";
  });

  return configuration;
}

- (void) test
{
  NSLog(@"hooooo yeah!");
}

@end
