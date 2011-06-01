//
//  MMTrackResource.m
//  CLIServer
//
//  Created by Kra on 5/30/11.
//  Copyright 2011 kra. All rights reserved.
//


#import <HTTPServe/HSResourceDescriptor.h>
#import <HTTPServe/HSResponse.h>
#import <HTTPServe/HSHandlerPath.h>
#import <HTTPServe/HSRequestParameters.h>

#import "MMTrackResource.h"

#import "iTunesContentRepository.h"
#import "ContentAssembler+iTunes.h"

@implementation MMTrackResource

#pragma mark - Rest Resource descriptor
- (NSArray*) resourceDescriptors
{
  HSResourceDescriptor *descriptor = [HSResourceDescriptor descriptorWithPath: @"/tracks" resource:self selector:@selector(updateTracks:) andMethod: POST];
  return [NSArray arrayWithObject: descriptor];
}

#pragma mark - Rest resource processing
- (HSResponse*) updateTracks: (HSRequestParameters*) params
{
  HSResponse *response = [HSResponse jsonResponse];

  MMContentAssembler *assembler = [MMContentAssembler sharedInstance];
  
  NSArray *dtos = params.parameters;
//  NSArray *tracks = [assembler c
//  NSArray *playlists = [repository playlistHeaders];
  
//  NSArray *dtos = [contentAssembler writePlaylists: playlists];
  response.object = dtos;
  
  return response;
}


@end
