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
#import <MediaManagement/MMSubtitleTrack.h>
#import "MMAudioTrack+MMAudioTrack_Handbrake.h"

static ITSEncoder *sharedEncoder;

@interface ITSEncoder()
- (void) performScanAtPath: (NSString *) path withHandbrakeHandle: (hb_handle_t *) handle;
- (MMTitleList *) readTitleListFromLastScanWithPath: (NSString *) path withHandbrakeHandle: (hb_handle_t *) handle;
- (NSArray *) soundTracksFromHBTitle: (hb_title_t *) hbTitle;
- (NSArray *) subtitleTracksFromHBTitle: (hb_title_t *) hbTitle;

- (void) performScheduleTitleListForEncode: (MMTitleList *) titleList;
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
    // we want to use dvd nav library
    hb_dvd_set_dvdnav(false);
    
    // init hb library  
    // tell it to STFU and to not check for updates.
    handbrakeScannerHandle = hb_init(HB_DEBUG_NONE, 0);
    handbrakeEncodingHandle = hb_init(HB_DEBUG_ALL, 0);
    scheduledTitles = [NSMutableArray arrayWithCapacity: 40];
    
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
  [self performScanAtPath: path withHandbrakeHandle: handbrakeScannerHandle];
  MMTitleList *titleList = [self readTitleListFromLastScanWithPath: path withHandbrakeHandle: handbrakeScannerHandle];
 
  // flip the synchronization switch so other threads can resume
  scanInProgress = NO;
  
  return titleList;
}

#pragma mark libhb actual scan
- (void) performScanAtPath: (NSString *) path withHandbrakeHandle: (hb_handle_t *) handle
{
  BOOL isEncodeScan = handle == handbrakeEncodingHandle;
  if(isEncodeScan)
  {
    encoderScanIsDone = NO;
  }
  else
  {
    scanIsDone = NO;
  }
  
  // ask libhb to scan requested content
  hb_scan(handle, [path UTF8String], 0, 10, 1 , 1 );
  
  SEL selector = isEncodeScan ? @selector(timerCheckEncodingScanner:) : @selector(timerCheckScanner:);
  
  // Block current thread until the scan is done by running currentRunLoop.
  // We don't wait multiple request to be processed at the same time
  // first, setup the timer that will periodically check if the current scan is done
  NSTimer *timer = [NSTimer timerWithTimeInterval: 0.5 
                                           target: self 
                                         selector:selector
                                         userInfo: nil 
                                          repeats: YES];
  
  // schedule the timer on the current run loop
  NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
  [runLoop addTimer: timer forMode: NSDefaultRunLoopMode];
  
  // and run until we're out.
  while(!(isEncodeScan ? encoderScanIsDone : scanIsDone) && [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.2]])
  {
  }
}

- (MMTitleList *) readTitleListFromLastScanWithPath: (NSString *) path withHandbrakeHandle: (hb_handle_t *) handle
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
  hb_list_t *hbSubtitleTracks = hbTitle->list_subtitle;
  // sanity check on C pointer
  if(hbSubtitleTracks == NULL)
  {
    return nil;
  }
  
  int subtitleTracksCount = hb_list_count(hbSubtitleTracks);
  
  // extract single subtitle track now
  NSMutableArray *subtitleTracks = [NSMutableArray arrayWithCapacity: subtitleTracksCount];
  for(int i = 0; i < subtitleTracksCount; i++)
  {
    hb_subtitle_t *hbSubtitleTrack = hb_list_item(hbSubtitleTracks, i);
    if(hbSubtitleTrack == NULL)
    {
      continue;
    }
    
    // extract index, type (vobsub/text) and language
    NSInteger index = (NSInteger) hbSubtitleTrack->track;
    MMSubtitleType type = hbSubtitleTrack->format == PICTURESUB ? SUBTITLE_VOBSUB : SUBTITLE_CLOSED_CAPTION;
    const char *isoLangChar = hbSubtitleTrack->iso639_2;
    NSString *language = isoLangChar == NULL ? nil : [NSString stringWithCString: isoLangChar encoding: NSUTF8StringEncoding];
    
    // now build subtitle track and add it to returned list
    MMSubtitleTrack *subtitleTrack = [MMSubtitleTrack subtitleTrackWithIndex: index language: language andType: type];
    [subtitleTracks addObject: subtitleTrack];
  }
  
  return subtitleTracks;
}

#pragma mark Scanner timers
- (void) timerCheckScanner: (NSTimer *) timer
{
  hb_state_t scannerState;
  hb_get_state(handbrakeScannerHandle, &scannerState);
  if(scannerState.state == HB_STATE_SCANDONE || scannerState.state == HB_STATE_IDLE)
  {
    scanIsDone = YES;
    [timer invalidate];
  }
}

#pragma mark - Schedule an encode
- (void) scheduleTitleList: (MMTitleList *) titleList
{
  NSString *path = titleList.titleListId;
  // abort early for nonsensical data
  if([path length] == 0 || ![fileManager fileExistsAtPath: path])
  {
    return;
  }
  
  // scheduling encodes require hb_* opaque types, so we have to schedule an encode.
  // same thing than for the regular scans, this is NOT thread safe, so use the same technique here
  // than we did for regular scans.
  // make sure only 1 thread can run a scan at a time
  NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
  // this synchronized block should take care of synchronization, unless there's an obvious flaw I'm missing
  @synchronized(self)
  {
    while(encoderScanInProgress && [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.2]])
    {
    }
    
    encoderScanInProgress = YES;
  }

  // perform the scan so the handle is populated with the content
  [self performScanAtPath: path withHandbrakeHandle: handbrakeEncodingHandle];
  // and schedule for encoding
  [self performScheduleTitleListForEncode: titleList];
  
  encoderScanInProgress = NO;
}
static void hb_cli_error_handler ( const char *errmsg )
{
  fprintf( stderr, "ERROR: %s\n", errmsg );
}


