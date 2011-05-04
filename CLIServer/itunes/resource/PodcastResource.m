//
//  PodcastResource.m
//  CLIServer
//
//  Created by Kra on 5/3/11.
//  Copyright 2011 kra. All rights reserved.
//
#import <HTTPServe/HSResourceDescriptor.h>
#import <HTTPServe/HSResponse.h>

#import <MediaManagement/MMContentAssembler.h>
#import <MediaManagement/MMMediaLibrary.h>

#import "PodcastResource.h"

#import "iTunesContentRepository.h"

@implementation PodcastResource
#pragma mark - Rest Resource descriptor
- (NSArray*) resourceDescriptors
{
  HSResourceDescriptor *descriptor = [HSResourceDescriptor descriptorWithPath:@"/podcasts" resource:self andSelector:@selector(podcastLibrary:)];
  return [NSArray arrayWithObject: descriptor];
}

#pragma mark - Rest resource processing


- (HSResponse*) podcastLibrary: (NSDictionary*) params
{
  HSResponse *response = [HSResponse response];
  MMMediaLibrary *library = [repository podcastLibrary];
  
  NSDictionary *dto = [contentAssembler writeLibrary: library];
  response.object = dto;
  
  return response;
}

@end
