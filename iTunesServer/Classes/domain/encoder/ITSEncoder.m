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
#import "MMAudioTrack+MMAudioTrack_Handbrake.h"

static ITSEncoder *sharedEncoder;

@interface ITSEncoder()
- (void) performScanAtPath: (NSString *) path;
- (MMTitleList *) readTitleListFromLastScanWithPath: (NSString *) path;
- (NSArray *) soundTracksFromHBTitle: (hb_title_t *) hbTitle;
- (NSArray *) subtitleTracksFromHBTitle: (hb_title_t *) hbTitle;
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
  // abort early for nonsensical data
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
    
    NSInteger duration = hbTitle->duration;
    MMTitle *mmTitle = [MMTitle titleWithIndex: index andDuration: duration];
    [titleList addtitle: mmTitle];
    
    NSArray *soundTracks = [self soundTracksFromHBTitle: hbTitle];
    for(MMAudioTrack *soundtrack in soundTracks)
    {
      [mmTitle addAudioTrack: soundtrack];
    }

    NSArray *subtitleTracks = [self subtitleTracksFromHBTitle: hbTitle];
    for(MMSubtitleTrack *subtitleTrack in subtitleTracks)
    {
      [mmTitle addSubtitleTrack: subtitleTrack];
    }
  }
  return titleList;
}

#pragma mark Extracting soundtracks
- (NSArray *) soundTracksFromHBTitle: (hb_title_t *) hbTitle
{
  // grab audio list from hb list, check for null first thing
  hb_list_t *hbSoundTracks = hbTitle->list_audio;
  if(hbSoundTracks == NULL)
  {
    return nil;
  }
  
  // iterate of audio tracks, and build MMAudioTrack wrappers.
  int soundTracksCount = hb_list_count(hbSoundTracks);

  NSMutableArray *audioTracks = [NSMutableArray arrayWithCapacity: soundTracksCount];
  for(int j = 0; j < soundTracksCount; j++)
  {
    hb_audio_t *hbAudioTrack = hb_list_item(hbSoundTracks, j);
    // same old, same old, C code, check for null before dereferencing anything
    if(hbAudioTrack == NULL)
    {
      continue;
    }
    
    hb_audio_config_t audioConfig = hbAudioTrack->config;
    
    // audio track index
    NSInteger index = (NSInteger) audioConfig.in.track;
    
    // audio config: codec, channel layout and LFE
    NSInteger codec = (NSInteger) audioConfig.in.codec;
    NSInteger channelLayout = (NSInteger) audioConfig.in.channel_layout;
    
    // audio track language (ISO 4 char code)
    const char *isoLanguageCodeChar = audioConfig.lang.iso639_2;
    NSString *isoLanguageCode = isoLanguageCodeChar == NULL ? nil : [NSString stringWithCString: isoLanguageCodeChar encoding: NSUTF8StringEncoding];
    
    // now we can build the audio track and add it to the returned list
    MMAudioTrack *audioTrack = [MMAudioTrack audiotTrackWithHandbrakeIndex: index 
                                                                     codec: codec 
                                                             channelLayout: channelLayout
                                                               andLanguage: isoLanguageCode];
    [audioTracks addObject: audioTrack];
  }
  
  return audioTracks;
}

#pragma mark Extracting subtitle tracks
- (NSArray *) subtitleTracksFromHBTitle: (hb_title_t *) hbTitle
{
  return nil;
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
