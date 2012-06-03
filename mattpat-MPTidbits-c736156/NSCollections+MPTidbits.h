#import <Foundation/Foundation.h>


@interface NSArray(MPTidbits)

- (BOOL)isEmpty;

@end

@interface NSDictionary(MPTidbits)

- (BOOL)isEmpty;
- (BOOL)containsKey:(NSString *)aKey;
- (BOOL)containsKey:(NSString *)aKey allowEmptyValue:(BOOL)allowEmpty;

@end

