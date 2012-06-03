#import <Foundation/Foundation.h>


@interface NSString(MPTidbits)

- (BOOL)isEmpty;
- (BOOL)isEmptyIgnoringWhitespace:(BOOL)ignoreWhitespace;
- (NSString *)stringByTrimmingWhitespace;

- (NSString *)MD5Hash;
- (NSString *)SHA1Hash;

@end

@interface NSMutableString(MPTidbits)

- (void)trimCharactersInSet:(NSCharacterSet *)aCharacterSet;
- (void)trimWhitespace;

@end
