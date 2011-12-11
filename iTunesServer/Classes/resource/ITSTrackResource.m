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
#import <MediaManagement/MMContent.h>

#import "ITSTrackResource.h"
#import "iTunesContentRepository.h"
#import "ContentAssembler+iTunes.h"

@implementation ITSTrackResource

#pragma mark - Rest Resource descriptor
- (NSArray*) resourceDescriptors
{
  HSResourceDescriptor *trackDescriptor = [HSResourceDescriptor descriptorWithPath: @"/library/{playlistId}/{trackId}" resource:self selector:@selector(updateTrack:) andMethod: POST];
  HSResourceDescriptor *tracksDescriptor = [HSResourceDescriptor descriptorWithPath: @"/library/{playlistId}/" resource:self selector:@selector(updateTracks:) andMethod: POST];

  return [NSArray arrayWithObjects: trackDescriptor, tracksDescriptor, nil];
}

#pragma mark - Rest resource processing
- (HSResponse*) updateTracks: (HSRequestParameters*) params
{
  HSResponse *response = [HSResponse jsonResponse];

  MMContentAssembler *assembler = [MMContentAssembler sharedInstance];
  
  NSArray *dtos = params.parameters;
  NSArray *tracks = [assembler createContentArray: dtos];
  [repository updateContents: tracks];
  
  return response;
}

- (HSResponse*) updateTrack: (HSRequestParameters*) params
{
  HSResponse *response = [HSResponse jsonResponse];
  
  MMContentAssembler *assembler = [MMContentAssembler sharedInstance];
  
  NSDictionary *dto = params.parameters;
  MMContent *track = [assembler createContent: dto];
 
#ifdef DEBUG
  NSLog(@"Updating track %@", track.name);
#endif
  
  NSArray *tracks = [NSArray arrayWithObject: track];
  [repository updateContents: tracks];
  
  return response;
}

@end
