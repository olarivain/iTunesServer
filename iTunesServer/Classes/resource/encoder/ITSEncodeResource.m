//
//  ITSEncodeResource.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/25/11.
//  Copyright (c) 2011 kra. All rights reserved.
//

#import <YARES/HSResourceDescriptor.h>
#import <YARES/HSResponse.h>
#import <YARES/HSHandlerPath.h>
#import <YARES/HSRequestParameters.h>

#import <MediaManagement/MMTitleAssembler.h>
#import "MMTitleAssembler+iTunesServer.h"
#import "ITSEncodeResource.h"

#import "ITSEncoder.h"
#import "ITSEncodingRepository.h"

@implementation ITSEncodeResource

- (NSArray*) resourceDescriptors 
{
  HSResourceDescriptor *listResource = [HSResourceDescriptor descriptorWithPath: @"/encoder" resource:self andSelector:@selector(listResources:)];
  HSResourceDescriptor *scanResource = [HSResourceDescriptor descriptorWithPath: @"/encoder/{resourceId}" resource:self andSelector:@selector(scanResource:)];
  HSResourceDescriptor *scheduleEncodeResource = [HSResourceDescriptor descriptorWithPath: @"/encoder/{resourceId}" resource:self selector:@selector(scheduleResourceForEncode:) andMethod: POST];
  
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
  // YARES will HTTP escape once by design, take care of the second unescape explicitly here
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

- (HSResponse *) scheduleResourceForEncode: (HSRequestParameters *) params
{
  // rebuild title list from JSON object
  MMTitleAssembler *assembler = [MMTitleAssembler sharedInstance];
  MMTitleList *titleList = [assembler updateTitleListWithDto: params.parameters];
  
  // pass it to the encoder to schedule it.
  ITSEncoder *encoder = [ITSEncoder sharedEncoder];
  [encoder scheduleTitleList: titleList];
  HSResponse *response = [HSResponse jsonResponse];
  response.object = params.pathParameters;
  
  return response;
}

@end
