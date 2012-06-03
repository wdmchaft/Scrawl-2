#import <Cocoa/Cocoa.h>

@interface PTKeyCombo : NSObject <NSCopying>
{
	NSInteger	mKeyCode;
	NSUInteger	mModifiers;
}

+ (id)clearKeyCombo;
+ (id)keyComboWithKeyCode: (NSInteger)keyCode modifiers: (NSUInteger)modifiers;
- (id)initWithKeyCode: (NSInteger)keyCode modifiers: (NSUInteger)modifiers;

- (id)initWithPlistRepresentation: (id)plist;
- (id)plistRepresentation;

- (BOOL)isEqual: (PTKeyCombo*)combo;

- (NSInteger)keyCode;
- (NSUInteger)modifiers;

- (BOOL)isClearCombo;
- (BOOL)isValidHotKeyCombo;

@end