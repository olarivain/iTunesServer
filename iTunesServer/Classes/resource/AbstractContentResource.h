//
//  AbstractContentResource.h
//  CLIServer
//
//  Created by Kra on 5/3/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>

@class iTunesContentRepository;
@class MMContentAssembler;

@interface AbstractContentResource : NSObject
{
  iTunesContentRepository *repository;
  MMContentAssembler *contentAssembler;
  
}
@end
