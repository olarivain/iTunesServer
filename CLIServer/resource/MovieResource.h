//
//  PhonyResource.h
//  CLIServer
//
//  Created by Kra on 3/12/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RestResource.h"

@class iTunesContentRepository;
@class ContentAssembler;
@interface MovieResource : NSObject<HSRestResource> 
{
  @private
  iTunesContentRepository *repository;
  ContentAssembler *contentAssembler;
    
}

- (NSArray*) resourceDescriptors;

@end
