#import "Notr_AppDelegate.h"
#import <BWToolkitFramework/BWToolkitFramework.h>

enum WindowSize {
	WSNormal,
	WSBig,
	WSLong
};

enum NotePosition {
	NPTop,
	NPBottom
};



@implementation Notr_AppDelegate

@synthesize statusItem, statusView, statusMenu, mainWindow, preferencesWindow, mainView, editView, currentView, notesTableView,
searchField, titleTextField, contentTextView, notesArrayController, pProgressSpinner, bIsSyncInProcess, bIsRemovingNotesDictionaryItems;
@synthesize query, bIsEditMode;

typedef void * CGSConnection;
extern OSStatus CGSNewConnection(const void **attributes, CGSConnection * id);

// Values for different types of item positions
int temporaryViewPosition		 = -1;
int startViewPosition			 = -2;
int endViewPosition				 = -3;
#define temporaryViewPositionNum [NSNumber numberWithInt:temporaryViewPosition]
#define startViewPositionNum     [NSNumber numberWithInt:startViewPosition]
#define endViewPositionNum       [NSNumber numberWithInt:endViewPosition]

// Scrawl drop type
NSString *NotrDropType = @"NotrDropType";

#pragma mark -
#pragma mark Initialization and deallocation methods

- (id)init {

	if (self = [super init]) {

		NSMutableDictionary *initialValues = [[NSMutableDictionary alloc] init];
        
        pDeleteNotesDictionary = [[NSMutableDictionary alloc] init];

		[initialValues setObject:[NSNumber numberWithBool:NO]
						  forKey:@"startOnLogin"];
		[initialValues setObject:[NSNumber numberWithBool:YES]
						  forKey:@"editOnCreate"];
		[initialValues setObject:[NSNumber numberWithBool:YES]
						  forKey:@"showBlur"];
		[initialValues setObject:[NSNumber numberWithInteger:WSNormal]
						  forKey:@"windowSize"];
		[initialValues setObject:[NSNumber numberWithInteger:NPTop]
						  forKey:@"newNotePosition"];

		[[NSUserDefaultsController sharedUserDefaultsController]
		 setInitialValues:initialValues];

		[initialValues release];
        
        bIsSyncInProcess = FALSE;
        bIsEditMode = FALSE;
	}

	return self;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
	
	PFMoveToApplicationsFolderIfNecessary();
    
    //[self ClearICloud];
    
    if (![self IsICloudAvailable])
    {
        NSLog(@"No iCloud access");
        
    }

    // Sync data on every minute = 5 seconds
   [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(startBackgroundJobOfSyncData) userInfo:nil repeats:YES];
       
}


- (void)applicationDidFinishLaunching:(NSNotification *)notification {

	// Hide the application upon startup
	[[NSApplication sharedApplication] hide:self];
}

- (void)awakeFromNib {

	float	width		= 30.0;
	float	height		= [[NSStatusBar systemStatusBar] thickness];
	NSRect	viewFrame	= NSMakeRect(0, 0, width, height);
    bIsRemovingNotesDictionaryItems = FALSE;

	[mainWindow setDelegate:self];

	// Setup the Notr login item
	[self setupLoginItem:self];

	// Create a status item
	statusView = [[StatusView alloc] initWithFrame:viewFrame controller:self];
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:width] retain];
	[statusItem setView:statusView];

	// Set the status menu's delegate
	statusMenuDelegate = [[StatusMenuDelegate alloc] initWithController:self];
	[statusMenu setDelegate:statusMenuDelegate];

	// Setup a global hotkey
	notrKeyCombo = [[PTKeyCombo alloc] initWithKeyCode:45 modifiers:controlKey+
					optionKey+cmdKey];
	notrHotKey = [[PTHotKey alloc] initWithIdentifier:@"NotrHotKey" keyCombo:notrKeyCombo];
	[notrHotKey setTarget:self];
	[notrHotKey setAction:@selector(toggleMainWindow:)];
	[[PTHotKeyCenter sharedCenter] registerHotKey:notrHotKey];

	// Set up the notes table view (delegate, dragging and dropping, etc.)
	NSArray *dragTypes = [[NSArray alloc] initWithObjects:NotrDropType, nil];
	[notesTableView setTarget:self];
	[notesTableView setDataSource:self];
	[notesTableView setDelegate:self];
	[notesTableView setDoubleAction:@selector(showEditor:)];
	[notesTableView registerForDraggedTypes:dragTypes];
	[notesTableView setDraggingSourceOperationMask:(NSDragOperationMove | NSDragOperationCopy) forLocal:YES];
	[dragTypes release];

	// Add observers for when the notes are modified
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noteWasModified:) name:NSTextDidChangeNotification
											   object:contentTextView];
}

