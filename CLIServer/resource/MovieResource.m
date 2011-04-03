//
//  PhonyResource.m
//  CLIServer
//
//  Created by Kra on 3/12/11.
//  Copyright 2011 kra. All rights reserved.
//

#import "ResourceDescriptor.h"
#import "Response.h"

#import "MovieResource.h"

#import "Content.h"
#import "iTunesContentRepository.h"

#import "ContentAssembler.h"


@implementation MovieResource

- (id)init
{
    self = [super init];
    if (self) 
    {
      repository = [[iTunesContentRepository alloc] init];
      contentAssembler = [[ContentAssembler sharedInstance] retain];
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
  ResourceDescriptor *descriptor = [ResourceDescriptor descriptorWithPath:@"/movies" resource:self andSelector:@selector(allMovies:)];
  return [NSArray arrayWithObject: descriptor];
}

#pragma mark - Rest resource processing


- (Response*) allMovies: (NSDictionary*) params
{
  Response *response = [Response response];
  NSArray *content = [repository allMovies];
  
  NSData *data = [contentAssembler writeObject: content];
  [response setContent: data];
  return response;
}
@end
