//
//  ITSEncoder.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/25/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import "ITSEncoder.h"

#import "ITSTitleList.h"

static ITSEncoder *sharedEncoder;

@interface ITSEncoder()
- (void) performScanAtPath: (NSString *) path;
- (ITSTitleList *) readTitleListFromLastScanWithPath: (NSString *) path;
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
- (ITSTitleList *) scanPath: (NSString *) path
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
  ITSTitleList *titleList = [self readTitleListFromLastScanWithPath: path];
 
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

- (ITSTitleList *) readTitleListFromLastScanWithPath: (NSString *) path
{
  // now, grab the content
  hb_list_t *titles = hb_get_titles(handbrakeScannerHandle);
  
  int titlesCount = hb_list_count(titles);
  for(int i = 0; i < titlesCount; i++)
  {
//    hb_title_t *title = hb_list_item(titles, i);
//    int type = title->type;
//    NSString *name = [NSString stringWithUTF8String: title->name];
//    NSInteger index = (NSInteger) title->index;
//    NSInteger hours = (NSInteger) title->hours;
//    NSInteger minutes = (NSInteger) title->minutes;
//    NSInteger seconds = (NSInteger) title->seconds;
//    hb_metadata_t *metadata = title->metadata;
//    NSString *contentName = metadata == NULL ? nil : [NSString stringWithUTF8String: metadata->name];
    
  }
  return [ITSTitleList titleList];
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