- (void)dealloc {

	[[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
	[statusView release];
    [mainWindow release];
	[currentView release];
    [managedObjectContext release];
    [persistentStoreCoordinator release];
    [managedObjectModel release];
    
    [pProgressSpinner release];

    [super dealloc];
}


/**
 Implementation of the applicationShouldTerminate: method, used here to
 handle the saving of changes in the application managed object context
 before the application terminates.
 */

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {

    if (!managedObjectContext) return NSTerminateNow;

    if (![managedObjectContext commitEditing]) {
        NSLog(@"%@:%s unable to commit editing to terminate", [self class], _cmd);
        return NSTerminateCancel;
    }
	
    if (![managedObjectContext hasChanges]) return NSTerminateNow;
	
    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
		
        // This error handling simply presents error information in a panel with an 
        // "Ok" button, which does not include any attempt at error recovery (meaning, 
        // attempting to fix the error.)  As a result, this implementation will 
        // present the information to the user and then follow up with a panel asking 
        // if the user wishes to "Quit Anyway", without saving the changes.
		
        // Typically, this process should be altered to include application-specific 
        // recovery steps.  
		
        BOOL result = [sender presentError:error];
        if (result) return NSTerminateCancel;
		
        NSString *question = NSLocalizedString(@"Could not save changes while quitting.  Quit anyway?",
											   @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save",
										   @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
		
        NSInteger answer = [alert runModal];
        [alert release];
        alert = nil;
        
        if (answer == NSAlertAlternateReturn) return NSTerminateCancel;
		
    }
	
    return NSTerminateNow;
}


- (void)applicationDidResignActive:(NSNotification *)aNotification {

	[statusView setClicked:NO];
	[statusView setNeedsDisplay:YES];
	[self closeMainWindow:self];
}

#pragma mark -
#pragma mark Methods for Sync iCloud Data

- (BOOL) IsICloudAvailable
{
    BOOL bRes = FALSE;
    NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:@"8W27B5T8XC.com.allendunahoo.Scrawl"];
    if (ubiq) 
        bRes = TRUE;
    
    return bRes;
}


- (void) ClearICloud
{

    NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:@"8W27B5T8XC.com.allendunahoo.Scrawl"];
    if (ubiq) 
    {
        NSUbiquitousKeyValueStore *cloudStore = [NSUbiquitousKeyValueStore defaultStore];
        NSMutableArray *pCloudArrary = [[NSMutableArray alloc] init];
        [cloudStore setArray:pCloudArrary forKey:@"notesarray"];
        [cloudStore synchronize];
        [pCloudArrary release];
    }
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    NSLog(@"clicked %d button\n", returnCode);
    
    [alert release];
}

- (void)startBackgroundJobOfSyncData 
{
    if (!bIsSyncInProcess && !bIsEditMode)
    {
        //NSLog(@"Load document");
        NSMetadataQuery *metaquery = [[NSMetadataQuery alloc] init];
        query = metaquery;
        [query setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope]];
        
        NSPredicate *pred = [NSPredicate predicateWithFormat: @"%K.pathExtension = 'txt'", NSMetadataItemFSNameKey];
        [query setPredicate:pred];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryDidFinishGathering:) name:NSMetadataQueryDidFinishGatheringNotification object:query];
        
        [query startQuery];
    }
}

- (void)queryDidFinishGathering:(NSNotification *)notification 
{
    
    //NSLog(@"Finish query");
    
    NSMetadataQuery *metaquery = [notification object];
    [metaquery disableUpdates];
    [metaquery stopQuery];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:NSMetadataQueryDidFinishGatheringNotification
                                                  object:metaquery];
    
    query = nil;
    [self UpLoadNotesDataOnICloud:metaquery];
}

-(BOOL) IsItemNeedToRemoveFromDictonary : (NSDate*)pModifiedDate
{
    BOOL bRes = FALSE;
    
	NSDate *currentDate = [NSDate date];
    
	NSTimeInterval seconds = [currentDate timeIntervalSinceDate:pModifiedDate];
	NSInteger nDaysPassed = seconds / (24*60*60);
	if (nDaysPassed > 10)
		bRes = TRUE;
	
    return bRes;
}

