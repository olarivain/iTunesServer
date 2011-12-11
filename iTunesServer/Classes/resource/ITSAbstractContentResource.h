//
//  AbstractContentResource.h
//  CLIServer
//
//  Created by Kra on 5/3/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ITSiTunesContentRepository;
@class MMContentAssembler;

@interface ITSAbstractContentResource : NSObject
{
  ITSiTunesContentRepository *repository;
  MMContentAssembler *contentAssembler;
  
}
@end
