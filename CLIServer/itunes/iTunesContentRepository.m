//
//  MovieRepository.m
//  CLIServer
//
//  Created by Kra on 3/12/11.
//  Copyright 2011 kra. All rights reserved.
//

#import "iTunesContentRepository.h"
#import "ScriptRepository.h"
#import "Content.h"

@interface iTunesContentRepository(private)
- (NSAppleEventDescriptor*) descriptor: (NSString*) scriptKey methodName: (NSString*) methodName andParameters: (NSArray*) params;
@end

@implementation iTunesContentRepository

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}
   
#pragma mark - Generic apple script execution methods
- (NSAppleEventDescriptor*) descriptor: (NSString*) scriptKey methodName: (NSString*) methodName andParameters: (NSArray*) parameters 
{
  // load the script from a resource
  NSAppleScript *appleScript = [[ScriptRepository sharedInstance] scriptForKey: scriptKey];
  if(!appleScript)
  {
    // script not found, don't have bother going further.
    return nil;
  }
  
  // Go through parameters and add them to the list of apple script parameters.
  int index = 1;
  NSAppleEventDescriptor *appleScriptParameters = [NSAppleEventDescriptor listDescriptor];
  for(NSObject *parameter in parameters){
    // params other than string are NOT supported yet.
    if(![parameter isKindOfClass:[NSString class]]){
      break;
    }
      
    NSString *stringParameter = (NSString*) parameter;
    NSAppleEventDescriptor *appleScriptParameter = [NSAppleEventDescriptor descriptorWithString:stringParameter];
    [appleScriptParameters insertDescriptor:appleScriptParameter atIndex:index];
    index++;
  }
  
  // create the AppleEvent target
  ProcessSerialNumber psn = { 0, kCurrentProcess };
  NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber
                                                                                  bytes:&psn
                                                                                 length:sizeof(ProcessSerialNumber)];
  // create an NSAppleEventDescriptor with the method name
  // note that the name must be lowercase (even if it is uppercase in AppleScript)
  NSAppleEventDescriptor *handler = [NSAppleEventDescriptor descriptorWithString:[methodName lowercaseString]];
  
  // last but not least, create the event for an AppleScript subroutine
  // set the method name and the list of parameters
  NSAppleEventDescriptor *event = [NSAppleEventDescriptor appleEventWithEventClass:'ascr'
                                                                           eventID:'psbr'
                                                                  targetDescriptor:target
                                                                          returnID:kAutoGenerateReturnID
                                                                     transactionID:kAnyTransactionID];
  [event setParamDescriptor:handler forKeyword:'snam'];
  [event setParamDescriptor:appleScriptParameters forKeyword:keyDirectObject];

  // at last, call the event in AppleScript
  NSDictionary *error = nil;
  NSAppleEventDescriptor *response = [appleScript executeAppleEvent:event error:&error];
  NSLog(@"error: %@", error);
  return response;
}

#pragma mark - Repository methods

- (NSArray*) arrayWithResponse: (NSAppleEventDescriptor*) descriptor andContentKind: (ContentKind) kind;
{
  NSMutableArray *array = [NSMutableArray arrayWithCapacity:[descriptor numberOfItems]];
  NSInteger numberOfItems = [descriptor numberOfItems];
  for(int i = 1; i < numberOfItems +1; i++)
  {
    NSAppleEventDescriptor *record = [descriptor descriptorAtIndex: i];
    Content *content = [Content content: kind];
    
    NSAppleEventDescriptor *nextRecord = [record descriptorForKeyword:'ID  '];
    content.contentId = [nextRecord int32Value];
    
    nextRecord = [record descriptorForKeyword:'pAlb'];
    content.album = [nextRecord stringValue];
    
    nextRecord = [record descriptorForKeyword:'pArt'];
    content.artist = [nextRecord stringValue];
    
    nextRecord = [record descriptorForKeyword:'pnam'];
    content.name = [nextRecord stringValue]; 
    
    nextRecord = [record descriptorForKeyword:'pDes'];
    content.description = [nextRecord stringValue];
    
    nextRecord = [record descriptorForKeyword:'pGen'];
    content.genre = [nextRecord stringValue];
    
    nextRecord = [record descriptorForKeyword:'pShw'];
    content.show = [nextRecord stringValue];
    
    nextRecord = [record descriptorForKeyword:'pTrN'];
    content.trackNumber = [nextRecord int32Value]; 
    
    nextRecord = [record descriptorForKeyword:'pEpN'];
    content.episodeNumber = [nextRecord int32Value];
    
    nextRecord = [record descriptorForKeyword:'pSeN'];
    content.season = [nextRecord int32Value];
    
    [array addObject:content];
  }

  return array;
}

- (NSArray*) allMovies
{
  NSAppleEventDescriptor *descriptor = [self descriptor:READ_SCRIPTS methodName:@"GetContent" andParameters: [NSArray arrayWithObject: @"Movies"]];
  return [self arrayWithResponse: descriptor andContentKind:MOVIE];
  
}

- (NSArray*) allMusic
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSAppleEventDescriptor *descriptor = [self descriptor:READ_SCRIPTS methodName:@"GetContent" andParameters: [NSArray arrayWithObject: @"Music"]];
  NSArray *response = [self arrayWithResponse: descriptor andContentKind:MUSIC];
  [pool drain];
  [pool release];
  
  return response;
}

- (NSArray*) allPodcasts
{
  NSAppleEventDescriptor *descriptor = [self descriptor:READ_SCRIPTS methodName:@"GetContent" andParameters: [NSArray arrayWithObject: @"Podcasts"]];
  return [self arrayWithResponse: descriptor andContentKind:PODCAST];
}

- (NSArray*) alliTunesU
{
  NSAppleEventDescriptor *descriptor = [self descriptor:READ_SCRIPTS methodName:@"GetContent" andParameters: [NSArray arrayWithObject: @"iTunes U"]];
  return [self arrayWithResponse: descriptor andContentKind:ITUNES_U];
}


@end
