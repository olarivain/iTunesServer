//
//  MusicResource.m
//  CLIServer
//
//  Created by Kra on 4/3/11.
//  Copyright 2011 kra. All rights reserved.
//


#import "HSResourceDescriptor.h"
#import "HSResponse.h"

#import "MusicResource.h"

#import "MMContent.h"
#import "iTunesContentRepository.h"

#import "MMContentAssembler.h"
#import "MMMediaLibrary.h"
#import "MMiTunesMediaLibrary.h"


@implementation MusicResource

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
  HSResourceDescriptor *descriptor = [HSResourceDescriptor descriptorWithPath:@"/music" resource:self andSelector:@selector(allMusic:)];
  return [NSArray arrayWithObject: descriptor];
}

#pragma mark - Rest resource processing
- (HSResponse*) allMusic: (NSDictionary*) params
{
  HSResponse *response = [HSResponse response];
  MMMediaLibrary *library = [repository musicLibrary];
  
  NSData *data = [contentAssembler writeLibrary: library];
  [response setContent: data];
  return response;
}

@end
