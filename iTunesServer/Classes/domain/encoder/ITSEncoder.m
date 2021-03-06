//
//  ITSEncoder.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/25/11.
//  Copyright (c) 2011 kra. All rights reserved.
//
#import <MediaManagement/MMTitleList.h>
#import <MediaManagement/MMTitle.h>
#import <MediaManagement/MMSubtitleTrack.h>

#import "ITSEncoder.h"

#import "MMAudioTrack+MMAudioTrack_Handbrake.h"
#import "MMTitle+MMTitle_Handbrake.h"

#import "ITSConfigurationRepository.h"
#import "ITSConfiguration.h"
#import "ITSEncodingRepository.h"

#import "ITSSleepService.h"

#import "ITSErrors.h"

static ITSEncoder *sharedEncoder;

@interface ITSEncoder()
// shared file manager
@property (nonatomic, strong, readwrite) NSFileManager *fileManager;
// list of scheduled titles
@property (nonatomic, strong, readwrite) NSMutableArray *scheduledTitles;
// title list currently in progress
@property (nonatomic, strong, readwrite) MMTitleList *activeTitleList;
@property (nonatomic, strong, readwrite) MMTitle *activeTitle;
// timer used to poll the encoding queue
@property (nonatomic, strong, readwrite) NSTimer *encoderTimer;

// hb handles used for scanning and encoding content
@property (nonatomic, assign, readwrite) hb_handle_t *handbrakeScannerHandle;
@property (nonatomic, assign, readwrite) hb_handle_t *handbrakeEncodingHandle;

@property (nonatomic, assign, readwrite) BOOL scanInProgress;
@property (nonatomic, assign, readwrite) BOOL scanIsDone;

@property (nonatomic, assign, readwrite) BOOL encoderScanIsDone;
@property (nonatomic, assign, readwrite) BOOL encodeScheduleInProgress;
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
		self.handbrakeScannerHandle = hb_init(HB_DEBUG_NONE, 0);
		self.handbrakeEncodingHandle = hb_init(HB_DEBUG_NONE, 0);
		self.scheduledTitles = [NSMutableArray arrayWithCapacity: 40];
		
		self.fileManager = [NSFileManager defaultManager];
		
		// schedule this sucker on the main loop, since we want it to keep firing always, no matter
		// what. And we don't care if the main loop is stuck for 3 seconds, there's no UI to it.
		self.encoderTimer = [NSTimer timerWithTimeInterval: 2
													target:self
												  selector: @selector(timerEncodeNextTitleList:)
												  userInfo: nil
												   repeats: YES];
		[[NSRunLoop mainRunLoop] addTimer: self.encoderTimer forMode: NSDefaultRunLoopMode];
	}
	
	return self;
}

#pragma mark - Scanning content
#pragma mark Schedule a Scan
- (MMTitleList *) scanPath: (NSString *) path
{
	// abort early for nonsensical data
	if([path length] == 0 || ![self.fileManager fileExistsAtPath: path])
	{
		return nil;
	}
	
	ITSEncodingRepository *repository = [ITSEncodingRepository sharedInstance];
	MMTitleList *titleList = [repository titleListWithId: path];
	if([titleList.titles count] > 0)
	{
		return titleList;
	}
	
	// make sure only 1 thread can run a scan at a time
	NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
	// this synchronized block should take care of synchronization, unless there's an obvious flaw I'm missing
	@synchronized(self)
	{
		while(self.scanInProgress && [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.2]])
		{
		}
		
		self.scanInProgress = YES;
	}
	
	// go ahead an tell libhb to do the scan
	[self performScanAtPath: path withHandbrakeHandle: self.handbrakeScannerHandle];
#warning the construct is odd and shouldn't be needed, but I'm tired of fighting regressions so I'll keep it for now
	titleList = [self readTitleListFromLastScanWithPath: path withHandbrakeHandle: self.handbrakeScannerHandle];
	
	// flip the synchronization switch so other threads can resume
	self.scanInProgress = NO;
	
	return titleList;
}

