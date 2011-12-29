//
//  MMLibraryResource.m
//  CLIServer
//
//  Created by Kra on 5/14/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <HTTPServe/HSResourceDescriptor.h>
#import <HTTPServe/HSResponse.h>
#import <HTTPServe/HSHandlerPath.h>
#import <HTTPServe/HSRequestParameters.h>

#import "ITSLibraryResource.h"

#import "ITSiTunesContentRepository.h"
#import "MMContentAssembler+iTunes.h"



@implementation ITSLibraryResource

#pragma mark - Rest Resource descriptor
- (NSArray*) resourceDescriptors
{
  HSResourceDescriptor *descriptor = [HSResourceDescriptor descriptorWithPath: @"/library" resource:self andSelector:@selector(libraryHeaders:)];
  return [NSArray arrayWithObject: descriptor];
}

#pragma mark - Rest resource processing
- (HSResponse*) libraryHeaders: (HSRequestParameters*) params
{
  HSResponse *response = [HSResponse jsonResponse];

  NSArray *playlists = [repository playlistHeaders];
  
  NSArray *dtos = [contentAssembler writePlaylists: playlists];
  response.object = dtos;
  
  return response;
}

@end
