#import <CoreData/CoreData.h>

@interface Notes : NSManagedObject {
}

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *content;
@property (nonatomic, retain) NSNumber *viewPosition;
@property (nonatomic, retain) NSNumber *insertionPoint;
@property (nonatomic, retain) NSDate *createDate;
@property (nonatomic, retain) NSDate *modifyDate;

// Create a title by getting the content up to a newline
- (NSString *)titleFromString:(NSString *)theString;

@end
