//
//  ITSEncoder.h
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/25/11.
//  Copyright (c) 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "hb.h"

@class MMTitleList;
@class MMTitle;

@interface ITSEncoder : NSObject
{
  // shared file manager
  __strong NSFileManager *fileManager;
  // list of scheduled titles
  __strong NSMutableArray *scheduledTitles;
  // title list currently in progress
  __strong MMTitleList *activeTitleList;
  __strong MMTitle *activeTitle;
  // timer used to poll the encoding queue
  __strong NSTimer *encoderTimer;
  
  // hb handles used for scanning and encoding content
  hb_handle_t *handbrakeScannerHandle;
  hb_handle_t *handbrakeEncodingHandle;
  
  BOOL scanInProgress;
  BOOL scanIsDone;
  
  BOOL encoderScanIsDone;
  BOOL encodeScheduleInProgress;
}

+ (ITSEncoder *) sharedEncoder;

@property (nonatomic, readonly) MMTitle *activeTitle;

- (MMTitleList *) scanPath: (NSString *) path;
- (NSError *) deleteResource: (NSString *) resource;

- (void) scheduleTitleList: (MMTitleList *) titleList;

- (void) closeLibHB;


@end
