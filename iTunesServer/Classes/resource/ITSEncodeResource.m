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

#import "ITSEncodeResource.h"

#import "ITSEncoder.h"
#import "ITSEncodingRepository.h"

@implementation ITSEncodeResource

- (NSArray*) resourceDescriptors 
{
  HSResourceDescriptor *listResource = [HSResourceDescriptor descriptorWithPath: @"/encoder" resource:self andSelector:@selector(listResources:)];
  HSResourceDescriptor *scanResource = [HSResourceDescriptor descriptorWithPath: @"/encoder/{resourceId}" resource:self andSelector:@selector(scanResource:)];
  
  return [NSArray arrayWithObjects: listResource, scanResource, nil];
}

- (HSResponse *) listResources: (HSRequestParameters*) params
{
  // ask repository for available resources
  ITSEncodingRepository *repository = [ITSEncodingRepository sharedInstance];
  NSArray *resources = [repository availableResources];
  
  // and just return them, as is
  HSResponse *response = [HSResponse jsonResponse];
  response.object = resources;
  return response;
}

- (HSResponse *) scanResource: (HSRequestParameters *) params
{
  ITSEncoder *encoder = [ITSEncoder sharedEncoder];
  NSString *encodedResourceId = [params.pathParameters objectForKey: @"resourceId"];
  NSString *resourceId = [encodedResourceId stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
  [encoder scanPath: resourceId];
  return  [HSResponse emptyResponse];

}

@end
