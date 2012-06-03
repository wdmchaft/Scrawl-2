#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import "MAAttachedWindow.h"
#import "MPLoginItems.h"
#import "PTHotKeyCenter.h"
#import "PTHotKey.h"
#import "PFMoveApplication.h"
#import "StatusView.h"
#import "StatusMenuDelegate.h"
#import "MainView.h"
#import "Notes.h"
#import "NotesDocument.h"

#define kFILENAME @"ScrawlNotes.txt"

@class StatusView, StatusMenuDelegate, MainView;

@interface Notr_AppDelegate : NSObject {

	NSStatusItem								*statusItem;
	StatusView									*statusView;
	NSMenu										*statusMenu;
	StatusMenuDelegate							*statusMenuDelegate;
	MAAttachedWindow							*mainWindow;
	MAAttachedWindow							*findWindow;
	NSWindow									*preferencesWindow;

	MainView									*mainView;
	NSView										*editView;
	NSView										*findView;

	NSView										*currentView;

	NSTableView									*notesTableView;
	NSTextField									*searchField;
	NSTextField									*titleTextField;
	NSTextView									*contentTextView;

	NSArrayController							*notesArrayController;

	NSArray										*_sortDescriptors;

	NSPersistentStoreCoordinator				*persistentStoreCoordinator;
	NSManagedObjectModel						*managedObjectModel;
	NSManagedObjectContext						*managedObjectContext;

	PTKeyCombo									*notrKeyCombo;
	PTHotKey									*notrHotKey;
    
    NSProgressIndicator                         *pProgressSpinner;
    BOOL                                        bIsSyncInProcess;
    BOOL                                        bIsRemovingNotesDictionaryItems;
    NSMutableDictionary                         *pDeleteNotesDictionary;
    NSMetadataQuery                             *query;
    BOOL                                        bIsEditMode;
}

@property (readonly) NSStatusItem				*statusItem;
@property (readonly) StatusView					*statusView;
@property (readonly) IBOutlet NSMenu			*statusMenu;
@property (assign) IBOutlet MAAttachedWindow	*mainWindow;
@property (assign) IBOutlet NSWindow			*preferencesWindow;
@property (assign) IBOutlet MainView			*mainView;
@property (assign) IBOutlet NSView				*editView, *currentView;
@property (assign) IBOutlet NSTableView			*notesTableView;
@property (assign) IBOutlet NSTextField			*titleTextField, *searchField;
@property (assign) IBOutlet NSTextView			*contentTextView;
@property (assign) IBOutlet NSArrayController	*notesArrayController;

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) IBOutlet NSProgressIndicator *pProgressSpinner;
@property (nonatomic, assign) BOOL bIsSyncInProcess;
@property (nonatomic, assign) BOOL bIsRemovingNotesDictionaryItems;

@property (nonatomic, retain) NSMetadataQuery *query;
@property (nonatomic, assign) BOOL bIsEditMode;

- (IBAction)saveAction:sender;
- (IBAction)showMainWindow:(id)sender;
- (IBAction)closeMainWindow:(id)sender;
- (IBAction)closeMainWindowAndHide:(id)sender;
- (IBAction)showEditor:(id)sender;
- (IBAction)showPreferences:(id)sender;
- (IBAction)showAbout:(id)sender;
- (IBAction)undo:(id)sender;
- (IBAction)redo:(id)sender;
- (IBAction)addNewItem:(id)sender;
- (IBAction)removeSelectedItems:(id)sender;
- (IBAction)duplicateSelectedItem:(id)sender;
- (IBAction)renameItem:(id)sender;
- (IBAction)setupLoginItem:(id)sender;




- (void)showMainWindowWithView:(NSView *)theView;
- (void)toggleMainWindow:(id)sender;
- (void)enableBlurForWindow:(NSWindow *)window;

- (void)addNewItemWithContent:(NSString *)content select:(BOOL)select;
- (void)noteWasModified:(NSNotification *)aNotification;
- (void)removeEmptyNotes;

// Various methods for arranging the items
- (NSArray *)sortDescriptors;
- (void)renumberViewPositions;
- (NSArray *)copyItems:(NSArray *)itemsToCopyArray;

// Helper methods for the table view
- (NSArray *)itemsUsingFetchPredicate:(NSPredicate *)fetchPredicate;
- (NSArray *)itemsWithViewPosition:(int)value;
- (NSArray *)itemsWithNonTemporaryViewPosition;
- (NSArray *)itemsWithViewPositionGreaterThanOrEqualTo:(int)value;
- (NSArray *)itemsWithViewPositionBetween:(int)lowValue and:(int)highValue;
- (int)renumberViewPositionsOfItems:(NSArray *)array startingAt:(int)value;


- (void) ClearICloud;
- (BOOL) IsICloudAvailable;
- (void)startBackgroundJobOfSyncData;
- (void) StartProgress;
- (void) StopProgress;
- (int) GetNoteIndexFromCreateDate : (NSDate*)nsCreateDate;
- (void) UpLoadNotesDataOnICloud:(NSMetadataQuery *)pSearchQuery;
- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
-(BOOL) IsItemNeedToRemoveFromDictonary : (NSDate*)pModifiedDate;


@end
