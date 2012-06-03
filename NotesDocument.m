//
//  NotesDocument.m
//  Scrawl
//
//  Created by Whizpool on 12/23/11.
//  Copyright (c) 2011 Paul Dunahoo. All rights reserved.
//

#import "NotesDocument.h"

@implementation NotesDocument

@synthesize noteContent;


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    /*
     Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    */
    
    //if (outError) 
    //{
    //    *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    //    return nil;
    //}
    
    NSData *pData = nil;
    if ([self.noteContent length] > 0) 
    {
        pData = [NSData dataWithBytes:[self.noteContent UTF8String] length:[self.noteContent length]];
    }
    
    return pData;
    
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    /*
    Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    */
    
    BOOL bRetValue = NO;
    if (outError) 
    {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
        NSLog(@"Its an error");
        return bRetValue;
    }
    
    if ([data length] > 0) 
    {
        bRetValue = YES;
        self.noteContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } 
    else 
    {
        // When the note is first created, assign some default content
        NSLog(@"Notes empty");
        self.noteContent = @"";
        bRetValue = NO; 
    }
    
    
    return bRetValue;
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

@end
