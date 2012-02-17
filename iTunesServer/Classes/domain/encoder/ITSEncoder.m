  //
//  ITSEncoder.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/25/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//
#import <MediaManagement/MMTitleList.h>
#import <MediaManagement/MMTitle.h>
#import <MediaManagement/MMSubtitleTrack.h>

#import "ITSEncoder.h"

#import "MMAudioTrack+MMAudioTrack_Handbrake.h"
#import "MMTitle+MMTitle_Handbrake.h"

#import "ITSConfigurationRepository.h"
#import "ITSConfiguration.h"

static ITSEncoder *sharedEncoder;

@interface ITSEncoder()
// scanning/extracting content from a scan
- (void) performScanAtPath: (NSString *) path withHandbrakeHandle: (hb_handle_t *) handle;
- (MMTitleList *) readTitleListFromLastScanWithPath: (NSString *) path withHandbrakeHandle: (hb_handle_t *) handle;
- (NSArray *) soundTracksFromHBTitle: (hb_title_t *) hbTitle;
- (NSArray *) subtitleTracksFromHBTitle: (hb_title_t *) hbTitle;

// scheduling encodes
- (void) performScheduleTitleListForEncode: (MMTitleList *) titleList;
- (void) setupVideoParametersFromTitle: (MMTitle *) title 
                    withHandbrakeTitle: (hb_title_t *) handbrakeTitle 
                        toHandbrakeJob: (hb_job_t *) job;
- (void) addAudioTracksFromTitle: (MMTitle *) title 
              withHandbrakeTitle: (hb_title_t *) handbrakeTitle 
                  toHandbrakeJob: (hb_job_t *) job;
- (void) addSubtitleTracksFromTitle: (MMTitle *) title 
                 withHandbrakeTitle: (hb_title_t *) handbrakeTitle 
                     toHandbrakeJob: (hb_job_t *) job
;
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
    // we want to use dvdnav library, dvdread crashes on 0 length titles
    hb_dvd_set_dvdnav(true);
    
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
  
  // ask libhb to scan requested content. At least one preview is required, libhb won't scan otherwise.
  hb_scan(handle, [path UTF8String], 0, 1, 0, 90000L * 10);
  
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
    
    NSInteger duration = (NSInteger) hbTitle->duration;
    MMTitle *mmTitle = [MMTitle titleWithIndex: index andHandbrakeDuration: duration];
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

#pragma mark actual schedule (libhb)
- (void) performScheduleTitleListForEncode: (MMTitleList *) titleList
{

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
  for(MMTitle *title in selectedTitles)
  {
    // grab the position of the title in the hb_list (different than title index, 
    // which could be the DVD title on VIDEO_TS content)
    NSInteger titlePosition = [titleList indexOfTitle: title];
    
    // skip if position is beyond count, just in case the data somehow got corrupted.
    // We don't want a stupid out of bounds index, do we?
    if(titlePosition > titlesCount)
    {
      continue;
    }

    hb_title_t *handbrakeTitle = hb_list_item(titles, (int) titlePosition);
    
    // the job that will be submitted
    hb_job_t *job = handbrakeTitle->job;
    
    // enqueue the job as the last one
    job->sequence_id = jobIndex;
    job->title = handbrakeTitle;
    // output file name
    
    ITSConfigurationRepository *configurationRepository = [ITSConfigurationRepository sharedInstance];
    ITSConfiguration *configuration = [configurationRepository readConfiguration];
    NSString *file = [NSString stringWithFormat: @"%@/%@-%i.m4v", configuration.autoScanPath, titleList.name, title.index];
    job->file = [file cStringUsingEncoding: NSUTF8StringEncoding];
    // encode all chapters, client side doesn't do any of that fancy stuff
#if DEBUG_ENCODER == 1
    // except in debug mode, just encode a minute, 'cause I'm tired of waiting 45 minutes
    // for my tests to go through :)
    job->pts_to_start = 300 * 90000;
    job->pts_to_stop = 420 * 90000;
#else
    job->chapter_start = 1;
    job->chapter_end = hb_list_count(handbrakeTitle->list_chapter);
#endif
    // and mark them in resulting file
    job->chapter_markers = 1;
    
    // we want to produce an mp4 file (of course)
    job->mux = HB_MUX_MP4;
    // for now, no large file is needed
    job->largeFileSize = 0;
    
    // fuck HTTP optimization, we don't need that in our use case
    job->mp4_optimize = 0;
    
    // setup video params
    [self setupVideoParametersFromTitle: title
                     withHandbrakeTitle: handbrakeTitle
                         toHandbrakeJob: job];

    // then add audio tracks to the job
    [self addAudioTracksFromTitle: title 
               withHandbrakeTitle: handbrakeTitle 
                   toHandbrakeJob: job];
    
    // and last but not least, add subtitle tracks to the job
    [self addSubtitleTracksFromTitle: title 
                  withHandbrakeTitle: handbrakeTitle 
                      toHandbrakeJob: job];

    // and add to encoding queue
    hb_add(handbrakeEncodingHandle, job);
    jobIndex++;
  }
  
  hb_state_t encoderState;
  hb_get_state(handbrakeEncodingHandle, &encoderState);
  if(encoderState.state == HB_STATE_IDLE)
  {
    hb_start(handbrakeEncodingHandle);
  }
}

