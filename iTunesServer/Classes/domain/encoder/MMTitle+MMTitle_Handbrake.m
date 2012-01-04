//
//  MMTitle+MMTitle_Handbrake.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 1/3/12.
//  Copyright (c) 2012 Edmunds. All rights reserved.
//

#import "MMTitle+MMTitle_Handbrake.h"

@interface MMTitle()
- (id) initWithIndex:(NSInteger)index andHandbrakeDuration:(NSInteger)duration;
@end

@implementation MMTitle (MMTitle_Handbrake)

+ (MMTitle *) titleWithIndex:(NSInteger)index andHandbrakeDuration:(NSInteger)duration
{
  return [[MMTitle alloc] initWithIndex: index andHandbrakeDuration: duration];
}

- (id) initWithIndex: (NSInteger) anIndex andHandbrakeDuration: (NSInteger) aDuration
{
  self = [super init];
  if(self)
  {
    index = anIndex;
    audioTracks = [NSMutableArray arrayWithCapacity: 5];
    subtitleTracks = [NSMutableArray arrayWithCapacity: 5];
    duration = aDuration / 90000;
  }
  return self;
}

@end