- (void) UpLoadNotesDataOnICloud:(NSMetadataQuery *)pSearchQuery
{
    //NSLog(@"IN THE FUNCTION");
    
    BOOL bShouldSyncWithCloud = false;
    bIsSyncInProcess = TRUE;
    
    // First get the values from icloud and update notes
    [self saveAction:self];
    
    BOOL bIsICloudDictionaryFound = FALSE;
    NSMutableDictionary *pDataDictionary = nil;
    if (pSearchQuery && [pSearchQuery resultCount]>0)
    {
        //NSLog(@"Dictionary Found");
        NSMetadataItem *item = [pSearchQuery resultAtIndex:0];
        NSURL *url = [item valueForAttribute:NSMetadataItemURLKey];
        NotesDocument *notedoc = [[NotesDocument alloc] initWithContentsOfURL:url ofType:@"txt" error:nil]; 
        if (notedoc)
        {
            //NSLog(@"Note document initialize");
            
            NSData* data=[[notedoc noteContent] dataUsingEncoding:NSUTF8StringEncoding];
            CFPropertyListRef plist = CFPropertyListCreateFromXMLData(kCFAllocatorDefault, (CFDataRef)data, kCFPropertyListImmutable, NULL);
            
            // we check if it is the correct type and only return it if it is
            if ([(id)plist isKindOfClass:[NSDictionary class]])
            {
                //NSLog(@"Plist created and udpdated dictionary");
                
                NSDictionary *pDataDic = [(NSDictionary *)plist autorelease];
                pDataDictionary = [[NSMutableDictionary alloc] initWithDictionary:pDataDic];

            }
            else
            {
                //NSLog(@"Dictionary is nil");
                pDataDictionary = nil;
            }
            
            bIsICloudDictionaryFound = TRUE;
        }
    }
    else
    {
        //NSLog(@"Dictionary Not Found, Init new");
        pDataDictionary = [[NSMutableDictionary alloc] init];
    }
    
    // Delete items from dictionary if there are some to delete
    if (pDeleteNotesDictionary && [pDeleteNotesDictionary count]>0)
    {
        bIsRemovingNotesDictionaryItems = TRUE;
        
        NSArray *pAllKeys = [pDeleteNotesDictionary allKeys];
        for (int n=0; n < [pAllKeys count]; n++)
        {
            NSString *csKey = [pAllKeys objectAtIndex:n];
            if (csKey)
            {
                NSDictionary *pItemDic = [pDataDictionary objectForKey:csKey];
                if (pItemDic)
                {
                    // Find the key in cloud dictionary, if available delete it from there
                    [pItemDic setValue:@"TRUE" forKey:@"deletenote"];
                    bShouldSyncWithCloud = true;
                }
            }
        }
        
        [pDeleteNotesDictionary removeAllObjects];
        
        bIsRemovingNotesDictionaryItems = FALSE;
    }
    
    // Upload notes data on icloud (start)
    if (pDataDictionary)
    {
        //NSLog(@"Upload start");
        
        // Loop on all notes ans then sync with icloud
        NSArray *pLocalArary = [notesArrayController arrangedObjects];
        for (int n=0; n < [pLocalArary count]; n++)
        {
            Notes *noteItem = [pLocalArary objectAtIndex:n];
            NSDate *nsNoteCreateDate = [noteItem createDate];
            NSString *csLocalCreatedDate =  [nsNoteCreateDate description];
            
            BOOL bNoteFound = TRUE;
            NSMutableDictionary *pCloudNoteDic = [pDataDictionary objectForKey:csLocalCreatedDate];
            if (!pCloudNoteDic)
            {
                bNoteFound = FALSE;
            }
            
            NSMutableDictionary *pDic = [[NSMutableDictionary alloc] init];
            
            [pDic setValue:[noteItem title] forKey:@"title"];
            [pDic setValue:[noteItem content] forKey:@"content"];
            [pDic setValue:[noteItem createDate] forKey:@"createDate"];
            [pDic setValue:[noteItem modifyDate] forKey:@"modifyDate"];
            [pDic setValue:@"FALSE" forKey:@"deletenote"];
            
            if (bNoteFound)
            {
                
                NSString *csCloudCreatedDate =  [[pCloudNoteDic valueForKey:@"createDate"] description];
                NSString *csCloudModifiedDate =  [[pCloudNoteDic valueForKey:@"modifyDate"] description];
                NSString *csLocalModifiedDate =  [[noteItem modifyDate] description];
                
                if ([csCloudCreatedDate compare:csLocalCreatedDate] == NSOrderedSame)
                {
                    // This means we need to modify/replace the object only if Modified dates are different
                    if ([csCloudModifiedDate compare:csLocalModifiedDate] == NSOrderedAscending)
                    {    
                        // Replace object
                        //NSLog(@"Item Replaced");
                        [pDataDictionary setValue:pDic forKey:csLocalCreatedDate];
                        bShouldSyncWithCloud = true;
                    }
                }
            }
            else
            {
                
                //insert object
                [pDataDictionary setValue:pDic forKey:csLocalCreatedDate];
                bShouldSyncWithCloud = true;
                //NSLog(@"New Item Inserted");
                //NSLog(@"Title:%@  CreateDate:%@  ModifyDate:%@ ToDelete:%@", [noteItem title], [noteItem createDate], [noteItem modifyDate], @"FALSE");
            }
            
            [pDic release];
            pDic = nil;
            
        } // Upload notes data on icloud (end)
        
        
        NSMutableArray *pKeysToRemoveArray = [[NSMutableArray alloc] init];

        // Download notes data from icloud (start)
        if (bIsICloudDictionaryFound)
        {
            //NSLog(@"Downlaod start");
            
            if (pDataDictionary && [pDataDictionary count]>0)
            {
                NSArray *pAllKeys = [pDataDictionary allKeys];
                // Loop on all array items
                for (int nArrayIndex=0; nArrayIndex < [pAllKeys count]; nArrayIndex++)
                {
                    NSString *csKey = [pAllKeys objectAtIndex:nArrayIndex];
                    NSDictionary *pItemDic = [pDataDictionary objectForKey:csKey];
                    
                    if (pItemDic)
                    {
                        NSString *csTitle = [pItemDic objectForKey:@"title"];
                        NSString *csContent = [pItemDic objectForKey:@"content"];
                        NSDate *nsCreateDate = [pItemDic objectForKey:@"createDate"];
                        NSDate *nsModifyDate = [pItemDic objectForKey:@"modifyDate"];
                        
                        //NSLog(@"Title:%@  CreateDate:%@  ModifyDate:%@ ToDelete:%@", csTitle, [nsCreateDate description], [nsModifyDate description], [pItemDic objectForKey:@"deletenote"]);
                        
                        BOOL bIsItemForDelete = [[pItemDic objectForKey:@"deletenote"] boolValue];
                        if (bIsItemForDelete)
                        {
                            // Delete from the array controller if it is available
                            int nNoteIndex = [self GetNoteIndexFromCreateDate:nsCreateDate];
                            if (nNoteIndex >= 0)
                            {
                                //NSLog(@"Item found in local array to delete");
                                NSArray *pNotesArary = [notesArrayController arrangedObjects];
                                NSManagedObject *currentObject = [pNotesArary objectAtIndex:nNoteIndex];
                                if (currentObject)
                                {
                                    [[self managedObjectContext] deleteObject:currentObject];
                                    
                                    [self renumberViewPositions];
                                }
                                
                            }
                            else
                            {
                               // NSLog(@"Item not found in local array to delete");
                            }
                            
                            
                            // Delete any delete entry which is 10 days old (start)
                            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                            NSString *csModifyDateString = [pItemDic objectForKey:@"modifyDate"];
                            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZZ"];
                            
                            NSDate *pModifyDate = [dateFormatter dateFromString:csModifyDateString];
                            BOOL bDeleteItem = [self IsItemNeedToRemoveFromDictonary:pModifyDate];
                            if (bDeleteItem)
                            {
                                [pKeysToRemoveArray addObject:csKey];
                            }
                            
                            [dateFormatter release];
                            dateFormatter = nil;

                        }
                        else
                        {
                            int nNotesIndex = [self GetNoteIndexFromCreateDate:nsCreateDate];
                            if (nNotesIndex >= 0)
                            {
                                //NSLog(@"Item found in local array");
                                NSArray *pNotesArary = [notesArrayController arrangedObjects];
                                if (pNotesArary && [pNotesArary count] > 0)
                                {
                                    Notes *noteItem = [pNotesArary objectAtIndex:nNotesIndex];
                                    if (noteItem)
                                    {
                                        NSString *nsNoteModifyDate = [[noteItem modifyDate] description];
                                        // Compare who has the recent date
                                        if ([nsNoteModifyDate compare:[nsModifyDate description]] == NSOrderedAscending)
                                        {
                                            //NSLog(@"Update item");
                                            
                                            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                                            NSString *csCreateDateString = [pItemDic objectForKey:@"createDate"];
                                            NSString *csModifyDateString = [pItemDic objectForKey:@"modifyDate"];
                                            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZZ"];
                                            NSDate *pCreateDate = [dateFormatter dateFromString:csCreateDateString];
                                            NSDate *pModifyDate = [dateFormatter dateFromString:csModifyDateString];
                                            
                                            [noteItem setTitle:csTitle];
                                            [noteItem setContent:csContent];
                                            [noteItem setCreateDate:pCreateDate];
                                            [noteItem setModifyDate:pModifyDate];
                                            
                                            [dateFormatter release];
                                            dateFormatter = nil;
                                        }                                        
                                    }
                                    
                                }
                            }
                            else
                            {
                                //NSLog(@"Insert New item in local array");
                                // Enter new note to array
                                NSManagedObject *newItem = [NSEntityDescription
                                                            insertNewObjectForEntityForName:@"Notes"
                                                            inManagedObjectContext:[self
                                                                                    managedObjectContext]];
                                
                                // Add new item's data
                                
                                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                                NSString *csCreateDateString = [pItemDic objectForKey:@"createDate"];
                                NSString *csModifyDateString = [pItemDic objectForKey:@"modifyDate"];
                                [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZZ"];
                                NSDate *pCreateDate = [dateFormatter dateFromString:csCreateDateString];
                                NSDate *pModifyDate = [dateFormatter dateFromString:csModifyDateString];
                                
                                [newItem setValue:csContent forKey:@"content"];
                                [newItem setValue:pCreateDate forKey:@"createDate"];
                                [newItem setValue:pModifyDate forKey:@"modifyDate"];
                                [newItem setValue:[NSNumber numberWithInt:endViewPosition] forKey:@"viewPosition"];
                                
                                [self renumberViewPositions];
                                
                                [dateFormatter release];
                                dateFormatter = nil;
                                
                            }
                        }
                    }
                }
                
            }
            else
            {
                //NSLog(@"Array not found");
            }
            
            
            
        } // Download notes data from icloud (end)
        
        if (pKeysToRemoveArray && [pKeysToRemoveArray count]>0)
        {
            bShouldSyncWithCloud = true;
            [pDataDictionary removeObjectsForKeys:pKeysToRemoveArray];
        }
        
        [pKeysToRemoveArray release];
        pKeysToRemoveArray = nil;
        
        if (bShouldSyncWithCloud)
        {
            // Write dictionary to nsstring and upload to icloud
            
            NSString *csNotesItemsDictionary = [pDataDictionary description];
            //NSLog(@"%@", csNotesItemsDictionary);
            
            NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:@"8W27B5T8XC.com.allendunahoo.Scrawl"];
            NSURL *ubiquitousPackage = [[ubiq URLByAppendingPathComponent:@"Documents"] URLByAppendingPathComponent:kFILENAME];
            
            NSError *pError;
            
            NotesDocument *pDocObj = [[NotesDocument alloc] init];
            [pDocObj setNoteContent:csNotesItemsDictionary];
            if (pDocObj) 
            {
                [pDocObj saveToURL:ubiquitousPackage ofType:@"txt" forSaveOperation:NSSaveOperation error:&pError];
                //NSLog(@"Svaing file");
            }
            
        }
        
    }
    
    bIsSyncInProcess = FALSE;
    
}



