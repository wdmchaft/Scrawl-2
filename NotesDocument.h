//
//  NotesDocument.h
//  Scrawl
//
//  Created by Whizpool on 12/23/11.
//  Copyright (c) 2011 Paul Dunahoo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NotesDocument : NSDocument
{
    NSString *noteContent;
}

@property (nonatomic, retain) NSString *noteContent;


@end