- (void) setupVideoParametersFromTitle: (MMTitle *) title 
                    withHandbrakeTitle: (hb_title_t *) handbrakeTitle 
                        toHandbrakeJob: (hb_job_t *) job
{
  // set video codec to x264 (of course)
  job->vcodec = HB_VCODEC_X264;
  job->vquality = 20.5;
  job->vbitrate = -1;
  
  // single pass, since we're doing constant quality
  job->pass = 0;
  
  // advanced H264 options, copied over from handbrake.
  NSString *options = @"ref=2:bframes=2:subq=6:mixed-refs=0:weightb=0:8x8dct=0:trellis=0";
  job->advanced_opts = (char *)calloc([options length] + 1, 1); /* Fixme, this just leaks */
  strcpy(job->advanced_opts, [options cStringUsingEncoding: NSUTF8StringEncoding]);
  
  //    Just checking if job template is properly prefilled
  //    job->width = 720;
  //    job->height = 480;
  NSLog(@"duration: %llu", handbrakeTitle->duration /90000);
  NSLog(@"Width/Height: %i*%i", job->width, job->height);
  // we want a constant framerate
  job->cfr = 1;
  
  //    Just checking if the job template is properly filled
  NSLog(@"Anamorphic mode: %i", job->anamorphic.mode);
  //    job->anamorphic.mode = 0;
  
  // we definitely want to keep the aspect ratio
  job->keep_ratio = 1;
  
  //Just checking if crop settings defaults are OK
  NSLog(@"crop settings: %i %i %i %i", job->crop[0], job->crop[1], job->crop[2], job->crop[3]);
  //    job->crop[0] = 0;
  //    job->crop[1] = 0;
  //    job->crop[2] = 0;
  //    job->crop[3] = 0;
  
  // for now, skip filters
  job->filters = hb_list_init();
}