// Return -1 if note note found
// Return index of note that has same create date
- (int) GetNoteIndexFromCreateDate : (NSDate*)nsCreateDate
{
    int nIndex = -1;
    
    NSArray *pNotesArary = [notesArrayController arrangedObjects];
    for (int n=0; n < [pNotesArary count]; n++)
    {
        Notes *noteItem = [pNotesArary objectAtIndex:n];
        if (noteItem)
        {
            NSString *nsNoteCreateDate = [[noteItem createDate] description];
            
            if ([nsNoteCreateDate compare:[nsCreateDate description]] == NSOrderedSame)
            {
                // Item found with same create date
                nIndex = n;            
                break;
            }
        
        }
        
    }
    
    return nIndex;
}

- (void) StartProgress
{
    [pProgressSpinner startAnimation:nil];
}

- (void) StopProgress
{
    [pProgressSpinner stopAnimation:nil];
}


#pragma mark -
#pragma mark Methods for managing Core Data

/**
    Returns the support directory for the application, used to store the Core Data
    store file.  This code uses a directory named "Notr" for
    the content, either in the NSApplicationSupportDirectory location or (if the
    former cannot be found), the system's temporary directory.
 */


- (NSString *)applicationSupportDirectory {

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"Scrawl"];
}


/**
    Creates, retains, and returns the managed object model for the application 
    by merging all of the models found in the application bundle.
 */
 
- (NSManagedObjectModel *)managedObjectModel {

    if (managedObjectModel) return managedObjectModel;
	
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}


