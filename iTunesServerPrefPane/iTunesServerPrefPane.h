//
//  iTunesServerPrefPane.h
//  iTunesServerPrefPane
//
//  Created by Larivain, Olivier on 12/10/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

@interface iTunesServerPrefPane : NSPreferencePane 
{
  IBOutlet __strong NSTextField *runningLabel;
  IBOutlet __strong NSTextField *automaticImportTextField;
  IBOutlet __strong NSButton *startStopButton;
  IBOutlet __strong NSProgressIndicator *progressIndicator;
  
  __strong NSUserDefaults *defaults;
  __strong NSWorkspace *workspace;
  
  BOOL isRunning;
}

- (IBAction) startStopServer:(id)sender;
- (IBAction) changeAutomaticImportFolder:(id)sender;

@end
