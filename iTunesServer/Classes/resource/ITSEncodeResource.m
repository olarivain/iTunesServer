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
#import "hb.h"

@implementation ITSEncodeResource

- (NSArray*) resourceDescriptors 
{
  HSResourceDescriptor *descriptor = [HSResourceDescriptor descriptorWithPath: @"/encoder" resource:self andSelector:@selector(encoder:)];
  return [NSArray arrayWithObject: descriptor];
}

- (HSResponse *) encoder: (HSRequestParameters*) params
{
  hb_handle_t *handle = hb_init(0, 0);
  hb_dvd_set_dvdnav(true);
  hb_scan( handle, [@"/Users/olarivain/Movies/ALIAS S5D3.dvdmedia/" UTF8String], 0, 10, 1 , 1 );
  HSResponse *response = [HSResponse NOT_FOUND_RESPONSE];
}

@end
