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
  HSResourceDescriptor *listResource = [HSResourceDescriptor descriptorWithPath: @"/encoder" 
                                                                       resource:self 
                                                                    andSelector:@selector(listResources:)];
  
  HSResourceDescriptor *scanResource = [HSResourceDescriptor descriptorWithPath: @"/encoder/{resourceId}" 
                                                                       resource:self 
                                                                    andSelector:@selector(scanResource:)];
  
  HSResourceDescriptor *encodeResource = [HSResourceDescriptor descriptorWithPath: @"/encoder/{resourceId}" 
                                                                                 resource:self 
                                                                                 selector:@selector(scheduleResourceForEncode:) 
                                                                                andMethod: POST];
    HSResourceDescriptor *deleteResource = [HSResourceDescriptor descriptorWithPath: @"/encoder/{resourceId}"
                                                                           resource:self
                                                                           selector:@selector(deleteResource:)
                                                                          andMethod: DELETE];
  
  return [NSArray arrayWithObjects: listResource, scanResource, encodeResource, deleteResource, nil];
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
  // passed ressources are double HTTP encoded (/ in path). 
  // YARES will HTTP escape once by design, take care of the second unescape explicitly here
  NSString *encodedResourceId = [params.pathParameters objectForKey: @"resourceId"];
  NSString *resourceId = [encodedResourceId stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
  
  // and ask encoder to scan that for us.
  ITSEncoder *encoder = [ITSEncoder sharedEncoder];
  MMTitleList *titleList = [encoder scanPath: resourceId];
  
  MMTitleAssembler *assembler = [MMTitleAssembler sharedInstance];
  HSResponse *response = [HSResponse jsonResponse];
  response.object = [assembler writeTitleList: titleList];
  
  // now, assemble that to JSON and return it.
  return response;
}

- (HSResponse *) scheduleResourceForEncode: (HSRequestParameters *) params
{
  NSDictionary *titleListDto = params.parameters;
  // passed ressources are double HTTP encoded (/ in path). 
  // YARES will HTTP escape once by design, take care of the second unescape explicitly here
  NSString *encodedResourceId = [params.pathParameters objectForKey: @"resourceId"];
  NSString *resourceId = [encodedResourceId stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
  
  // Scan first, to be sure we have the right content
  ITSEncoder *encoder = [ITSEncoder sharedEncoder];
  MMTitleList *titleList = [encoder scanPath: resourceId];
  
  // update title list from JSON object
  MMTitleAssembler *assembler = [MMTitleAssembler sharedInstance];
  [assembler updateTitleList: titleList withSelectionDto: titleListDto];
  
  // pass it to the encoder to schedule it.
  [encoder scheduleTitleList: titleList];
  HSResponse *response = [HSResponse jsonResponse];
  response.object = params.pathParameters;
  
  return response;
}

- (HSResponse *) deleteResource: (HSRequestParameters *) params {
  // passed ressources are double HTTP encoded (/ in path).
  // YARES will HTTP escape once by design, take care of the second unescape explicitly here
  NSString *encodedResourceId = [params.pathParameters objectForKey: @"resourceId"];
  NSString *resourceId = [encodedResourceId stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
  
  // now, delete the sucker
  ITSEncoder *encoder = [ITSEncoder sharedEncoder];
  NSError *error = [encoder deleteResource: resourceId];
  
  HSResponse *response = [HSResponse jsonResponse];
  response.code = error == nil ? OK : BAD_REQUEST;
  NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity: 1];
  [dictionary setObjectNilSafe: error.localizedDescription forKey: @"error"];
  response.object = dictionary;
  
  return response;
}

@end
