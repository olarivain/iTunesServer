//
//  iTunesUResource.m
//  CLIServer
//
//  Created by Kra on 5/3/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <HTTPServe/HSResourceDescriptor.h>
#import <HTTPServe/HSResponse.h>

#import <MediaManagement/MMContentAssembler.h>
#import <MediaManagement/MMMediaLibrary.h>

#import "iTunesUResource.h"

#import "iTunesContentRepository.h"

@implementation iTunesUResource

#pragma mark - Rest Resource descriptor
- (NSArray*) resourceDescriptors
{
  HSResourceDescriptor *descriptor = [HSResourceDescriptor descriptorWithPath:@"/itunesu" resource:self andSelector:@selector(iTunesULibrary:)];
  return [NSArray arrayWithObject: descriptor];
}

#pragma mark - Rest resource processing


- (HSResponse*) iTunesULibrary: (NSDictionary*) params
{
  HSResponse *response = [HSResponse jsonResponse];
  MMMediaLibrary *library = [repository iTunesULibrary];
  
  NSDictionary *dto = [contentAssembler writeLibrary: library];
  response.object = dto;
  
  return response;
}


@end
