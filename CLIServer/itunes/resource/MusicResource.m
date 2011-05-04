//
//  MusicResource.m
//  CLIServer
//
//  Created by Kra on 4/3/11.
//  Copyright 2011 kra. All rights reserved.
//


#import <HTTPServe/HSResourceDescriptor.h>
#import <HTTPServe/HSResponse.h>

#import <MediaManagement/MMContentAssembler.h>
#import <MediaManagement/MMContent.h>
#import <MediaManagement/MMMediaLibrary.h>
#import <MediaManagement/MMServerMediaLibrary.h>

#import "MusicResource.h"

#import "iTunesContentRepository.h"



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
  HSResourceDescriptor *descriptor = [HSResourceDescriptor descriptorWithPath:@"/music" resource:self andSelector:@selector(musicLibrary:)];
  return [NSArray arrayWithObject: descriptor];
}

#pragma mark - Rest resource processing
- (HSResponse*) musicLibrary: (NSDictionary*) params
{
  HSResponse *response = [HSResponse response];
  MMMediaLibrary *library = [repository musicLibrary];
  
  NSDictionary *data = [contentAssembler writeLibrary: library];
  response.object = data;
  return response;
}

@end
