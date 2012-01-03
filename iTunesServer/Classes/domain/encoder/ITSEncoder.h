//
//  ITSEncoder.h
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/25/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "hb.h"

@class MMTitleList;

@interface ITSEncoder : NSObject
{
  __strong NSFileManager *fileManager;
  hb_handle_t *handbrakeScannerHandle;
  hb_handle_t *handbrakeEncodingHandle;
  
  NSMutableArray *scheduledTitles;
  
  BOOL scanInProgress;
  BOOL scanIsDone;
  
  BOOL encoderScanInProgress;
  BOOL encoderScanIsDone;
}

+ (ITSEncoder *) sharedEncoder;

- (MMTitleList *) scanPath: (NSString *) path;

- (void) scheduleTitleList: (MMTitleList *) titleList;

@end
