//
//  MMPlaylistResource.m
//  CLIServer
//
//  Created by Kra on 5/14/11.
//  Copyright 2011 kra. All rights reserved.
//
#import <HTTPServe/HSResourceDescriptor.h>
#import <HTTPServe/HSResponse.h>
#import <HTTPServe/HSHandlerPath.h>
#import <HTTPServe/HSRequestParameters.h>

#import "MMPlaylistResource.h"

#import "iTunesContentRepository.h"
#import "ContentAssembler+iTunes.h"


@implementation MMPlaylistResource

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
