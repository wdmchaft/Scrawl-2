#import "StatusMenuDelegate.h"


@implementation StatusMenuDelegate

- (id)initWithController:(Notr_AppDelegate *)cntrlr {

	if (self = [super init]) {

		controller = cntrlr;
	}

	return self;
}

- (void)menuDidClose:(NSMenu *)menu {

	[[controller statusView] setClicked:NO];
	[[[controller statusItem] view] setNeedsDisplay:YES];
}

@end
