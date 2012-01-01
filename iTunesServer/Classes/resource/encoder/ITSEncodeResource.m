//
//  ITSEncodeResource.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/25/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import <HTTPServe/HSResourceDescriptor.h>
#import <HTTPServe/HSResponse.h>
#import <HTTPServe/HSHandlerPath.h>
#import <HTTPServe/HSRequestParameters.h>

#import <MediaManagement/MMTitleAssembler.h>

#import "ITSEncodeResource.h"

#import "ITSEncoder.h"
#import "ITSEncodingRepository.h"

@implementation ITSEncodeResource

- (NSArray*) resourceDescriptors 
{
  HSResourceDescriptor *listResource = [HSResourceDescriptor descriptorWithPath: @"/encoder" resource:self andSelector:@selector(listResources:)];
  HSResourceDescriptor *scanResource = [HSResourceDescriptor descriptorWithPath: @"/encoder/{resourceId}" resource:self andSelector:@selector(scanResource:)];
  HSResourceDescriptor *scheduleEncodeResource = [HSResourceDescriptor descriptorWithPath: @"/encoder/{resourceId}" resource:self selector:@selector(scheduleEncodeResource:) andMethod: POST];
  
  return [NSArray arrayWithObjects: listResource, scanResource, scheduleEncodeResource, nil];
}

- (HSResponse *) listResources: (HSRequestParameters*) params
{
  // ask repository for available resources
  ITSEncodingRepository *repository = [ITSEncodingRepository sharedInstance];
  NSArray *resources = [repository availableTitleLists];
  
  // assemble and return
  MMTitleAssembler *assembler = [MMTitleAssembler sharedInstance];
  HSResponse *response = [HSResponse jsonResponse];
  response.object = [assembler writeTitleLists: resources];
  return response;
}

- (HSResponse *) scanResource: (HSRequestParameters *) params
{
  ITSEncoder *encoder = [ITSEncoder sharedEncoder];
  // passed ressources are double HTTP encoded (/ in path). 
  // HTTPServe will HTTP escape once by design, take care of the second unescape explicitly here
  NSString *encodedResourceId = [params.pathParameters objectForKey: @"resourceId"];
  NSString *resourceId = [encodedResourceId stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
  
  // and ask encoder to scan that for us.
  MMTitleList *titleList = [encoder scanPath: resourceId];
  
  MMTitleAssembler *assembler = [MMTitleAssembler sharedInstance];
  HSResponse *response = [HSResponse jsonResponse];
  response.object = [assembler writeTitleList: titleList];
  
  // now, assemble that to JSON and return it.
  return response;
}

- (HSResponse *) scheduleEncodeResource: (HSRequestParameters *) params
{
  NSLog(@"We have an encoder here");
  HSResponse *response = [HSResponse jsonResponse];
  response.object = params.pathParameters;
  
  return response;
}

@end