#pragma mark actual schedule (libhb)
- (void) performScheduleTitleListForEncode: (MMTitleList *) titleList
{
      hb_register_error_handler(&hb_cli_error_handler);
  // grab the handbrake title list first, and make sure it actually exist.
  hb_list_t *titles = hb_get_titles(handbrakeEncodingHandle);
  if(titles == NULL)
  {
    return;
  }
  
  int titlesCount = hb_list_count(titles);
  int jobIndex = hb_count(handbrakeEncodingHandle) ;
  // schedule every selected title
  NSArray *selectedTitles = titleList.selectedTitles;
  for(MMTitle *title in titleList.titles)
  {
    // skip if index is beyond count, just in case the data somehow got corrupted.
//    if(title.index > titlesCount)
//    {
//      continue;
//    }

    hb_title_t *handbrakeTitle = hb_list_item(titles, 0);
    // the job that will be submitted
    hb_job_t *job = handbrakeTitle->job;
    
    // enqueue the job as the last one
    job->sequence_id = jobIndex;
    job->title = handbrakeTitle;
    
    // encode all chapters
    job->chapter_start = 1;
    job->chapter_end = hb_list_count(handbrakeTitle->list_chapter);
//    
    // and mark them in mp4 file
    job->chapter_markers = 0;
    
    // we want to produce an mp4 file (of course)
    job->mux = HB_MUX_MP4;
    
    // set video codec to x264 (of course)
    job->vcodec = HB_VCODEC_X264;
    job->vquality = -1;
    job->vbitrate = 1500;
    job->width = 720;
    job->height = 480;
    job->cfr = 1;
    job->angle = 1;
    job->anamorphic.mode = 0;
    
    job->keep_ratio = 1;
    job->pass = 0;
    job->largeFileSize = 0;
    job->mp4_optimize = 0;
    job->crop[0] = 0;
    job->crop[1] = 0;
    job->crop[2] = 0;
    job->crop[3] = 0;

    hb_audio_config_t * audio = NULL;
    audio = (hb_audio_config_t *) calloc(1, sizeof(*audio));
    hb_audio_config_init(audio);
    audio->in.track = 1;
    /* We go ahead and assign values to our audio->out.<properties> */
    audio->out.track = audio->in.track;
    audio->out.dynamic_range_compression = 0.7f;
    audio->out.codec = HB_ACODEC_FAAC;
    audio->out.mixdown = HB_AMIXDOWN_STEREO;
    audio->out.bitrate = 128;
    audio->out.samplerate = 44000;
    
    hb_audio_add( job, audio );
    free(audio);

//    for( int i = 0; i < audiotrack_count; i++ )
//    {
//      hb_audio_t * temp_audio = (hb_audio_t*) hb_list_item( job->list_audio, 0 );
//      hb_list_rem(job->list_audio, temp_audio);
//    }    
//    hb_list_add(job->list_audio, hb_list_item(handbrakeTitle->list_audio, 0));
////    job->acodec_copy_mask = 0;
////    job->acodec_copy_mask |= HB_ACODEC_FFAAC;
    
//    int subtitle_count = hb_list_count(job->list_subtitle);
//    for( int i = 0; i < subtitle_count; i++ )
//    {
//      hb_subtitle_t * temp_subtitle = (hb_subtitle_t*) hb_list_item( job->list_subtitle, 0 );
//      hb_list_rem(job->list_subtitle, temp_subtitle);
//    }
    
    // advanced H264 options
    NSString *options = @"ref=2:bframes=2:subq=6:mixed-refs=0:weightb=0:8x8dct=0:trellis=0";
    job->advanced_opts = (char *)calloc(1024, 0); /* Fixme, this just leaks */
//    strcpy(job->advanced_opts, [options cStringUsingEncoding: NSUTF8StringEncoding]);
    
    // output file name
    NSString *file = [NSString stringWithFormat: @"/Users/olarivain/%@-%i.m4v", titleList.name, title.index];
    job->file = [file cStringUsingEncoding: NSUTF8StringEncoding];
    
    job->filters = hb_list_init();
    job->indepth_scan = 0;

    hb_add(handbrakeEncodingHandle, job);
    jobIndex++;
  }
  
  hb_state_t encoderState;
  hb_get_state(handbrakeEncodingHandle, &encoderState);
  if(encoderState.state == HB_STATE_IDLE)
  {
    hb_start(handbrakeEncodingHandle);
  }
  
//  NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
//  while([runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.2]])
//  {
//    hb_state_t scannerState;
//    hb_get_state(handbrakeEncodingHandle, &scannerState);
//    NSLog(@"state %i with error %i", scannerState.state, scannerState.param.workdone);
//  }
  
}

#pragma mark Encoer Scanner timers
- (void) timerCheckEncodingScanner: (NSTimer *) timer
{
  hb_state_t scannerState;
  hb_get_state(handbrakeEncodingHandle, &scannerState);
//  NSLog(@"state %i with error %i", scannerState.state, scannerState.param.workdone);
  if(scannerState.state == HB_STATE_SCANDONE || scannerState.state == HB_STATE_IDLE)
  {
    encoderScanIsDone = YES;
    [timer invalidate];
  }
}

- (void) timerCheckEncoding: (NSTimer *) timer
{
  hb_state_t scannerState;
  hb_get_state(handbrakeEncodingHandle, &scannerState);
  NSLog(@"state: %i", scannerState.state);
}

@end
