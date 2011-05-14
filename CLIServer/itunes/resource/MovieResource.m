//
//  PhonyResource.m
//  CLIServer
//
//  Created by Kra on 3/12/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <HTTPServe/HSResourceDescriptor.h>
#import <HTTPServe/HSResponse.h>

#import <MediaManagement/MMContentAssembler.h>
#import <MediaManagement/MMPlaylist.h>

#import "MovieResource.h"

#import "iTunesContentRepository.h"




@implementation MovieResource

#pragma mark - Rest Resource descriptor
- (NSArray*) resourceDescriptors
{
  HSResourceDescriptor *descriptor = [HSResourceDescriptor descriptorWithPath:@"/movies" resource:self andSelector:@selector(movieLibrary:)];
  return [NSArray arrayWithObject: descriptor];
}

#pragma mark - Rest resource processing
- (HSResponse*) movieLibrary: (NSDictionary*) params
{
  HSResponse *response = [HSResponse jsonResponse];
  MMPlaylist *library = [repository movieLibrary];;
  
  NSDictionary *dto = [contentAssembler writeLibrary: library];
  response.object = dto;

  return response;
}
@end