#pragma mark libhb actual scan
- (void) performScanAtPath: (NSString *) path withHandbrakeHandle: (hb_handle_t *) handle
{
	BOOL isEncodeScan = handle == self.handbrakeEncodingHandle;
	if(isEncodeScan)
	{
		self.encoderScanIsDone = NO;
	}
	else
	{
		self.scanIsDone = NO;
	}
	
	// stop any in progress scan, we don't want it to mess with us.
	hb_scan_stop(handle);
	
	NSString *logScanType = isEncodeScan ? @"encoder" : @"listing";
	DDLogInfo(@"Performing scan at path %@ for %@", path, logScanType);
	
	uint64_t minDuration = 90000L * 1020L;
	// ask libhb to scan requested content. At least one preview is required, libhb won't scan otherwise.
	hb_scan(handle, [path UTF8String], 0, 10, 0, minDuration);
	
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
	while(!(isEncodeScan ? self.encoderScanIsDone : self.scanIsDone) && [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.2]])
	{
	}
	DDLogInfo(@"Scan finished at path %@ for %@", path, logScanType);
}

- (MMTitleList *) readTitleListFromLastScanWithPath: (NSString *) path withHandbrakeHandle: (hb_handle_t *) handle
{
	// now, grab the content
	hb_list_t *titles = hb_get_titles(self.handbrakeScannerHandle);
	if(titles == NULL)
	{
		return nil;
	}
	
	// go through all titles, grab
	int titlesCount = hb_list_count(titles);
	if(titlesCount == 0)
	{
		return nil;
	}
	
	ITSEncodingRepository *encodingRepository = [ITSEncodingRepository sharedInstance];
	MMTitleList *titleList = [encodingRepository titleListWithId: path];
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
	hb_get_state(self.handbrakeScannerHandle, &scannerState);
	if(scannerState.state != HB_STATE_SCANDONE)
	{
		return;
	}
	
	self.scanIsDone = YES;
	[timer invalidate];
}

#pragma mark - Schedule an encode
- (void) scheduleTitleList: (MMTitleList *) titleList
{
	NSString *path = titleList.titleListId;
	// abort early for nonsensical data
	if([path length] == 0 || ![self.fileManager fileExistsAtPath: path])
	{
		DDLogInfo(@"title list with path %@ not found, has it been deleted since it has been scheduled?", path);
		return;
	}
	
	// title list has been scheduled already, we don't have anything to do here, just get the hell out
	if([self.activeTitleList isEqual: titleList] || [self.scheduledTitles containsObject: titleList])
	{
		DDLogInfo(@"Title %@ is already scheduled, title list has been updated.", titleList.titleListId);
		return;
	}
	
	@synchronized(self)
	{
		[self.scheduledTitles addObject: titleList];
	}
	
	// encoding will be scheduled by the encoding timer, so there isn't anything to do here,
	// except return.
	// we can't call encodeNextTitleList because it will block until the dvd has been scanned,
	// let'l just let the timer take care of that.
}

#pragma mark actual schedule (libhb)
- (void) encodeNextTitleList
{
	@synchronized(self)
	{
		// encoder is busy or nothing to encode, just return
		if([self.scheduledTitles count] == 0 && self.activeTitleList == nil)
		{
			// we can now reenable sleep, since we're done with our schedule.
			ITSSleepService *sleepService = [ITSSleepService sharedInstance];
			[sleepService enableSleep: YES];
			return;
		}
		
		if(self.activeTitleList.isCompleted || self.activeTitleList == nil)
		{
			self.activeTitleList.active = NO;
			// pop from list to active title
			self.activeTitleList = [self.scheduledTitles objectAtIndex: 0];
			[self.scheduledTitles removeObjectAtIndex: 0];
			self.activeTitleList.active = YES;
		}
		
		// flag the encoder as "we're scheduling something, so don't mess with us here"
		self.encodeScheduleInProgress = YES;
	}
	
	// prevent host from going to sleep. You'll sleep when you reach brookly. Haha.
	ITSSleepService *sleepService = [ITSSleepService sharedInstance];
	[sleepService enableSleep: NO];
	
	DDLogInfo(@"Scheduling encode for %@ with title %ld", self.activeTitleList.titleListId, self.activeTitle.index);
	// perform the scan so the handle is populated with the content.
	// this will block until done
	[self performScanAtPath: self.activeTitleList.titleListId withHandbrakeHandle: self.handbrakeEncodingHandle];
	
	// and schedule for encoding
	[self performScheduleTitleListForEncode: self.activeTitleList];
	self.encodeScheduleInProgress = NO;
}

