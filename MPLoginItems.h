#import <Cocoa/Cocoa.h>


@interface MPLoginItems : NSObject {

}

// Methods
+ (NSArray *)loginItems;
+ (BOOL)loginItemExists:(NSURL *)theURL;
+ (void)addLoginItemWithURL:(NSURL *)theURL;
+ (void)removeLoginItemWithURL:(NSURL *)theURL;

@end
