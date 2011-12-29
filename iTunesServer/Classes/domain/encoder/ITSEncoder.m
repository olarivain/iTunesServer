//
//  ITSEncoder.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/25/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import "ITSEncoder.h"

#import <MediaManagement/MMTitleList.h>
#import <MediaManagement/MMTitle.h>

static ITSEncoder *sharedEncoder;

@interface ITSEncoder()
- (void) performScanAtPath: (NSString *) path;
- (MMTitleList *) readTitleListFromLastScanWithPath: (NSString *) path;
@end

@implementation ITSEncoder

+ (ITSEncoder *) sharedEncoder
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedEncoder = [[ITSEncoder alloc] init];
  });
  return sharedEncoder;
}

- (id) init
{
  self = [super init];
  if(self)
  {
    // init hb library
    // tell it to STFU and to not check for updates.
    handbrakeScannerHandle = hb_init(HB_DEBUG_NONE, 0);
    // we want to use dvd nav library
    hb_dvd_set_dvdnav(true);
    
    fileManager = [NSFileManager defaultManager];
  }
  
  return self;
}

#pragma mark - Scanning content
#pragma mark Schedule a Scan
- (MMTitleList *) scanPath: (NSString *) path
{
  // abort eary for nonsensical data
  if([path length] == 0 || ![fileManager fileExistsAtPath: path])
  {
    return nil;
  }
  
  // make sure only 1 thread can run a scan at a time
  NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
  // this synchronized block should take care of synchronization, unless there's an obvious flaw I'm missing
  @synchronized(self)
  {
    while(scanInProgress && [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.2]])
    {
    }

    scanInProgress = YES;
  }
  
  // go ahead an tell libhb to do the scan
  [self performScanAtPath: path];
  MMTitleList *titleList = [self readTitleListFromLastScanWithPath: path];
 
  // flip the synchronization switch so other threads can resume
  scanInProgress = NO;
  
  return titleList;
}

#pragma mark libhb actual scan
- (void) performScanAtPath: (NSString *) path
{
  scanIsDone = NO;
  
  // ask libhb to scan requested content
  hb_scan(handbrakeScannerHandle, [path UTF8String], 0, 10, 1 , 1 );
  
  // Block current thread until the scan is done by running currentRunLoop.
  // We don't wait multiple request to be processed at the same time
  // first, setup the timer that will periodically check if the current scan is done
  NSTimer *timer = [NSTimer timerWithTimeInterval: 0.5 
                                           target: self 
                                         selector:@selector(timerCheckScanner:) 
                                         userInfo: nil 
                                          repeats: YES];
  
  // schedule the timer on the current run loop
  NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
  [runLoop addTimer: timer forMode: NSDefaultRunLoopMode];
  
  // and run until we're out.
  while(!scanIsDone && [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.2]])
  {
  }
}

- (MMTitleList *) readTitleListFromLastScanWithPath: (NSString *) path
{
  // now, grab the content
  hb_list_t *titles = hb_get_titles(handbrakeScannerHandle);
  
  // go through all titles, grab 
  int titlesCount = hb_list_count(titles);
  if(titlesCount == 0)
  {
    return nil;
  }
  
  MMTitleList *titleList = [MMTitleList titleListWithId: path];
  for(int i = 0; i < titlesCount; i++)
  {
    // grab next title
    hb_title_t *hbTitle = hb_list_item(titles, i);
    // make sure we have content that makes sense.
    if(hbTitle == NULL)
    {
      continue;
    }

    // now read basic fields and create Title object from them
    NSInteger index = (NSInteger) hbTitle->index;
    
    hb_list_t *chapterList = hbTitle->list_chapter;
    NSInteger chapterCount = chapterList == NULL ? 0 : (NSInteger) hb_list_count(chapterList);
    
    NSInteger duration = hbTitle->duration;
    MMTitle *mmTitle = [MMTitle titleWithIndex: index chapterCount: chapterCount andDuration: duration];
    [titleList addtitle: mmTitle];
  }
  return titleList;
}

#pragma mark Scanner timers
- (void) timerCheckScanner: (NSTimer *) timer
{
  hb_state_t scannerState;
  hb_get_state(handbrakeScannerHandle, &scannerState);
  if(scannerState.state == HB_STATE_SCANDONE)
  {
    scanIsDone = YES;
    [timer invalidate];
  }
}

@end
