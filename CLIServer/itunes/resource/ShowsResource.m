//
//  ShowsResource.m
//  CLIServer
//
//  Created by Kra on 5/3/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <HTTPServe/HSResourceDescriptor.h>
#import <HTTPServe/HSResponse.h>

#import <MediaManagement/MMContentAssembler.h>
#import <MediaManagement/MMMediaLibrary.h>

#import "ShowsResource.h"

#import "iTunesContentRepository.h"

@implementation ShowsResource

#pragma mark - Rest Resource descriptor
- (NSArray*) resourceDescriptors
{
  HSResourceDescriptor *descriptor = [HSResourceDescriptor descriptorWithPath:@"/shows" resource:self andSelector:@selector(showsLibrary:)];
  return [NSArray arrayWithObject: descriptor];
}

#pragma mark - Rest resource processing


- (HSResponse*) showsLibrary: (NSDictionary*) params
{
  HSResponse *response = [HSResponse jsonResponse];
  MMMediaLibrary *library = [repository showsLibrary];
  
  NSDictionary *dto = [contentAssembler writeLibrary: library];
  response.object = dto;
  
  return response;
}


@end
