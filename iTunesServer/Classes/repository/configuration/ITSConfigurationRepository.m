//
//  ITSConfigurationRepository.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/10/11.
//  Copyright (c) 2011 kra. All rights reserved.
//

#import "ITSConfigurationRepository.h"

#import "ITSConfiguration.h"
#import "ITSDefaults.h"

static ITSConfigurationRepository *sharedInstance;

@interface ITSConfigurationRepository()
@property (nonatomic, readwrite, retain) ITSConfiguration *configuration;
- (void) loadConfiguration;
@end

@implementation ITSConfigurationRepository

+ (ITSConfigurationRepository *) sharedInstance
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[ITSConfigurationRepository alloc] init];
	});
	
	return sharedInstance;
}

- (void) dealloc {
    self.configuration = nil;
    [super dealloc];
}

@synthesize configuration;

- (ITSConfiguration *) readConfiguration
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		self.configuration = [ITSConfiguration configuration];
		[self loadConfiguration];
	});
	
	return configuration;
}

- (void) loadConfiguration
{
	NSUserDefaults *defaults = [[[NSUserDefaults alloc] init] autorelease];
	[defaults addSuiteNamed:@"com.kra.iTunesServerShared"];
	
	NSDictionary *dict = [defaults persistentDomainForName: @"com.kra.iTunesServer"];
	
	configuration.port = [[dict objectForKey: ITUNES_SERVER_PORT_KEY] integerValue];
	configuration.autoScanEnabled = [[dict objectForKey: AUTO_IMPORT_KEY] integerValue];
	configuration.autoScanPath = [dict objectForKey: AUTO_IMPORT_PATH_KEY];
	configuration.startOnLogin = [[dict objectForKey: START_ON_LOGIN_KEY] integerValue];
	configuration.encodingResourcePath = [dict objectForKey: ENCODING_RESOURCE_PATH_KEY];
}

- (ITSConfiguration *) saveConfiguration
{
	[self readConfiguration];
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity: 4];
	[dictionary setObject: [NSNumber numberWithInt: configuration.port]
					forKey: ITUNES_SERVER_PORT_KEY];
	[dictionary setObject: [NSNumber numberWithInt: configuration.autoScanEnabled]
					forKey: AUTO_IMPORT_KEY];
	[dictionary setObject: [NSNumber numberWithInt: configuration.startOnLogin]
					forKey: START_ON_LOGIN_KEY];
	
	if(self.configuration.autoScanPath != nil) {
		[dictionary setObject:  configuration.autoScanPath
					   forKey: AUTO_IMPORT_PATH_KEY];
	}
	
	if(self.configuration.encodingResourcePath != nil) {
		[dictionary setObject: configuration.encodingResourcePath
					   forKey:ENCODING_RESOURCE_PATH_KEY];
	}
	
	NSUserDefaults *defaults = [[[NSUserDefaults alloc] init] autorelease];
	[defaults addSuiteNamed:@"com.kra.iTunesServerShared"];
	
	[defaults setPersistentDomain: dictionary forName: @"com.kra.iTunesServer"];
	return configuration;
}

- (ITSConfiguration *) forceReload
{
	if(configuration == nil)
	{
		return [self readConfiguration];
	}
	
	[self loadConfiguration];
	
	return configuration;
}

@end
