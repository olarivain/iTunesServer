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

@interface ResourceDescriptor : NSObject {
@private
  NSString *path;
  HttpMethod method;
  SEL selector;
  id<RestResource> resource;
}

+ (id) descriptorWithPath: (NSString*) resourcePath resource: (id<RestResource>) resource andSelector: (SEL) sel;
+ (id) descriptorWithPath: (NSString*) resourcePath resource: (id<RestResource>) resource selector: (SEL) sel andMethod: (HttpMethod) resourceMethod;

@property (readwrite, retain) NSString *path;
@property (readwrite, assign) HttpMethod method;
@property (readwrite, assign) SEL selector;
@property (readwrite, retain) id<RestResource> resource;

@end
