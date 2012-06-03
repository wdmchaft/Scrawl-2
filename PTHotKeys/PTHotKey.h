#import <Cocoa/Cocoa.h>
#import "PTKeyCombo.h"

@interface PTHotKey : NSObject
{
	NSString*		mIdentifier;
	NSString*		mName;
	PTKeyCombo*		mKeyCombo;
	id				mTarget;
	SEL				mAction;
	UInt32			mAssociatedID;
}

@property (nonatomic, retain) NSString* identifier;
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) PTKeyCombo* keyCombo;
@property (nonatomic, assign) id target;
@property (nonatomic, assign) SEL action;
@property (nonatomic, assign) UInt32 associatedID;

- (id)initWithIdentifier: (id)identifier keyCombo: (PTKeyCombo*)combo;
- (id)init;

- (void)invoke;

@end
