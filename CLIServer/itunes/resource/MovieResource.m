//
//  PhonyResource.m
//  CLIServer
//
//  Created by Kra on 3/12/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <HTTPServe/HSResourceDescriptor.h>
#import <HTTPServe/HSResponse.h>

#import <MediaManagement/MMContent.h>
#import <MediaManagement/MMContentAssembler.h>
#import <MediaManagement/MMServerMediaLibrary.h>

#import "MovieResource.h"

#import "iTunesContentRepository.h"




@implementation MovieResource

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

#pragma mark - Rest Resource descriptor
- (NSArray*) resourceDescriptors
{
  HSResourceDescriptor *descriptor = [HSResourceDescriptor descriptorWithPath:@"/movies" resource:self andSelector:@selector(movieLibrary:)];
  return [NSArray arrayWithObject: descriptor];
}

#pragma mark - Rest resource processing


- (HSResponse*) movieLibrary: (NSDictionary*) params
{
  HSResponse *response = [HSResponse response];
  MMMediaLibrary *library = [repository movieLibrary];;
  
  NSDictionary *dto = [contentAssembler writeLibrary: library];
  response.object = dto;

  return response;
}
@end
