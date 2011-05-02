//
//  PhonyResource.m
//  CLIServer
//
//  Created by Kra on 3/12/11.
//  Copyright 2011 kra. All rights reserved.
//

#import "HSResourceDescriptor.h"
#import "HSResponse.h"

#import "MovieResource.h"

#import "MMContent.h"
#import "iTunesContentRepository.h"

#import "MMContentAssembler.h"
#import "MMiTunesMediaLibrary.h"


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
  HSResourceDescriptor *descriptor = [HSResourceDescriptor descriptorWithPath:@"/movies" resource:self andSelector:@selector(allMovies:)];
  return [NSArray arrayWithObject: descriptor];
}

#pragma mark - Rest resource processing


- (HSResponse*) allMovies: (NSDictionary*) params
{
  HSResponse *response = [HSResponse response];
  MMMediaLibrary *library = [repository movieLibrary];;
  
  NSData *data = [contentAssembler writeLibrary: library];
  [response setContent: data];

  return response;
}
@end
