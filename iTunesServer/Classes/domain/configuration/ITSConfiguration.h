//
//  ITSConfiguration.h
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/11/11.
//  Copyright (c) 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ITSConfiguration : NSObject
{
  NSInteger port;
  
  BOOL autoScanEnabled;
  NSString *autoScanPath;
  
  BOOL startOnLogin;
  
  NSString *encodingResourcePath;
}

+ (ITSConfiguration *) configuration;

@property (nonatomic, readwrite, assign) NSInteger port;
@property (nonatomic, readwrite, assign) BOOL autoScanEnabled;
@property (nonatomic, readwrite, retain) NSString *autoScanPath;
@property (nonatomic, readwrite, assign) BOOL startOnLogin;
@property (nonatomic, readwrite, retain) NSString *encodingResourcePath;

@end
