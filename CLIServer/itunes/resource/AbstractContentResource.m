//
//  AbstractContentResource.m
//  CLIServer
//
//  Created by Kra on 5/3/11.
//  Copyright 2011 kra. All rights reserved.
//
#import <MediaManagement/MMContentAssembler.h>

#import "AbstractContentResource.h"

#import "iTunesContentRepository.h"

@implementation AbstractContentResource

- (id)init
{
  self = [super init];
  if (self) 
  {
    repository = [[iTunesContentRepository alloc] init];
    contentAssembler = [[MMContentAssembler sharedInstance] retain];
  }
  
  return self;
}

- (void)dealloc
{
  [repository release];
  [contentAssembler release];
  [super dealloc];
}

@end