- (void) addAudioTracksFromTitle: (MMTitle *) title 
              withHandbrakeTitle: (hb_title_t *) handbrakeTitle 
                  toHandbrakeJob: (hb_job_t *) job
{
  // first, free up the job's audio list.
  int jobAudioTrackCount = hb_list_count(job->list_audio);
  for(int i = 0; i < jobAudioTrackCount; i++)
  {
    hb_audio_t *toRemove =hb_list_item(job->list_audio, 0);
    hb_list_rem(job->list_audio, toRemove);
  }
  
  int audioTrackCount = hb_list_count(handbrakeTitle->list_audio);
  // now, go through all selected audio tracks and add them
  NSArray *selectedAudioTracks = title.selectedAudioTracks;
  for(MMAudioTrack *selectedAudioTrack in selectedAudioTracks)
  {
    // same thing than with titles, grab the hb audio track index from MMAudioTrack
    NSInteger audioIndex = [title indexOfAudioTrack: selectedAudioTrack];
    // make sure input is safe
    if(audioIndex > audioTrackCount)
    {
      continue;
    }
    
    // let's create audio config now.
    // first, extract the relevant audio config from hb audio list so we can copy stuff over.
    hb_audio_config_t *audioTemplateConfig = hb_list_item(handbrakeTitle->list_audio, (int) audioIndex);
    
    
    // now is time to create the schedule audio config.
    // the first track is always AAC. if input source is not AC3/DTS, then mixdown to stereo AAC.
    // if it is, the first track must still be AAC, so iThingies will actually play them properly.
    // So, go on and add AAC audio track to job.
    // first, basic setup
    hb_audio_config_t *audio = (hb_audio_config_t *) calloc(1, sizeof(*audio));
    hb_audio_config_init(audio);
    
    // then copy shit over from template
    audio->in.track = audioTemplateConfig->in.track;
    audio->out.track = audio->in.track;
    
    // drop dynamic range just because the HB guys do it in their tool.
    audio->out.dynamic_range_compression = 0.7f;
    
    // AAC codec, CoreAudio flavor, with Pro Logic II mixdow
    audio->out.codec = HB_ACODEC_CA_AAC;
    audio->out.mixdown = HB_AMIXDOWN_DOLBYPLII;
    
    // keep sample rate, but drop bitrate to 192kbps
    audio->out.samplerate = 48000;
    audio->out.bitrate = hb_get_default_audio_bitrate(HB_ACODEC_CA_AAC, 
                                                      HB_AMIXDOWN_DOLBYPLII, 
                                                      audioTemplateConfig->in.samplerate);

    // and schedule that.
    hb_audio_add(job, audio);
    // don't forget the clean up, little panda!
    free(audio);
    audio = NULL;
    
    // track was AC3/DTS, so add the passthrough. Note: we want to do that only if it's actual surround
    // sound, it's pointless to pass it through if it's stereo, we will be better off with only AAC 
    // in that case.
    if(selectedAudioTrack.channelCount > 3 && 
       (selectedAudioTrack.codec == AUDIO_CODEC_AC3 || selectedAudioTrack.codec == AUDIO_CODEC_DTS))
    {
      // same same, init
      audio = (hb_audio_config_t *) calloc(1, sizeof(*audio));
      hb_audio_config_init(audio);
      // then copy shit over
      audio->in.track = audioTemplateConfig->in.track;
      audio->out.track = audio->in.track;
      audio->out.dynamic_range_compression = 0.7f;
      
      // pick right passthru codec
      BOOL isAC3 = selectedAudioTrack.codec == AUDIO_CODEC_AC3;
      audio->out.codec = isAC3 ? HB_ACODEC_AC3_PASS : HB_ACODEC_DCA_PASS;
      
      // passthru, dude!
      audio->out.mixdown = isAC3 ? HB_ACODEC_AC3 : HB_ACODEC_DCA;
      
      // this time, bitrate and samplerate are just copied over.
      audio->out.bitrate = audioTemplateConfig->in.bitrate;
      audio->out.samplerate = audioTemplateConfig->in.samplerate;
      
      // and schedule audio track
      hb_audio_add(job, audio);
      free(audio);
    }
  }
}

- (void) addSubtitleTracksFromTitle: (MMTitle *) title 
              withHandbrakeTitle: (hb_title_t *) handbrakeTitle 
                  toHandbrakeJob: (hb_job_t *) job
{
  // first, free up the job's subtitle list.
  int jobSubtitleTrackCount = hb_list_count(job->list_subtitle);
  for(int i = 0; i < jobSubtitleTrackCount; i++)
  {
    hb_subtitle_t *toRemove =hb_list_item(job->list_subtitle, 0);
    hb_list_rem(job->list_subtitle, toRemove);
  }
  
  int subtitleTrackCount = hb_list_count(handbrakeTitle->list_subtitle);
  // now, go through all selected subtitl tracks and add them
  NSArray *selectedSubtitleTracks = title.selectedSubtitleTracks;
  for(MMSubtitleTrack *selectedSubtitleTrack in selectedSubtitleTracks)
  {
    // same thing than with titles, grab the hb audio track index from MMSubtitleTRack
    NSInteger subtitleIndex = [title indexOfSubtitleTrack: selectedSubtitleTrack];
    // make sure input is safe
    if(subtitleIndex > subtitleTrackCount)
    {
      continue;
    }

    // grab subtitle track now
    hb_subtitle_t * subt = hb_list_item(handbrakeTitle->list_subtitle, (int) subtitleIndex);
    
    // passthru for CC, render it otherwise
    enum subdest destination = selectedSubtitleTrack.type == SUBTITLE_CLOSED_CAPTION ? PASSTHRUSUB : RENDERSUB;
    subt->config.dest = destination;
    
    // and schedule the bastard!
    hb_subtitle_add(job, &subt->config, (int) subtitleIndex);
  }
}

#pragma mark Encoer Scanner timers
- (void) timerCheckEncodingScanner: (NSTimer *) timer
{
  hb_state_t scannerState;
  hb_get_state(handbrakeEncodingHandle, &scannerState);
  if(scannerState.state == HB_STATE_SCANDONE || scannerState.state == HB_STATE_IDLE)
  {
    encoderScanIsDone = YES;
    [timer invalidate];
  }
}

@end
