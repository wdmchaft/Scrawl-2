#import "MainView.h"

@implementation MainView

@synthesize controller;

- (void)mouseDown:(NSEvent *)event {

	// If the mouse clicks the view, deselect all items (I have OCD, and that bothers me)
	[[controller notesArrayController] setSelectedObjects:nil];
}

- (void)keyDown:(NSEvent *)event {

	// Escape
	if ([event keyCode] == 53) {

		[controller closeMainWindowAndHide:self];
	}

	// Tab
	if ([event keyCode] == 48) {

		[[controller mainWindow] makeFirstResponder:[controller searchField]];
	}

	// Space
	if ([event keyCode] == 49 && [[[controller notesArrayController] selectedObjects] count] > 0) {

		[controller showEditor:self];
	}
}

@end