/**
    Returns the persistent store coordinator for the application.  This 
    implementation will create and return a coordinator, having added the 
    store for the application to it.  (The directory for the store is created, 
    if necessary.)
 */

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator 
{

    if (persistentStoreCoordinator) 
        return persistentStoreCoordinator;

    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) 
    {
        NSAssert(NO, @"Managed object model is nil");
        NSLog(@"%@:%s No model to generate a store from", [self class], _cmd);
        return nil;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportDirectory = [self applicationSupportDirectory];
    NSError *error = nil;
    
    if ( ![fileManager fileExistsAtPath:applicationSupportDirectory isDirectory:NULL] ) 
    {
		if (![fileManager createDirectoryAtPath:applicationSupportDirectory withIntermediateDirectories:NO attributes:nil
										  error:&error]) 
        {
			NSString *failureString = [[NSString alloc] initWithFormat:@"Failed to create App Support directory %@ : %@",
									   applicationSupportDirectory, error];
			NSAssert(NO, (failureString));
            NSLog(@"Error creating application support directory at %@ : %@",applicationSupportDirectory,error);
			[failureString release];
            return nil;
		}
    }

#ifndef DEBUG
    NSURL *url = [[NSURL alloc] initFileURLWithPath:[applicationSupportDirectory stringByAppendingPathComponent:@"storedata"]];
#else
	NSURL *url = [[NSURL alloc] initFileURLWithPath:[applicationSupportDirectory stringByAppendingPathComponent:@"storedata-dbg"]];
#endif

    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: mom];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error])
	{
        [[NSApplication sharedApplication] presentError:error];
        [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
        return nil;
    }    

	[url release];

    return persistentStoreCoordinator;
}

/**
    Returns the managed object context for the application (which is already
    bound to the persistent store coordinator for the application.) 
 */
 
- (NSManagedObjectContext *) managedObjectContext {

    if (managedObjectContext) return managedObjectContext;

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: coordinator];

    return managedObjectContext;
}

/**
    Returns the NSUndoManager for the application.  In this case, the manager
    returned is that of the managed object context for the application.
 */
 
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}


#pragma mark -
#pragma mark Interface Builder actions

/**
    Performs the save action for the application, which is to send the save:
    message to the application's managed object context.  Any encountered errors
    are presented to the user.
 */
 
- (IBAction) saveAction:(id)sender {

    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%s unable to commit editing before saving", [self class], _cmd);
    }

    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (IBAction)showMainWindow:(id)sender {

	if (mainWindow) 
    {
		[self closeMainWindow:self];
	}

	[self removeEmptyNotes];
    bIsEditMode = FALSE;
	[self showMainWindowWithView:mainView];

    
    if([sender isMemberOfClass:[BWTransparentButton class]])
    {
        NSLog(@"Done button");
        //[self performSelectorInBackground:@selector(UpLoadDataOnICloud) withObject:nil];
    }
    
}

- (IBAction)closeMainWindow:(id)sender {
	
	if (mainWindow) 
    {
		[statusView setClicked:NO];
		[statusView setNeedsDisplay:YES];
		//[self closeWindowWithSlide:mainWindow];
		[mainWindow endEditingFor:nil];
		[mainWindow orderOut:self];
		[mainWindow release];
		mainWindow = nil;

		// Check to see if there is a note with "IMPORTANT" in the title
		// [self checkForImportantNote];

	}
    
    
}

- (IBAction)closeMainWindowAndHide:(id)sender {

	if (mainWindow) {

		[self closeMainWindow:self];

		// Check to see if there are any windows open. If not, hide.
		for (NSWindow *window in [[NSApplication sharedApplication] windows]) {

			if ([window isVisible] == YES) {
				return;
			}

			[[NSApplication sharedApplication] hide:self];
		}
	}
}

- (IBAction)showEditor:(id)sender {

	if ([[notesArrayController selectedObjects] count] > 0) {

		if (mainWindow) {
			[self closeMainWindow:self];
		}

        bIsEditMode = TRUE;
		[self showMainWindowWithView:editView];

		// If the content is "New Note", select it. Otherwise, move the insertion point to the start.
		if ([[[notesArrayController selectedObjects] objectAtIndex:0] content] == @"New Note") {

			[contentTextView selectAll:self];

		} 
        else 
        {

			[contentTextView setSelectedRange:NSMakeRange(0, 0)];
		}
	}
}

- (IBAction)showPreferences:(id)sender {

	[self closeMainWindow:sender];
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
	[preferencesWindow center];
	[preferencesWindow makeKeyAndOrderFront:sender];
}

- (IBAction)showAbout:(id)sender {

	[self closeMainWindow:sender];
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
	[[NSApplication sharedApplication] orderFrontStandardAboutPanel:self];
}

- (IBAction)undo:(id)sender {

	[[[mainWindow firstResponder] undoManager] undo];
	[notesTableView reloadData];
}

- (IBAction)redo:(id)sender {

	[[[mainWindow firstResponder] undoManager] redo];
	[notesTableView reloadData];
}

- (IBAction)addNewItem:(id)sender {

	[self addNewItemWithContent:@"New Note" select:YES];

	if ([[[[NSUserDefaultsController sharedUserDefaultsController]
		   values] valueForKey:@"editOnCreate"] boolValue] == YES) {

		[self showEditor:self];
	}
}

