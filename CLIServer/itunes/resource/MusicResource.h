//
//  MusicResource.h
//  CLIServer
//
//  Created by Kra on 4/3/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>
@class iTunesContentRepository;
@class MMContentAssembler;

@interface MusicResource : NSObject<HSRestResource> 
{
@private
  iTunesContentRepository *repository;
  MMContentAssembler *contentAssembler;
  
}

- (NSArray*) resourceDescriptors;

@end
