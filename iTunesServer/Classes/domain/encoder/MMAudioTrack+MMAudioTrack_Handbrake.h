//
//  MMAudioTrack+MMAudioTrack_Handbrake.h
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/30/11.
//  Copyright (c) 2011 kra. All rights reserved.
//

#import <MediaManagement/MMAudioTrack.h>

@interface MMAudioTrack (MMAudioTrack_Handbrake)

+ (MMAudioTrack *) audiotTrackWithHandbrakeIndex: (NSInteger) index codec: (NSInteger) codec channelLayout: (NSInteger) layout andLanguage: (NSString *) language;
+ (MMAudioCodec) iTunesServerCodecFromHandbrakeCodec: (NSInteger) aCodec;
+ (NSInteger) channelCountFromHandbrakeChannelLayout: (NSInteger) layout;
+ (BOOL) handbrakeCodecHasLFE: (NSInteger) aCodec;
@end
