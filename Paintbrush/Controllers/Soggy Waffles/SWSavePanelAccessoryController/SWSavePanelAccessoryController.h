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


#import <Cocoa/Cocoa.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

extern NSString * const kSWCurrentFileType;

@interface SWSavePanelAccessoryController : NSViewController {
    NSString *currentFileType;
    
	IBOutlet NSPopUpButton *fileTypeButton;
    IBOutlet NSSlider *compressionSlider;
    
    IBOutlet NSTextField *bestTextField;
    IBOutlet NSTextField *leastTextField;
    IBOutlet NSTextField *qualityTextField;
    
	BOOL isAlphaEnabled;
	CGFloat imageQuality;
}

-(IBAction) changeImageQuality:(NSSlider *)sender;

- (void)updateViewForFileType:(NSString *)fileType;
- (NSView *)viewForFileType:(NSString *)fileType;
- (IBAction)fileTypeDidChange:(id)sender;

@property (retain) NSString *currentFileType;

// These values are bound (binded?) to the controls in the various subviews
@property (assign) BOOL isAlphaEnabled;
@property (assign) CGFloat imageQuality;

@end
