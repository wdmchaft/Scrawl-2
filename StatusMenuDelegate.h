#import <Cocoa/Cocoa.h>
#import "Notr_AppDelegate.h"


@class Notr_AppDelegate;

@interface StatusMenuDelegate : NSObject {

	Notr_AppDelegate *controller;
}

- (id)initWithController:(Notr_AppDelegate *)cntrlr;

@end
