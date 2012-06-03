#import "StatusView.h"


@implementation StatusView

@synthesize clicked;

- (id)initWithFrame:(NSRect)frame controller:(Notr_AppDelegate *)cntrlr {

	if (self = [super initWithFrame:frame]) {

		controller = cntrlr;

		statusIcon		= [NSImage imageNamed:@"status.png"];
		statusIconAlt	= [NSImage imageNamed:@"status-alt.png"];

		// Register the allowed drag types
		NSArray *dragTypes = [NSArray arrayWithObjects:NSStringPboardType, nil];
		[self registerForDraggedTypes:dragTypes];
	}

	return self;
}

- (void)dealloc {

	controller = nil;
	[statusIcon release];
	[statusIconAlt release];
	[super dealloc];
}

- (void)drawRect:(NSRect)rect {

	NSPoint pt = NSMakePoint(7, 3);
	NSRect imageRect = NSMakeRect(0, 0, 16, 16);

	if (clicked) {

        [[controller statusItem] drawStatusBarBackgroundInRect:rect withHighlight:YES];
		[statusIconAlt drawAtPoint:pt fromRect:imageRect
					  operation:NSCompositeHighlight fraction:1.0];
	} else {

		[statusIcon drawAtPoint:pt fromRect:imageRect
					  operation:NSCompositeCopy fraction:1.0];
	}
}

- (void)mouseDown:(NSEvent *)theEvent {

	[controller toggleMainWindow:self];
}

- (void)rightMouseDown:(NSEvent *)theEvent {

	if (!clicked) {
		[controller closeMainWindow:self];
		clicked = YES;
		[[[controller statusItem] view] setNeedsDisplay:YES];
		[[controller statusItem] popUpStatusItemMenu:[controller statusMenu]];
	}
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {

	NSPasteboard	*pboard;
	NSDragOperation	sourceDragMask;

	pboard			= [sender draggingPasteboard];
	sourceDragMask	= [sender draggingSourceOperationMask];

	if ([[pboard types] containsObject:NSStringPboardType]) {
		if (sourceDragMask & NSDragOperationCopy) {

			return NSDragOperationCopy;
		}
	}

	return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {

	NSPasteboard	*pboard;
	NSDragOperation	sourceDragMask;

	pboard			= [sender draggingPasteboard];
	sourceDragMask	= [sender draggingSourceOperationMask];

	if ([[pboard types] containsObject:NSStringPboardType]) {

		[controller addNewItemWithContent:[pboard
										   stringForType:NSStringPboardType]
								   select:YES];
	}

	return YES;
}

@end
