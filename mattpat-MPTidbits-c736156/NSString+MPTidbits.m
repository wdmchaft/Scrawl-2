#import "NSString+MPTidbits.h"
#import "MPFunctions.h"
#import <CommonCrypto/CommonDigest.h>


@implementation NSString(MPTidbits)

- (BOOL)isEmpty
{
	return [self isEmptyIgnoringWhitespace:YES];
}
- (BOOL)isEmptyIgnoringWhitespace:(BOOL)ignoreWhitespace
{
	NSString *toCheck = (ignoreWhitespace) ? [self stringByTrimmingWhitespace] : self;
	return [toCheck isEqualToString:@""];
}
- (NSString *)stringByTrimmingWhitespace
{
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (NSString *)MD5Hash
{
	const char *input = [self UTF8String];
	unsigned char result[CC_MD5_DIGEST_LENGTH];
	CC_MD5(input, strlen(input), result);
	return MPHexStringFromBytes(result, CC_MD5_DIGEST_LENGTH);
}
- (NSString *)SHA1Hash
{
	const char *input = [self UTF8String];
	unsigned char result[CC_SHA1_DIGEST_LENGTH];
	CC_SHA1(input, strlen(input), result);
	return MPHexStringFromBytes(result, CC_SHA1_DIGEST_LENGTH);
}

@end

@implementation NSMutableString(MPTidbits)

- (void)trimCharactersInSet:(NSCharacterSet *)aCharacterSet
{
	// trim front
	NSRange frontRange = NSMakeRange(0, 1);
	while ([aCharacterSet characterIsMember:[self characterAtIndex:0]])
		[self deleteCharactersInRange:frontRange];
	
	// trim back
	while ([aCharacterSet characterIsMember:[self characterAtIndex:([self length] - 1)]])
		[self deleteCharactersInRange:NSMakeRange(([self length] - 1), 1)];
}
- (void)trimWhitespace
{
	[self trimCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

@end

