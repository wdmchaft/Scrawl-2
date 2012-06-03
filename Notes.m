#import "Notes.h"

@implementation Notes 

@dynamic title;
@dynamic content;
@dynamic viewPosition;
@dynamic insertionPoint;
@dynamic createDate;
@dynamic modifyDate;

- (NSString *)title {

	[[self managedObjectContext] processPendingChanges];
	[[[self managedObjectContext] undoManager] disableUndoRegistration];

	[self willAccessValueForKey:@"content"];
	NSString *value = [self primitiveValueForKey:@"content"];
	[self didAccessValueForKey:@"content"];

	[[self managedObjectContext] processPendingChanges];
	[[[self managedObjectContext] undoManager] enableUndoRegistration];

	return [self titleFromString:value];
}

- (void)setContent:(NSString *)theContent {

	[[self managedObjectContext] processPendingChanges];
	[[[self managedObjectContext] undoManager] disableUndoRegistration];

	[self willChangeValueForKey:@"content"];
	[self setPrimitiveValue:theContent forKey:@"content"];
	[self didChangeValueForKey:@"content"];

	[[self managedObjectContext] processPendingChanges];
	[[[self managedObjectContext] undoManager] enableUndoRegistration];
}

- (NSString *)titleFromString:(NSString *)theString {
	
	return [[theString componentsSeparatedByString:@"\n"] objectAtIndex:0];
}

@end
