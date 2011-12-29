//
//  ITSConfiguration.h
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/11/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ITSConfiguration : NSObject
{
  NSInteger port;
  
  BOOL autoScanEnabled;
  __strong NSString *autoScanPath;
  
  BOOL startOnLogin;
  
  __strong NSString *encodingResourcePath;
}

+ (ITSConfiguration *) configuration;

@property (nonatomic, readwrite, assign) NSInteger port;
@property (nonatomic, readwrite, assign) BOOL autoScanEnabled;
@property (nonatomic, readwrite, strong) NSString *autoScanPath;
@property (nonatomic, readwrite, assign) BOOL startOnLogin;
@property (nonatomic, readwrite, strong) NSString *encodingResourcePath;

@end
