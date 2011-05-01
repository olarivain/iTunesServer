//
//  MusicResource.h
//  CLIServer
//
//  Created by Kra on 4/3/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>
@class iTunesContentRepository;
@class ContentAssembler;

@interface MusicResource : NSObject<HSRestResource> 
{
@private
  iTunesContentRepository *repository;
  ContentAssembler *contentAssembler;
  
}

- (NSArray*) resourceDescriptors;

@end
