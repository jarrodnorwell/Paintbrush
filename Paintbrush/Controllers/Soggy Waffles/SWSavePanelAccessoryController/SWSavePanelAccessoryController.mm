//
//  SWSavePanelAccessoryController.m
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


#import "SWImageTools.h"
#import "SWSavePanelAccessoryController.h"
#import "SWDocument.h"


NSString * const kSWCurrentFileTypeString = @"currentFileTypeString";

@implementation SWSavePanelAccessoryController


@synthesize currentFileTypeString;
@synthesize isAlphaEnabled;
@synthesize imageQuality;


// Overridden to initially populate the popup button
- (void)loadView
{
	[super loadView];
	
	// Use the file types
    NSArray *fileTypes = [SWDocument writableTypes];
    [fileTypeButton addItemsWithTitles:fileTypes];
	
	// Initialize the values for the controls in the subviews
	[self setImageQuality:0.8];
	[self setIsAlphaEnabled:YES];
}


- (NSView *)viewForFileType:(UTType *)fileType
{
    NSString *type = [SWImageTools fileExtensionForUTType:fileType];
    NSLog(@"type = %@", type);
    
	// We got a query for a filetype -- make sure that it's selected
    [fileTypeButton selectItemWithTitle:[[type stringByReplacingOccurrencesOfString:@"public." withString:@""] uppercaseString]];
	
	// We have a few views that we could use, depending on the file type
	[self updateViewForFileType:fileType];
	
	return [self view];
}


// Sets up the accessory view for optimal awesomeness
- (void)updateViewForFileType:(UTType *)fileType
{
	// First empty out the container view
	for (NSView *subview in [containerView subviews])
		[subview removeFromSuperview];
	
	// Now we can add the correct subview
	if (fileType == UTTypeJPEG) {
		[containerView addSubview:jpegView];
	}/* else {
		// In all other cases, just use this view
		[containerView addSubview:defaultView];
	}*/
	
}


// When they change fileType, swap views
- (IBAction)fileTypeDidChange:(id)sender
{
	// Convert the filetype for use as a file extension
	NSString *buttonSelection = [sender titleOfSelectedItem];
    NSLog(@"buttonSelection = %@", buttonSelection);
	UTType *finalString = [SWImageTools uttypeForFileExtension:buttonSelection];
	//
	// Use the explicit mutator, to trigger KVO
    NSLog(@"finalString = %@", finalString.preferredFilenameExtension);
	[self setCurrentFileTypeString:finalString.identifier];
	//
	// Update the container view for the new filetype
	[self updateViewForFileType:finalString];
}


@end
