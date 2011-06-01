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

#import "MMTrackResource.h"
#import "iTunesContentRepository.h"
#import "ContentAssembler+iTunes.h"

@implementation MMTrackResource

#pragma mark - Rest Resource descriptor
- (NSArray*) resourceDescriptors
{
  HSResourceDescriptor *tracksDescriptor = [HSResourceDescriptor descriptorWithPath: @"/tracks" resource:self selector:@selector(updateTracks:) andMethod: POST];
  HSResourceDescriptor *trackDescriptor = [HSResourceDescriptor descriptorWithPath: @"/track" resource:self selector:@selector(updateTrack:) andMethod: POST];

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
  
  NSArray *tracks = [NSArray arrayWithObject: track];
  [repository updateContents: tracks];
  
  return response;
}

@end
