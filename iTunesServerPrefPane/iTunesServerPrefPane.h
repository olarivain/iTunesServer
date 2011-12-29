//
//  iTunesServerPrefPane.h
//  iTunesServerPrefPane
//
//  Created by Larivain, Olivier on 12/10/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

@class ITSConfiguration;

@interface iTunesServerPrefPane : NSPreferencePane 
{
  IBOutlet __strong NSTextField *runningLabel;
  IBOutlet __strong NSTextField *automaticImportTextField;
  IBOutlet __strong NSButton *startStopButton;
  IBOutlet __strong NSProgressIndicator *progressIndicator;
  IBOutlet __strong NSButton *autoImportCheckBox;
  IBOutlet __strong NSButton *autoImportPathButton;
  IBOutlet __strong NSTextField *encodingResourceTextField;
  
  __strong ITSConfiguration *configuration;
  __strong NSWorkspace *workspace;
  
  BOOL isRunning;
}

- (IBAction) startStopServer:(id)sender;
- (IBAction) changeAutomaticImportFolder:(id)sender;
- (IBAction) toggleAutoImport:(id)sender;
- (IBAction) changeEncodingResourceFolder:(id)sender;

@end
