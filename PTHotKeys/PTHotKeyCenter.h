#import <Cocoa/Cocoa.h>
@class PTHotKey;

@interface PTHotKeyCenter : NSObject
{
	NSMutableDictionary*	mHotKeys; //Keys are NSValue of EventHotKeyRef
	NSMutableDictionary*	mHotKeyIDs;
	BOOL					mEventHandlerInstalled;
}

+ (PTHotKeyCenter *)sharedCenter;

- (BOOL)registerHotKey: (PTHotKey*)hotKey;
- (void)unregisterHotKey: (PTHotKey*)hotKey;

- (NSArray*)allHotKeys;
- (PTHotKey*)hotKeyWithIdentifier: (id)ident;

- (void)sendEvent: (NSEvent*)event;

@end
