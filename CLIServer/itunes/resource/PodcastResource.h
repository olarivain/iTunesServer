//
//  PodcastResource.h
//  CLIServer
//
//  Created by Kra on 5/3/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HTTPServe/HSRestResource.h>

@class iTunesContentRepository;
@class MMContentAssembler;

@interface PodcastResource : NSObject<HSRestResource> 
{
@private
  iTunesContentRepository *repository;
  MMContentAssembler *contentAssembler;
  
}

- (NSArray*) resourceDescriptors;
@end
