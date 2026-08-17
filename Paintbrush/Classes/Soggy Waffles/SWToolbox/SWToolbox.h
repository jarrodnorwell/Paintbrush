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

@class SWToolboxController;
@class SWDocument;

@class SWJNTool;

@interface SWToolbox : NSObject  {
	NSMutableDictionary *toolList;
	SWToolboxController *sharedController;
	
	SWJNTool *currentTool;
}

@property (nonatomic, retain) SWJNTool *currentTool;

-(SWToolbox *) initWithDocument:(SWDocument *)document;
+(NSArray<id> *) toolClassList;
-(SWJNTool *) toolForLabel:(NSString *)label;
-(void) finaliseForCurrentTool;
@end
