//
//  MMAudioTrack+MMAudioTrack_Handbrake.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/30/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import "MMAudioTrack+MMAudioTrack_Handbrake.h"

#import "hb.h"

@interface MMAudioTrack()
- (MMAudioTrack *) initWithHandbrakeIndex: (NSInteger) index codec: (NSInteger) codec channelLayout: (NSInteger) layout andLanguage: (NSString *) language;
@end

@implementation MMAudioTrack (MMAudioTrack_Handbrake)

+ (MMAudioTrack *) audiotTrackWithHandbrakeIndex: (NSInteger) index codec: (NSInteger) codec channelLayout: (NSInteger) layout andLanguage: (NSString *) language
{
  return [[MMAudioTrack alloc] initWithHandbrakeIndex: index codec: codec channelLayout: layout andLanguage: language];
}

- (MMAudioTrack *) initWithHandbrakeIndex: (NSInteger) anIndex codec: (NSInteger) aCodec channelLayout: (NSInteger) aLayout andLanguage: (NSString *) aLanguage
{
  self = [super init];
  if(self)
  {
    index = anIndex;
    hasLFE = [MMAudioTrack handbrakeCodecHasLFE: aLayout];
    language = aLanguage;
    codec = [MMAudioTrack iTunesServerCodecFromHandbrakeCodec: aCodec];
    channelCount = [MMAudioTrack channelCountFromHandbrakeChannelLayout: aLayout];
  }
  return self;
}

+ (BOOL) handbrakeCodecHasLFE: (NSInteger) aCodec
{
  return (aCodec & HB_INPUT_CH_LAYOUT_HAS_LFE) != 0;
}

+ (MMAudioCodec) iTunesServerCodecFromHandbrakeCodec: (NSInteger) codec
{
  if((codec & HB_ACODEC_AC3) != 0)
  {
    return AUDIO_CODEC_AC3;
  }
  
  if((codec & HB_ACODEC_DCA) != 0)
  {
    return AUDIO_CODEC_DTS;
  }
  
  if((codec & HB_ACODEC_FAAC) !=0
     || (codec & HB_ACODEC_CA_AAC) !=0)
  {
    return AUDIO_CODEC_AAC;
  }
  
  if((codec & HB_ACODEC_LAME) != 0)
  {
    return AUDIO_CODEC_MP3;
  }
  
  if((codec & HB_ACODEC_LPCM) != 0)
  {
    return AUDIO_CODEC_LINEAR_PCM;
  }
  
  if((codec & HB_ACODEC_VORBIS) != 0)
  {
    return AUDIO_CODEC_VORBIS;
  }
  
  return AUDIO_CODEC_UNKNOWN;
}

+ (NSInteger) channelCountFromHandbrakeChannelLayout: (NSInteger) layout
{
  return HB_INPUT_CH_LAYOUT_GET_DISCRETE_FRONT_COUNT(layout) + HB_INPUT_CH_LAYOUT_GET_DISCRETE_REAR_COUNT(layout);
}

@end