- (IBAction)removeSelectedItems:(id)sender 
{

	[self saveAction:self];

	NSArray *selectedItems = [notesArrayController selectedObjects];
	int indexOfFirstSelectedObject = [notesArrayController selectionIndex];

    BOOL bIsCloudAvailable = [self IsICloudAvailable];
	int count;
	for (count = 0; count < [selectedItems count]; count++) 
    {
        // Wait till the remove items are cleared from delete dictionary
        while (bIsRemovingNotesDictionaryItems) { }
        
		NSManagedObject *currentObject = [selectedItems objectAtIndex:count];
        NSDate *nsNoteCreateDate = [currentObject valueForKey:@"createDate"];
        NSString *csContent = [currentObject valueForKey:@"content"];

        // Maintain the dictionary for delete
        if (bIsCloudAvailable)
        {
            [pDeleteNotesDictionary setValue:csContent forKey:[nsNoteCreateDate description]];
        }
        
		[[self managedObjectContext] deleteObject:currentObject];
	}

	[self renumberViewPositions];

	if (indexOfFirstSelectedObject > [[notesArrayController arrangedObjects] count] - 1)
		indexOfFirstSelectedObject--;
    
	[notesArrayController setSelectionIndex:indexOfFirstSelectedObject];
    
    //[self performSelectorInBackground:@selector(SyncData) withObject:nil];
    [self startBackgroundJobOfSyncData];
}

- (IBAction)duplicateSelectedItem:(id)sender {

	[self saveAction:self];

	NSManagedObject *newItem = [NSEntityDescription
								insertNewObjectForEntityForName:@"Notes"
								inManagedObjectContext:[self
														managedObjectContext]];

	// Get the old item's data
	Notes *oldItem = [[notesArrayController selectedObjects] objectAtIndex:0];
	NSString *content		= [oldItem content];
	NSDate *createDate		= [oldItem createDate];
	NSDate *modifyDate		= [oldItem modifyDate];
	NSNumber *viewPosition	= [oldItem viewPosition];

	[newItem setValue:content forKey:@"content"];
	[newItem setValue:createDate forKey:@"createDate"];
	[newItem setValue:modifyDate forKey:@"modifyDate"];
	[newItem setValue:viewPosition forKey:@"viewPosition"];	

	[self renumberViewPositions];
}

- (IBAction)renameItem:(id)sender {

	if ([[notesArrayController selectedObjects] count] > 0) 
    {
		[notesTableView editColumn:0 row:[notesTableView selectedRow] withEvent:nil select:NO];
	}
}

// Add or remove the Notr login item depending on the current settings
- (IBAction)setupLoginItem:(id)sender {

	NSURL *bundleURL = [[NSURL alloc] initFileURLWithPath:[[NSBundle mainBundle]
													  bundlePath]];

	if ([[[[NSUserDefaultsController sharedUserDefaultsController]
		   values] valueForKey:@"startOnLogin"] boolValue] == YES) {

		if ([MPLoginItems loginItemExists:bundleURL] == NO) {
			[MPLoginItems addLoginItemWithURL:bundleURL];
		}
	} else if ([[[[NSUserDefaultsController sharedUserDefaultsController]
				  values] valueForKey:@"startOnLogin"] boolValue] == NO) {

		if ([MPLoginItems loginItemExists:bundleURL] == YES) {
			[MPLoginItems removeLoginItemWithURL:bundleURL];
		}
	}

	[bundleURL release];
}


#pragma mark -
#pragma mark Window showing, hiding and controlling

- (void)showMainWindowWithView:(NSView *)theView {

	if (mainWindow) {
		[self closeMainWindow:self];
	}

	// Set the current view
	currentView = theView;

	// Get the size settings of the window and adjust accordingly
	if ([[[[NSUserDefaultsController sharedUserDefaultsController]
		   values] valueForKey:@"windowSize"] intValue] == WSNormal) {
		
		[mainView setFrame:NSMakeRect(0, 0, 250, 164)];
		[editView setFrame:NSMakeRect(0, 0, 250, 164)];
		
	} else if ([[[[NSUserDefaultsController sharedUserDefaultsController]
			   values] valueForKey:@"windowSize"] intValue] == WSBig) {
		
		[mainView setFrame:NSMakeRect(0, 0, 320, 240)];
		[editView setFrame:NSMakeRect(0, 0, 320, 240)];
		
	} else if ([[[[NSUserDefaultsController sharedUserDefaultsController]
				  values] valueForKey:@"windowSize"] intValue] == WSLong) {

		[mainView setFrame:NSMakeRect(0, 0, 250, 320)];
		[editView setFrame:NSMakeRect(0, 0, 250, 320)];
	}

	[statusView setClicked:YES];
	[statusView setNeedsDisplay:YES];

	[NSApp activateIgnoringOtherApps:YES];
	NSRect frame = [[statusView window] frame];
	NSPoint pt = NSMakePoint(NSMidX(frame), NSMinY(frame));
	mainWindow = [[MAAttachedWindow alloc] initWithView:theView
										attachedToPoint:pt
											   inWindow:nil
												 onSide:MAPositionAutomatic
											 atDistance:5.0];
	[mainWindow setDelegate:self];
	[mainWindow setArrowBaseWidth:24.0];
	[mainWindow setArrowHeight:12.0];
    
	[mainWindow makeKeyAndOrderFront:self];


	if ([[[[NSUserDefaultsController sharedUserDefaultsController]
		   values] valueForKey:@"showBlur"] boolValue] == YES)
	{
		[self enableBlurForWindow:mainWindow];
	}

	// Reload the list of notes
	[notesTableView reloadData];
}

// Toggle the main window
- (void)toggleMainWindow:(id)sender {

	if (!mainWindow) {
		[self showMainWindow:self];
	} else {
		[statusView setClicked:NO];
		[statusView setNeedsDisplay:YES];
		[self closeMainWindowAndHide:self];
	}
}

