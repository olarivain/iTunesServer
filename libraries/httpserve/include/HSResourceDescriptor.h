//
//  ResourceDescriptor.h
//  HTTPServe
//
//  Created by Kra on 2/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HttpMethod.h"
#import "RestResource.h"

@interface HSResourceDescriptor : NSObject {
@private
  NSString *path;
  HttpMethod method;
  SEL selector;
  id<HSRestResource> resource;
}

+ (id) descriptorWithPath: (NSString*) resourcePath resource: (id<HSRestResource>) resource andSelector: (SEL) sel;
+ (id) descriptorWithPath: (NSString*) resourcePath resource: (id<HSRestResource>) resource selector: (SEL) sel andMethod: (HttpMethod) resourceMethod;

@property (readwrite, retain) NSString *path;
@property (readwrite, assign) HttpMethod method;
@property (readwrite, assign) SEL selector;
@property (readwrite, retain) id<HSRestResource> resource;

@end