- (void) performScheduleTitleListForEncode: (MMTitleList *) titleList
{
	
	// grab the handbrake title list first, and make sure it actually exist.
	hb_list_t *titles = hb_get_titles(self.handbrakeEncodingHandle);
	if(titles == NULL)
	{
		return;
	}
	
	// schedule the next title
	self.activeTitle = [self.activeTitleList nextTitleToEncode];
	// grab the position of the title in the hb_list (different than title index,
	// which could be the DVD title on VIDEO_TS content)
	NSInteger titlePosition = [titleList indexOfTitle: self.activeTitle];
	
	// skip if position is beyond count, just in case the data somehow got corrupted.
	// We don't want a stupid out of bounds index, do we?
	int titlesCount = hb_list_count(titles);
	if(titlePosition > titlesCount)
	{
		return;
	}
	
	hb_title_t *handbrakeTitle = hb_list_item(titles, (int) titlePosition);
	
	// the job that will be submitted
	hb_job_t *job = handbrakeTitle->job;
	
	// enqueue the job as the last one
	job->sequence_id = hb_count(self.handbrakeEncodingHandle);
	job->title = handbrakeTitle;
	// output file name
	
	ITSConfigurationRepository *configurationRepository = [ITSConfigurationRepository sharedInstance];
	ITSConfiguration *configuration = [configurationRepository readConfiguration];
	
	// strip extension out of the title name, if there is any
	NSString *titleName = titleList.name;
	if(titleName.pathExtension.length > 0) {
		NSString *extension = [NSString stringWithFormat: @".%@", [titleList.name pathExtension]];
		titleName = [titleName stringByReplacingOccurrencesOfString: extension withString: @""];
	}
	
	// append title number if we have more than one title
	NSString *suffix = titleList.titles.count == 1 ? @"" : [NSString stringWithFormat: @"-%02li", self.activeTitle.index];
	// create the target file name now
	NSString *file = [NSString stringWithFormat: @"%@/%@%@.m4v", configuration.autoScanPath, titleName, suffix];
	
	DDLogInfo(@"Encoding %@ titile %ld to %@", titleList.titleListId, titlePosition, file);
	job->file = [file cStringUsingEncoding: NSUTF8StringEncoding];
	self.activeTitle.targetPath = file;
	
	// encode all chapters, client side doesn't do any of that fancy stuff
#if DEBUG_ENCODER == 1
	// Un debug mode, just encode a small chunk, 'cause I'm tired of waiting 45 minutes
	// for my tests to go through :)
	uint64_t debugStart = 300;
	uint64_t debugDuration = 30;
	DDLogInfo(@"Debugger is ON, encoding only %llu seconds starting at %llu", debugDuration, debugStart);
	job->pts_to_start = debugStart * 90000L;
	job->pts_to_stop = debugDuration * 90000L;
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
	[self setupVideoParametersFromTitle: self.activeTitle
					 withHandbrakeTitle: handbrakeTitle
						 toHandbrakeJob: job];
	
	// then add audio tracks to the job
	[self addAudioTracksFromTitle: self.activeTitle
			   withHandbrakeTitle: handbrakeTitle
				   toHandbrakeJob: job];
	
	// and last but not least, add subtitle tracks to the job
	[self addSubtitleTracksFromTitle: self.activeTitle
				  withHandbrakeTitle: handbrakeTitle
					  toHandbrakeJob: job];
	
	// and add to encoding queue
	hb_add(self.handbrakeEncodingHandle, job);
	
	// and start the encoding
	hb_start(self.handbrakeEncodingHandle);
	self.activeTitle.encoding = YES;
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
	
	// advanced H264 options, copied over from handbrake, corresponds to their high profile
	NSString *options = @"b-adapt=2:rc-lookahead=50";
	job->advanced_opts = (char *)calloc([options length] + 1, 1); /* Fixme, this just leaks */
	strcpy(job->advanced_opts, [options cStringUsingEncoding: NSUTF8StringEncoding]);
	
	// we don't want a constant framerate. Whatever the title says, dude.
	job->cfr = 0;
	// copy over video frame rate
	job->vrate = handbrakeTitle->rate;
	job->vrate_base = handbrakeTitle->rate_base;;
	
	// I figured this worked, hope it doesn't break other stuff
	job->anamorphic.mode = 0;
	
	// we definitely want to keep the aspect ratio
	job->keep_ratio = 1;
	hb_fix_aspect( job, HB_KEEP_WIDTH );
	
	// add decomb filters, the easiest and most likely relevant way of deinterlacing
	job->filters = hb_list_init();
	// and just go with the default decomb settings, I wouldn't know what to put in there anyway.
	hb_filter_decomb.settings = 0;
	hb_list_add(job->filters, &hb_filter_decomb);
	
	// also add detelecine, as handbrake guys it's harmless when not needed
	// and vital when needed
	hb_filter_detelecine.settings = 0;
	hb_list_add(job->filters, &hb_filter_detelecine);
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
	int outAudioIndex = 0;
	for(MMAudioTrack *selectedAudioTrack in selectedAudioTracks)
	{
		// same thing than with titles, grab the hb audio track index from MMAudioTrack
		NSInteger inAudioIndex = [title indexOfAudioTrack: selectedAudioTrack];
		// make sure input is safe
		if(inAudioIndex > audioTrackCount)
		{
			continue;
		}
		
		// let's create audio config now.
		// first, extract the relevant audio config from hb audio list so we can copy stuff over.
		hb_audio_config_t *audioTemplateConfig = hb_list_item(handbrakeTitle->list_audio, (int) inAudioIndex);
		
		
		// now is time to create the schedule audio config.
		// the first track is always AAC. if input source is not AC3/DTS, then mixdown to stereo AAC.
		// if it is, the first track must still be AAC, so iThingies will actually play them properly.
		// So, go on and add AAC audio track to job.
		// first, basic setup
		hb_audio_config_t *audio = (hb_audio_config_t *) calloc(1, sizeof(*audio));
		hb_audio_config_init(audio);
		
		// then copy shit over from template
		audio->in.track = (int) inAudioIndex;
		audio->out.track = (int) outAudioIndex;
		outAudioIndex++;
		
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
			audio->in.track = (int) inAudioIndex;
			audio->out.track = (int) outAudioIndex;
			outAudioIndex++;
			
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
	hb_get_state(self.handbrakeEncodingHandle, &scannerState);
	if(scannerState.state != HB_STATE_SCANDONE)
	{
		return;
	}
	
	self.encoderScanIsDone = YES;
	[timer invalidate];
}

- (void) timerEncodeNextTitleList: (NSTimer *) timer
{
	// don't do anything if a schedule is in progress
	if(self.encodeScheduleInProgress)
	{
		return;
	}
	
	hb_state_t scannerState;
	hb_get_state(self.handbrakeEncodingHandle, &scannerState);
	
	// encoder is working, update active title with the progress
	if(scannerState.state == HB_STATE_WORKING)
	{
		// convert progress to percentage
		self.activeTitle.progress = (NSInteger) (scannerState.param.working.progress * 100.0f);
		
		// and eta to seconds
		self.activeTitle.eta = scannerState.param.working.hours * 3600;
		self.activeTitle.eta += scannerState.param.working.minutes * 60;
		self.activeTitle.eta += scannerState.param.working.seconds;
	}
	
	// encoder is not idle, so just encode next title (if any)
	if(scannerState.state != HB_STATE_WORKDONE && scannerState.state != HB_STATE_IDLE)
	{
		return;
	}
	
	// mark current title as completed and not active anymore
	self.activeTitle.encoding = NO;
	self.activeTitle.completed = YES;
	self.activeTitle.eta = 0;
	self.activeTitle.progress = 100;
	self.activeTitle = nil;
	
	if(self.activeTitleList.isCompleted)
	{
		self.activeTitleList = nil;
	}
	
	[self encodeNextTitleList];
}

- (void) closeLibHB
{
	hb_global_close();
}

#pragma mark - Deleting resources
- (NSError *) deleteResource: (NSString *) resource
{
	ITSEncodingRepository *encodingRepository = [ITSEncodingRepository sharedInstance];
	MMTitleList *deletedList = [encodingRepository titleListWithId: resource];
	
	// first, make sure we don't delete something in progress
	if(self.activeTitleList != nil && self.activeTitleList == deletedList)
	{
		
		NSString *errorMessage = [NSString stringWithFormat: @"Cannot delete %@ because it's currently encoding", deletedList.name];
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject: errorMessage forKey: NSLocalizedDescriptionKey];
		return [NSError errorWithDomain: @"ITS"
								   code: COULD_NOT_DELETE_ACTIVE
							   userInfo: userInfo];
	}
	
	if([self.scheduledTitles containsObject: deletedList]) {
		NSString *errorMessage = [NSString stringWithFormat: @"Cannot delete %@ because it's scheduled for encoding", deletedList.name];
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject: errorMessage forKey: NSLocalizedDescriptionKey];
		return [NSError errorWithDomain: @"ITS"
								   code: COULD_NOT_DELETE_ACTIVE
							   userInfo: userInfo];
	}
	
	// now, delete the file
	NSError *error = nil;
	[self.fileManager removeItemAtPath: resource
							error: &error];
	
	return error;
}

@end