-(void)enableBlurForWindow:(NSWindow *)window {

	CGSConnection thisConnection;
	NSUInteger compositingFilter;

	/*
	 Compositing Types
	 
	 Under the window   = 1 <<  0
	 Over the window    = 1 <<  1
	 On the window      = 1 <<  2
	 */

	NSInteger compositingType = 1 << 0; // Under the window

	/* Make a new connection to CoreGraphics */
	CGSNewConnection(NULL, &thisConnection);

	/* Create a CoreImage filter and set it up */
	CGSNewCIFilterByName(thisConnection, (CFStringRef)@"CIGaussianBlur",
						 &compositingFilter);
	NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber
									numberWithFloat:3.0] forKey:@"inputRadius"];
	CGSSetCIFilterValuesFromDictionary(thisConnection, compositingFilter,
									   (CFDictionaryRef)options);

	/* Now apply the filter to the window */
	CGSAddWindowFilter(thisConnection, [window windowNumber], compositingFilter,
					   compositingType);
}


#pragma mark -
#pragma mark Various methods for dealing with notes

// Add a new note with a title and content
- (void)addNewItemWithContent:(NSString *)content select:(BOOL)select {

	[self saveAction:self];

	BOOL addToBottom = YES;
	if ([[[[NSUserDefaultsController sharedUserDefaultsController]
		   values] valueForKey:@"newNotePosition"] intValue] == NPTop) {

		addToBottom = NO;
	} else {
		addToBottom = YES;
	}

	NSManagedObject *newItem = [NSEntityDescription
								insertNewObjectForEntityForName:@"Notes"
								inManagedObjectContext:[self
														managedObjectContext]];

	[newItem setValue:content forKey:@"content"];
	if (!addToBottom) {
		[newItem setValue:[NSNumber numberWithInt:startViewPosition]
				   forKey:@"viewPosition"];
	} else {
		[newItem setValue:[NSNumber numberWithInt:endViewPosition]
				   forKey:@"viewPosition"];
	}

	[newItem setValue:[NSDate date] forKey:@"createDate"];
	[newItem setValue:[NSDate date] forKey:@"modifyDate"];

	[self renumberViewPositions];

	if (select == YES) {

		if (!addToBottom) {
			[notesArrayController setSelectionIndex:0];
		} else {
			[notesArrayController setSelectionIndex:[[notesArrayController
													arrangedObjects] count]-1];
		}

		[notesTableView scrollRowToVisible:[notesTableView selectedRow]];
	}

}

- (void)noteWasModified:(NSNotification *)aNotification {

	// Set the currently selected note's date to now
	[[[notesArrayController selectedObjects] objectAtIndex:0] setModifyDate:[NSDate date]];
    
    
}

- (void)removeEmptyNotes {

	for (NSManagedObject *note in [notesArrayController	arrangedObjects]) {

		if ([[note valueForKey:@"content"] isEmpty] || [note valueForKey:@"content"] == nil)
			[notesArrayController removeObject:note];
	}
}

#pragma mark -
#pragma mark Item dragging, dropping and arrangement

- (NSArray *)sortDescriptors {

	NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"viewPosition" ascending:YES];

	if (_sortDescriptors == nil)
		_sortDescriptors = [[NSArray alloc] initWithObjects:sort, nil];

	[sort release];

	return _sortDescriptors;
}

- (void)renumberViewPositions {

	NSArray *startItems = [self itemsWithViewPosition:startViewPosition];

	NSArray *existingItems = [self itemsWithNonTemporaryViewPosition];

	NSArray *endItems = [self itemsWithViewPosition:endViewPosition];

	int currentViewPosition = 0;

	if (startItems && ([startItems count] > 0))
		currentViewPosition = [self renumberViewPositionsOfItems:startItems startingAt:currentViewPosition];

	if (existingItems && ([existingItems count] > 0))
		currentViewPosition = [self renumberViewPositionsOfItems:existingItems startingAt:currentViewPosition];

	if (endItems && ([endItems count] > 0))
		[self renumberViewPositionsOfItems:endItems startingAt:currentViewPosition];
}

- (NSArray *)copyItems:(NSArray *)itemsToCopyArray {

	NSMutableArray *arrayOfCopiedItems = [[NSMutableArray alloc]
									initWithCapacity:[itemsToCopyArray count]];

	int count;
	for (count = 0; count < [itemsToCopyArray count]; count++) {
		NSManagedObject *itemToCopy = [itemsToCopyArray objectAtIndex:count];
		NSManagedObject *copiedItem = [NSEntityDescription
									   insertNewObjectForEntityForName:@"Notes"
									   inManagedObjectContext:[self
														managedObjectContext]];

		[copiedItem setValue:[itemToCopy valueForKey:@"title"] forKey:@"title"];
		[copiedItem setValue:[itemToCopy valueForKey:@"content"]
					  forKey:@"content"];
		[copiedItem setValue:temporaryViewPositionNum forKey:@"viewPosition"];

		[arrayOfCopiedItems addObject:copiedItem];
	}

	return arrayOfCopiedItems;
}


/******************************

 Table view delegate methods

 ******************************/

- (BOOL)tableView:(NSTableView *)tableView
shouldShowCellExpansionForTableColumn:(NSTableColumn *)tableColumn
			  row:(NSInteger)row {

	return NO;
}

