//
//  AbstractContentResource.m
//  CLIServer
//
//  Created by Kra on 5/3/11.
//  Copyright 2011 kra. All rights reserved.
//
#import <MediaManagement/MMContentAssembler.h>

#import "ITSAbstractContentResource.h"

#import "ITSiTunesContentRepository.h"

@implementation ITSAbstractContentResource

- (id)init
{
  self = [super init];
  if (self) 
  {
    repository = [[ITSiTunesContentRepository alloc] init];
    contentAssembler = [MMContentAssembler sharedInstance];
  }
  
  return self;
}


@end
