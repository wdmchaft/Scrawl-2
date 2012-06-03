//
//  iVersionMacAppDelegate.h
//  iVersionMac
//
//  Created by Nick Lockwood on 06/02/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "iVersion.h"


@interface iVersionMacAppDelegate : NSObject <NSApplicationDelegate, iVersionDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;
@property (assign) IBOutlet NSTextView *textView;

- (IBAction)checkForNewVersion:(id)sender;

@end