- (BOOL)tableView:(NSTableView *)tv
writeRowsWithIndexes:(NSIndexSet *)rowIndexes
toPasteboard:(NSPasteboard*)pasteboard {

	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
	NSArray *dragTypes = [[NSArray alloc] initWithObjects:NotrDropType, nil];
	[pasteboard declareTypes:dragTypes owner:self];
	[pasteboard setData:data forType:NotrDropType];
	[dragTypes release];
	return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tableView
				validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(NSInteger)row
	   proposedDropOperation:(NSTableViewDropOperation)dropOperation {

	if ([info draggingSource] == notesTableView) {
		if (dropOperation == NSTableViewDropOn)
			[tableView setDropRow:row dropOperation:NSTableViewDropAbove];
		
		if (([[[NSApplication sharedApplication] currentEvent] modifierFlags] &
			 NSAlternateKeyMask))
			return NSDragOperationCopy;
		else
			return NSDragOperationMove;
	}
	
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView*)tableView acceptDrop:(id <NSDraggingInfo>)info
			  row:(NSInteger)row
	dropOperation:(NSTableViewDropOperation)dropOperation {

	NSPasteboard *pasteboard = [info draggingPasteboard];
	NSData *rowData = [pasteboard dataForType:NotrDropType];
	NSIndexSet *rowIndexes = [NSKeyedUnarchiver
							  unarchiveObjectWithData:rowData];

	NSArray *allItemsArray = [notesArrayController arrangedObjects];
	NSMutableArray *draggedItemsArray = [[NSMutableArray alloc] initWithCapacity:[rowIndexes count]];

	NSUInteger currentItemIndex;
	NSRange range = NSMakeRange(0, [rowIndexes lastIndex] + 1);
	while ([rowIndexes getIndexes:&currentItemIndex maxCount:1
					 inIndexRange:&range] > 0)
	{
		NSManagedObject *thisItem = [allItemsArray
									 objectAtIndex:currentItemIndex];
		
		[draggedItemsArray addObject:thisItem];
	}

	if ([info draggingSourceOperationMask] & NSDragOperationMove) {

		int count;
		for (count = 0; count < [draggedItemsArray count]; count++) {
			NSManagedObject *currentItemToMove = [draggedItemsArray
												  objectAtIndex:count];
			[currentItemToMove setValue:temporaryViewPositionNum
								 forKey:@"viewPosition"];
		}

		int tempRow;
		if (row == 0)
			tempRow = -1;
		else
			tempRow = row;

		NSArray *startItemsArray = [self itemsWithViewPositionBetween:0 and:tempRow];
		NSArray *endItemsArray = [self itemsWithViewPositionGreaterThanOrEqualTo:row];

		int currentViewPosition;
		currentViewPosition = [self renumberViewPositionsOfItems:startItemsArray startingAt:0];
		currentViewPosition = [self renumberViewPositionsOfItems:draggedItemsArray startingAt:currentViewPosition];
		[self renumberViewPositionsOfItems:endItemsArray startingAt:currentViewPosition];

		[self renumberViewPositions];

		return YES;

	} else if ([info draggingSourceOperationMask] & NSDragOperationCopy) {

		NSArray *copiedItemsArray = [self copyItems:draggedItemsArray];

		int tempRow;
		if (row == 0)
			tempRow = -1;
		else
			tempRow = row;

		NSArray *startItemsArray = [self itemsWithViewPositionBetween:0 and:tempRow];
		NSArray *endItemsArray = [self itemsWithViewPositionGreaterThanOrEqualTo:row];

		int currentViewPosition;
		
		currentViewPosition = [self renumberViewPositionsOfItems:startItemsArray startingAt:0];
		currentViewPosition = [self renumberViewPositionsOfItems:copiedItemsArray startingAt:currentViewPosition];
		[self renumberViewPositionsOfItems:endItemsArray startingAt:currentViewPosition];		

		[self renumberViewPositions];

		return YES;
	}

	[draggedItemsArray release];

	return NO;
}


/******************************

 Helper methods for the table view

 ******************************/

- (NSArray *)itemsUsingFetchPredicate:(NSPredicate *)fetchPredicate {

	NSError *error = nil;
	NSEntityDescription *entityDesc = [NSEntityDescription
									   entityForName:@"Notes"
									   inManagedObjectContext:[self
									   managedObjectContext]];

	NSArray *arrayOfItems;
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:entityDesc];
	[fetchRequest setPredicate:fetchPredicate];
	[fetchRequest setSortDescriptors:[self sortDescriptors]];
	arrayOfItems = [[self managedObjectContext] executeFetchRequest:fetchRequest
															  error:&error];
	[fetchRequest release];

	return arrayOfItems;
}

- (NSArray *)itemsWithViewPosition:(int)value {

	NSPredicate *fetchPredicate = [NSPredicate
								   predicateWithFormat:@"viewPosition == %i",
								   value];

	return [self itemsUsingFetchPredicate:fetchPredicate];
}

- (NSArray *)itemsWithNonTemporaryViewPosition {

	NSPredicate *fetchPredicate = [NSPredicate
								   predicateWithFormat:@"viewPosition >= 0"];

	return [self itemsUsingFetchPredicate:fetchPredicate];
}

- (NSArray *)itemsWithViewPositionGreaterThanOrEqualTo:(int)value {

	NSPredicate *fetchPredicate = [NSPredicate
								   predicateWithFormat:@"viewPosition >= %i",
								   value];

	return [self itemsUsingFetchPredicate:fetchPredicate];
}

- (NSArray *)itemsWithViewPositionBetween:(int)lowValue and:(int)highValue {

	NSPredicate *fetchPredicate = [NSPredicate
				predicateWithFormat:@"viewPosition >= %i && viewPosition <= %i",
								   lowValue, highValue];

	return [self itemsUsingFetchPredicate:fetchPredicate];
}

- (int)renumberViewPositionsOfItems:(NSArray *)array startingAt:(int)value {

	int currentViewPosition = value;
	int count = 0;

	if (array && ([array count] > 0)) {

		for (count = 0; count < [array count]; count++) {

			NSManagedObject *currentObject = [array objectAtIndex:count];
			[currentObject setValue:[NSNumber numberWithInt:currentViewPosition]
							 forKey:@"viewPosition"];
			currentViewPosition++;
		}
	}

	return currentViewPosition;
}

@end
