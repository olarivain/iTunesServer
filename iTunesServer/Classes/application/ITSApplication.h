//
//  ITSApplication.h
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/11/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import <AppKit/AppKit.h>

@class ITSConfiguration;

@interface NSApplication (ITSApplication) 
@property (nonatomic, readwrite, strong) ITSConfiguration *configuration;

@end
