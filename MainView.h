#import <Cocoa/Cocoa.h>
#import "Notr_AppDelegate.h"

@interface MainView : NSView {

	Notr_AppDelegate *controller;
}

@property (readwrite, assign) IBOutlet Notr_AppDelegate *controller;

@end
