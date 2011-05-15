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
#import <MediaManagement/MMPlaylist.h>

#import "MusicResource.h"

#import "iTunesContentRepository.h"



@implementation MusicResource

#pragma mark - Rest Resource descriptor
- (NSArray*) resourceDescriptors
{
  HSResourceDescriptor *descriptor = [HSResourceDescriptor descriptorWithPath:@"/music" resource:self andSelector:@selector(musicLibrary:)];
  return [NSArray arrayWithObject: descriptor];
}

#pragma mark - Rest resource processing
- (HSResponse*) musicLibrary: (NSDictionary*) params
{
  HSResponse *response = [HSResponse jsonResponse];
  MMPlaylist *library = [repository musicLibrary];
  
  NSDictionary *data = [contentAssembler writePlaylist: library];
  response.object = data;
  return response;
}

@end
