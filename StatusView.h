#import <Cocoa/Cocoa.h>
#import "Notr_AppDelegate.h"

@class Notr_AppDelegate;

@interface StatusView : NSView {

	Notr_AppDelegate *controller;
	BOOL clicked;

	NSImage *statusIcon;
	NSImage *statusIconAlt;
}

@property (readwrite) BOOL clicked;

- (id)initWithFrame:(NSRect)frame controller:(Notr_AppDelegate *)cntrlr;

@end
