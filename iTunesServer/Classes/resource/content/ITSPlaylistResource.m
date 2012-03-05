//
//  MMPlaylistResource.m
//  CLIServer
//
//  Created by Kra on 5/14/11.
//  Copyright 2011 kra. All rights reserved.
//
#import <YARES/HSResourceDescriptor.h>
#import <YARES/HSResponse.h>
#import <YARES/HSHandlerPath.h>
#import <YARES/HSRequestParameters.h>

#import "ITSPlaylistResource.h"

#import "ITSiTunesContentRepository.h"
#import "MMContentAssembler+iTunes.h"


@implementation ITSPlaylistResource

#pragma mark - Rest Resource descriptor
- (NSArray*) resourceDescriptors
{
  HSResourceDescriptor *descriptor = [HSResourceDescriptor descriptorWithPath: @"/library/{playlistID}" resource:self andSelector:@selector(playlist:)];
  return [NSArray arrayWithObject: descriptor];
}

#pragma mark - Rest resource processing
- (HSResponse*) playlist: (HSRequestParameters*) params
{
  HSResponse *response = [HSResponse jsonResponse];
  
  NSString *playlistID = [params.pathParameters objectForKey:@"playlistID"];
  
#ifdef DEBUG
  NSLog(@"Fetching playlist %@", playlistID);
#endif
  
  MMPlaylist *playlist = [repository playlistWithPersistentID: playlistID];
  NSDictionary *dto = [contentAssembler writePlaylist: playlist];
  response.object = dto;
  
  return response;
}

@end
