/**
 * Paintbrush
 * Copyright (C) 2007-2019  Michael Schreiber
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


#import "DebugLog.h"

#import "SWDocument.h"
#import "SWPaintView.h"
#import "SWScalingScrollView.h"
#import "SWCenteringClipView.h"
#import "SWToolbox.h"
#import "SWToolboxController.h"
#import "SWTextToolWindowController.h"
#import "SWSizeWindowController.h"
#import "SWResizeWindowController.h"
#import "SWToolList.h"
#import "SWAppController.h"
#import "SWSavePanelAccessoryController.h"
#import "SWPrintPanelAccessoryController.h"
#import "SWImageDataSource.h"
#import "SWImageTools.h"

#include <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@implementation SWDocument

// Synthesize our properties here
@synthesize toolbox;
@synthesize paintView;

// TODO: Nasty hack
static BOOL kSWDocumentWillShowSheet = YES;

- (id)init
{
    if (self = [super init]) 
	{				
		// Observers for the toolbox
		nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self
			   selector:@selector(showTextSheet:)
				   name:@"SWText"
				 object:nil];
		[nc addObserver:self 
			   selector:@selector(undoLevelChanged:) 
				   name:kSWUndoKey 
				 object:nil];
		
		// Set levels of undos based on user defaults
		NSNumber *undo = [[NSUserDefaults standardUserDefaults] objectForKey:kSWUndoKey];
		[[self undoManager] setLevelsOfUndo:[undo integerValue]];
		
		// Create my window's particular tools
		toolbox = [[SWToolbox alloc] initWithDocument:self];
		
	}
    return self;
}


// Housekeeping
- (void)dealloc
{	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[savePanelAccessoryController removeObserver:self forKeyPath:kSWCurrentFileType];
}


- (NSString *)windowNibName
{
    return @"MyDocument";
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];

	// We can make the app more responsive by loading these guys at launch
	if (!sizeController)
		sizeController = [[SWSizeWindowController alloc] initWithWindowNibName:@"SizeWindow"];
	
	if (!resizeController)
		resizeController = [[SWResizeWindowController alloc] initWithWindowNibName:@"ResizePanel"];

	toolboxController = [SWToolboxController sharedToolboxPanelController];
	
	clipView = [[SWCenteringClipView alloc] initWithFrame:[[scrollView contentView] frame]];
	//[clipView setBackgroundColor:[NSColor windowBackgroundColor]];
	
	// The Scroll View contains the clip view, which is the superclass of the paint view (whew!)
	[scrollView setContentView:(NSClipView *)clipView];
	[clipView setDocumentView:paintView];
	[scrollView setScaleFactor:1.0 adjustPopup:YES];
	
	// Get and set the background image of the clip view
	NSImage *bgImage = [NSImage imageNamed:@"bgImage"];
	if (bgImage)
		[clipView setBgImagePattern:bgImage];
		
	// If the user opened an image
	if (dataSource) 
		[self setUpPaintView];
	else
	{
		// When we create a new document
		if (kSWDocumentWillShowSheet) 
		{
            [[aController window] center];
			[[aController window] orderFront:self];
			[self raiseSizeSheet:aController];
		}
		else 
		{
			[SWDocument setWillShowSheet:YES];
			dataSource = [[SWImageDataSource alloc] initWithPasteboard];
			[self setUpPaintView];
		}
	}
	
	[paintView setBackgroundColor:[NSColor clearColor]];
}


- (void)setUpPaintView
{
	[paintView preparePaintViewWithDataSource:dataSource
									  toolbox:toolbox];
	
	// Use external method to determine the window bounds
	NSRect viewRect = [paintView frame];
	NSRect tempRect = [paintView calculateWindowBounds:viewRect];
	
	// Apply the changes to the new document
	[[paintView window] setFrame:tempRect display:YES animate:YES];
}


- (NSString *)pathForImageBackgrounds
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
    
	NSString *folder = @"~/Library/Application Support/Paintbrush/Background Images/";
	folder = [folder stringByExpandingTildeInPath];
	
	if ([fileManager fileExistsAtPath: folder] == NO)
	{
        [fileManager createDirectoryAtPath:folder withIntermediateDirectories:NO attributes:@{} error:nil];
	}
    
	NSString *fileName = @"bgImage.png";
	return [folder stringByAppendingPathComponent:fileName];   
}

#pragma mark Sheets - Size and Text

////////////////////////////////////////////////////////////////////////////////
//////////		Sheets - Size and Text
////////////////////////////////////////////////////////////////////////////////


// Called when a new document is made
- (IBAction)raiseSizeSheet:(id)sender
{
    [[super windowForSheet] beginSheet:[sizeController window] completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
            case NSModalResponseOK: {
                NSSize openingSize;
                openingSize.width = [self->sizeController width];
                openingSize.height = [self->sizeController height];
                
                // You better be nil at this point!
                NSAssert(self->dataSource == nil, @"We can't already have a DataSource when creating a document!");

                // Create the data source
                self->dataSource = [[SWImageDataSource alloc] initWithSize:openingSize];

                // Initial creation
                [self setUpPaintView];
            } break;
            case NSModalResponseCancel:
                [[super windowForSheet] close];
                break;
        }
    }];
}


// Called when the user resizes the canvas/image
- (IBAction)raiseResizeSheet:(id)sender
{
	// Sender tag: 1 == image, 0 == canvas
	if ([[sender class] isEqualTo: [NSMenuItem class]])
		[resizeController setScales:[sender tag]];
	
	// Get, and then set, the current document size
	NSSize currSize = [dataSource size];
	[resizeController setCurrentSize:currSize];
	
    [[super windowForSheet] beginSheet:[resizeController window] completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
            case NSModalResponseOK: {
                NSSize newSize;
                newSize.width = [self->resizeController width];
                newSize.height = [self->resizeController height];
                
                // Nothing to do if the size isn't changing!
                if (self->dataSource.size.width != newSize.width || self->dataSource.size.height != newSize.height)
                {
                    // This is also important!
                    [self->toolbox tieUpLooseEndsForCurrentTool];

                    [self handleUndoWithImageData:nil frame:NSZeroRect];
                    
                    [self->dataSource resizeToSize:newSize scaleImage:[self->resizeController scales]];
                    [self->paintView setFrame:NSMakeRect(0.0, 0.0, newSize.width, newSize.height)]; // Forces a redraw
                    
                    // We should also redraw the clip view
                    [self->clipView setNeedsDisplay:YES];
                }
            } break;
            case NSModalResponseCancel:
                break;
        }
    }];
}


// Keep the current document's undo manager up to date
- (void)undoLevelChanged:(NSNotification *)n
{
	NSNumber *number = [n object];
	[[self undoManager] setLevelsOfUndo:[number integerValue]];
}


- (void)showTextSheet:(NSNotification *)n
{
	if ([[super windowForSheet] isKeyWindow]) {
		if (!textController)
			textController = [[SWTextToolWindowController alloc] initWithDocument:self];
		
        [[super windowForSheet] beginSheet:[textController window] completionHandler:^(NSModalResponse returnCode) {
            // [[[NSFontManager sharedFontManager] fontPanel:NO] orderOut:self];
        }];
		
		// [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
		
		// Assigns the current front color (according to the sharedColorPanel) 
		// to the frontColor reference
		[[NSColorPanel sharedColorPanel] setColor:[n object]];
		
	}
}

#pragma mark Menu actions (Open, Save, Cut, Print, et cetera)

////////////////////////////////////////////////////////////////////////////////
//////////		Menu actions (Open, Save, Cut, Print, et cetera)
////////////////////////////////////////////////////////////////////////////////


// Override to ensure that the user's file type is set
- (IBAction)saveDocument:(id)sender
{
	[toolbox tieUpLooseEndsForCurrentTool];
    [super saveDocument:sender];
}

-(void) saveToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation completionHandler:(void (^)(NSError *))completionHandler {
    NSLog(@"typeName = %@", typeName);
    [super saveToURL:url ofType:typeName forSaveOperation:saveOperation completionHandler:^(NSError *error) {
        if (error == nil && (saveOperation == NSSaveOperation || saveOperation == NSSaveAsOperation)) {
            NSURL *fileURL = [self fileURL];
            
            NSError *readError = nil;
            if (![self readFromURL:fileURL ofType:typeName error:&readError]) {
                NSLog(@"readFromURL = %@", readError);
                error = readError;
            } else {
                [self->paintView setNeedsDisplay:YES];
            }
        }
        
        if (completionHandler) {
            completionHandler(error);
        }
    }];
}


// Saving data: returns the correctly-formatted image data
- (NSData *)dataOfType:(NSString *)aType error:(NSError **)anError
{
    NSBitmapImageRep *bitmap = [dataSource mainImage];
//    NSBitmapImageRep *bitmap = [SWImageTools createMonochromeImage:[paintView mainImage]];

    [SWImageTools flipImageVertical:bitmap];
        
    NSData *data = nil;
    NSBitmapImageFileType fileType = NSBitmapImageFileTypePNG;
    
    NSLog(@"fileType = %@", aType);
    if ([aType isEqualToString:@"bmp"])
        fileType = NSBitmapImageFileTypeBMP;
    else if ([aType isEqualToString:@"png"])
        fileType = NSBitmapImageFileTypePNG;
    else if ([aType isEqualToString:@"jpg"])
        fileType = NSBitmapImageFileTypeJPEG;
    else if ([aType isEqualToString:@"gif"])
        fileType = NSBitmapImageFileTypeGIF;
    else if ([aType isEqualToString:@"tif"])
        fileType = NSBitmapImageFileTypeTIFF;
    else
        DebugLog(@"Error: unknown filetype!");
    
    // We need to retrieve the data stored in the save panel, and pack them into a dictionary
    NSTIFFCompression tiffCompression = (fileType == NSBitmapImageFileTypeJPEG ? NSTIFFCompressionJPEG : NSTIFFCompressionNone);
    CGFloat compressionFactor = [savePanelAccessoryController imageQuality];
    //BOOL alpha = [savePanelAccessoryViewController isAlphaEnabled];
    NSDictionary *propDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInteger:tiffCompression], NSImageCompressionMethod,
                              [NSNumber numberWithFloat:compressionFactor], NSImageCompressionFactor,
                              nil];
    
    // Convert the image into the data that we need to return
    data = [bitmap representationUsingType:fileType
                                properties:propDict];
    
    // Remember to re-flip the image after it's been saved!
    [SWImageTools flipImageVertical:bitmap];

    return data;
}


// By overwriting this, we can ask files saved by Paintbrush to open with Paintbrush
// in the future when double-clicked
- (NSDictionary *)fileAttributesToWriteToURL:(NSURL *)absoluteURL
									  ofType:(NSString *)typeName
							forSaveOperation:(NSSaveOperationType)saveOperation
						 originalContentsURL:(NSURL *)absoluteOriginalContentsURL
									   error:(NSError **)outError
{
    NSLog(@"typeName2 = %@", typeName);
    NSMutableDictionary *fileAttributes = [[super fileAttributesToWriteToURL:absoluteURL
																	  ofType:typeName 
															forSaveOperation:saveOperation
														 originalContentsURL:absoluteOriginalContentsURL
																	   error:outError] mutableCopy];
	
	// 'Pbsh' has been registered with Apple as our personal four-letter integer
	// NOTE: This attribute is actively ignored as of 10.6.  If we ever require that OS, go
	// ahead and remove this.
    [fileAttributes setObject:[NSNumber numberWithUnsignedInt:'Pbsh']
					   forKey:NSFileHFSCreatorCode];
    return fileAttributes;
}


// Customizing our save panel to provide a few more options for the user
- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel
{
    if (!savePanelAccessoryController) {
        savePanelAccessoryController = [[SWSavePanelAccessoryController alloc] initWithNibName:@"SavePanelAccessory"
                                                                                                bundle:nil];
        [savePanelAccessoryController addObserver:self
                                           forKeyPath:kSWCurrentFileType
                                              options:NSKeyValueObservingOptionNew
                                              context:NULL];
    }

    // Update the filetype based on the user defaults (after converting from human readable form)
    NSString *savedValue = [[NSUserDefaults standardUserDefaults] valueForKey:@"FileType"];
    currentFileType = [SWImageTools convertFromFileType:savedValue];
    
    // Make sure that it's loaded its view
    [savePanelAccessoryController loadView];
    NSView *accessoryView = [savePanelAccessoryController viewForFileType:savedValue];
    if (accessoryView) {
        [savePanel setAccessoryView:accessoryView];
    }
    
    if ([currentFileType isKindOfClass:[UTType class]]) {
        currentFileType = [(UTType *)currentFileType preferredFilenameExtension];
    }
    
    // Make sure the correct file extension is being used
    [savePanel setAllowedFileTypes:[NSArray arrayWithObject:currentFileType]];
    
    return YES;
}


// We need to override this because our save panel has its own format popup
- (NSString *)fileTypeFromLastRunSavePanel
{
    return currentFileType;
}


// Whenever the currently-selected filetype changes, this will trigger
- (void)observeValueForKeyPath:(NSString *)keyPath 
					  ofObject:(id)object 
						change:(NSDictionary *)change 
					   context:(void *)context
{
    NSString *newFileType = (NSString *)[change valueForKey:NSKeyValueChangeNewKey];
	if (newFileType)
	{
        if ([newFileType isKindOfClass:[UTType class]]) {
            currentFileType = [(UTType *)newFileType preferredFilenameExtension];
        } else {
            currentFileType = newFileType;
        }
        
		NSSavePanel *savePanel = (NSSavePanel *)[[savePanelAccessoryController view] window];
        [savePanel setAllowedFileTypes:[NSArray arrayWithObject:currentFileType]];
	}
}


// Opening an image
- (BOOL)readFromURL:(NSURL *)URL ofType:(NSString *)aType error:(NSError **)anError
{
#pragma unused(aType, anError)
	if (dataSource == nil)
	{
		// Create the data source
		dataSource = [[SWImageDataSource alloc] initWithURL:URL];
	} 
	else
	{
		// We are reloading an image, so we need to just update the data source
		void([dataSource initWithURL:URL]);
	}

	return (dataSource != nil);
}


// Printing: Cocoa makes it easy!
- (void)printDocument:(id)sender
{
    NSPrintOperation *op = [NSPrintOperation printOperationWithView:paintView
														  printInfo:[self printInfo]];
	
	SWPrintPanelAccessoryController *ppavc = [[SWPrintPanelAccessoryController alloc]
												   initWithNibName:@"PrintPanelAccessory" bundle:nil];
	[[op printPanel] addAccessoryController:ppavc];
    [op runOperationModalForWindow:[super windowForSheet]
						  delegate:self
					didRunSelector:NULL
					   contextInfo:NULL];
}

#pragma mark Handling undo

////////////////////////////////////////////////////////////////////////////////
//////////		Handling undo
////////////////////////////////////////////////////////////////////////////////


// Undo canvas resizing
- (void)handleUndoWithImageData:(NSData *)mainImageData frame:(NSRect)frame
{
	NSUndoManager *undo = [self undoManager];
	NSRect currentFrame = NSZeroRect;
	currentFrame.size = [dataSource size];
	NSData *mainImageDataCurrent = [dataSource copyMainImageData];
	[[undo prepareWithInvocationTarget:self] handleUndoWithImageData:mainImageDataCurrent frame:currentFrame];
	
	// Without resize, set the string to drawing
	if (NSEqualSizes(frame.size, NSZeroSize) || NSEqualSizes(frame.size, [dataSource size]))
		[undo setActionName:NSLocalizedString(@"Drawing", @"The standard undo command string for drawings")];
	else
	{
		// It doesn't matter here if we scale or not, since we'll be replacing the image in a moment
		[dataSource resizeToSize:frame.size scaleImage:NO];
		[paintView setFrame:frame];
		[clipView setNeedsDisplay:YES];
		[undo setActionName:NSLocalizedString(@"Resize", @"The undo command string image resizings")];
	}
	
	if (mainImageData == nil)
	{
		// No data was passed, so retrieve it from the data source
		NSData *mainImageData = [dataSource copyMainImageData];
		[[undo prepareWithInvocationTarget:self] handleUndoWithImageData:mainImageData frame:frame];
	}
	
	[dataSource restoreMainImageFromData:mainImageData];
	
	// Only clear the overlay during an undo -- NEVER during the initial setup
	if ([undo isUndoing])
		[paintView clearOverlay];
	
	// But force a redraw either way
	[paintView setNeedsDisplay:YES];
}


// Called whenever Copy or Cut are called (copies the overlay image to the pasteboard)
// TODO: Relieve some of this method's dependencies on the Selection tool
- (void)writeImageToPasteboard:(NSPasteboard *)pb
{
	NSAssert([[toolbox currentTool] isKindOfClass:[SWSelectionTool class]], 
			 @"How are we copying without a SWSelectionTool as the active tool?");
	if ([[toolbox currentTool] isKindOfClass:[SWSelectionTool class]])
	{
		SWSelectionTool *currentTool = (SWSelectionTool *)[toolbox currentTool];
		
		NSBitmapImageRep *selectedImage = [currentTool selectedImage];		
		
		// Make sure we flip the image before we put it in the pasteboard
		[SWImageTools flipImageVertical:selectedImage];
		
        [pb declareTypes:[NSArray arrayWithObject:NSPasteboardTypeTIFF] owner:self];
        [pb setData:[selectedImage TIFFRepresentation] forType:NSPasteboardTypeTIFF];
		
		// Now flip it again
		[SWImageTools flipImageVertical:selectedImage];
	}
}


// Cut: same as copy, but clears the overlay
- (IBAction)cut:(id)sender
{
	[self copy:sender];
	[paintView clearOverlay];
}


// Copy
- (IBAction)copy:(id)sender
{
	[self writeImageToPasteboard:[NSPasteboard generalPasteboard]];
}


// Paste
- (IBAction)paste:(id)sender
{
    [self handleUndoWithImageData:nil frame:NSZeroRect];
    [toolboxController switchToScissors:nil];
    
    NSData *data = nil;
    
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    for (NSPasteboardItem *item in pasteboard.pasteboardItems) {
        if ([pasteboard availableTypeFromArray:@[NSPasteboardTypeFileURL]]) {
            NSArray<NSURL *> *urls = [pasteboard readObjectsForClasses:@[[NSURL class]] options:@{
                NSPasteboardURLReadingFileURLsOnlyKey : @YES
            }];
            
            data = [NSData dataWithContentsOfURL:urls.firstObject];
            break;
        }
        
        if ([pasteboard availableTypeFromArray:@[NSPasteboardTypeTIFF]]) {
            data = [item dataForType:NSPasteboardTypeTIFF];
            break;
        }
    }
    
    if (data) {
        // [paintView cursorUpdate:[NSApp currentEvent]]; // TODO: (jarrodnorwell) check this
        NSBitmapImageRep *temp = [[NSBitmapImageRep alloc] initWithData:data];

        NSPoint origin = [[paintView superview] bounds].origin;
        if (origin.x < 0) origin.x = 0;
        if (origin.y < 0) origin.y = 0;

        NSRect rect = NSZeroRect;
        rect.origin = origin;

        // Use ceiling because pixels can be fractions, but the tool assumes integer values
        rect.size = NSMakeSize(ceil([temp size].width), ceil([temp size].height));
        
        [dataSource restoreBufferImageFromData:data];
        
        // As always, flip the image to be viewed in our flipped view
        [SWImageTools flipImageVertical:[dataSource bufferImage]];

        SWTool *oldTool = [toolbox currentTool];
        
        [toolbox setCurrentTool:[toolbox toolForLabel:@"SWSelectionTool"]];
        [(SWSelectionTool *)[toolbox currentTool] setClippingRect:rect
                                                         forImage:[dataSource bufferImage]
                                                    withMainImage:[dataSource mainImage]];
        [paintView setNeedsDisplay:YES];
        [toolbox setCurrentTool:oldTool];
    }
}


// Select all
- (IBAction)selectAll:(id)sender
{
	[toolboxController switchToScissors:nil];
	
	[[toolbox currentTool] setSavedPoint:NSZeroPoint];
	[[toolbox currentTool] performDrawAtPoint:NSMakePoint([paintView bounds].size.width, [paintView bounds].size.height)
								withMainImage:[dataSource mainImage] 
								  bufferImage:[dataSource bufferImage] 
								   mouseEvent:MOUSE_UP];
	
	// [paintView cursorUpdate:[NSApp currentEvent]]; // TODO: (jarrodnorwell) check this
	[paintView setNeedsDisplay:YES];
}


- (IBAction)zoomIn:(id)sender
{
	if ([sender isKindOfClass:[SWTool class]]) {
		// Came from the zoom tool, so get its point
		NSPoint point = [(SWTool *)sender savedPoint];
		[scrollView setScaleFactor:([scrollView scaleFactor] * 2) atPoint:point adjustPopup:YES];
	} else {
		// Came from somewhere else (probably an NSMenuItem)
		[scrollView setScaleFactor:([scrollView scaleFactor] * 2) adjustPopup:YES];
	}
}


- (IBAction)zoomOut:(id)sender
{
	if ([sender isKindOfClass:[SWTool class]]) {
		// Came from the zoom tool, so get its point
		NSPoint point = [(SWTool *)sender savedPoint];
		[scrollView setScaleFactor:([scrollView scaleFactor] / 2) atPoint:point adjustPopup:YES];
	} else {
		// Came from somewhere else (probably an NSMenuItem)
		[scrollView setScaleFactor:([scrollView scaleFactor] / 2) adjustPopup:YES];
	}
}


- (IBAction)actualSize:(id)sender
{
	[scrollView setScaleFactor:1 adjustPopup:YES];
}


- (IBAction)showGrid:(id)sender
{
	[paintView setShowsGrid:![paintView showsGrid]];
	[sender setState:[paintView showsGrid]];
}


// Decides which menu items to enable, and which to disable (and when)
//- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
- (BOOL)validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)anItem
{
	SEL action = [anItem action];
	if ((action == @selector(copy:)) || 
		(action == @selector(cut:)) || 
		(action == @selector(crop:))) 
	{
		return ([[[toolbox currentTool] class] isEqualTo:[SWSelectionTool class]] && 
				[(SWSelectionTool *)[toolbox currentTool] isSelected]);
	} 
	else if (action == @selector(paste:)) 
	{
		NSArray *array = [[NSPasteboard generalPasteboard] types];
		BOOL paste = NO;
		id object;
		for (object in array) 
		{
            if ([object isEqualToString:NSPasteboardTypeTIFF])
				paste = YES;
		}
		return paste;
	}
	else if (action == @selector(zoomIn:))
		return [scrollView scaleFactor] < 16;
	else if (action == @selector(zoomOut:))
		return [scrollView scaleFactor] > 0.25;
	else if (action == @selector(showGrid:))
		return [scrollView scaleFactor] > 2.0;
	else if (action == @selector(newFromClipboard:))
		return YES;
	else
		return YES;
}


// TODO: Nasty nasty hack - fix it!
+ (void)setWillShowSheet:(BOOL)showSheet
{
	kSWDocumentWillShowSheet = showSheet;
}


#pragma mark Handling notifications from the toolbox, application controller

////////////////////////////////////////////////////////////////////////////////
//////////		Handling notifications from the toolbox, application controller
////////////////////////////////////////////////////////////////////////////////


- (IBAction)flipHorizontal:(id)sender
{
	if ([[super windowForSheet] isKeyWindow])
	{
		[self handleUndoWithImageData:nil frame:NSZeroRect];
		NSBitmapImageRep *image = [dataSource mainImage];
		[SWImageTools flipImageHorizontal:image];
		[paintView setNeedsDisplay:YES];
	}
}


- (IBAction)flipVertical:(id)sender
{
	if ([[super windowForSheet] isKeyWindow]) 
	{
		[self handleUndoWithImageData:nil frame:NSZeroRect];
		NSBitmapImageRep *image = [dataSource mainImage];
		[SWImageTools flipImageVertical:image];
		[paintView setNeedsDisplay:YES];
	}
}


// Used to shrink the image background while also isolating a specific
// section of the image to save
- (IBAction)crop:(id)sender
{
	// First we need to make a temporary copy of what's selected by the selection tool
	if ([[toolbox currentTool] isKindOfClass:[SWSelectionTool class]])
	{
		NSRect rect = [(SWSelectionTool *)[toolbox currentTool] clippingRect];
		
		NSBitmapImageRep *croppedImage = [(SWSelectionTool *)[toolbox currentTool] selectedImage];
		
		// This is also important!
		[toolbox tieUpLooseEndsForCurrentTool];
		
		[self handleUndoWithImageData:nil frame:NSZeroRect];
				
		// Pretend we are a resize
		[dataSource resizeToSize:rect.size scaleImage:NO];
		
		// Set the image
		[dataSource restoreMainImageFromData:[croppedImage TIFFRepresentation]];
		
		// Redraw the Paint view and the clip view
		[paintView setFrame:NSMakeRect(0.0, 0.0, rect.size.width, rect.size.height)];
		[clipView setNeedsDisplay:YES];
	}
}


// We offload the heavy lifting to an external class
- (IBAction)invertColors:(id)sender
{
	[self handleUndoWithImageData:nil frame:NSZeroRect];
	[SWImageTools invertImage:[dataSource mainImage]];
	[paintView setNeedsDisplay:YES];
}


@end
