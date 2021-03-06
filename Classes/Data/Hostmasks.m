//
//  IRCHostmasks.m
//  IRCBot
//
//  Created by Ben K on 2010/09/16.
//  All code is provided under the New BSD license.
//

#import "Hostmasks.h"

@implementation Hostmasks
@synthesize hostmaskArray;


- (id)init
{
	if ((self = [super init])) {
		NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
		
		self.hostmaskArray = [[NSMutableArray alloc] init];
		[self.hostmaskArray addObjectsFromArray:[standardUserDefaults objectForKey:@"hostmasks"]];		
	}
	return self;
}

-(void)addHostmask:(NSString *)host block:(BOOL)boolean
{
	int auth;
	if (boolean) auth = 1;
	else auth = 0;
	
	NSArray *tempArray = [NSArray arrayWithObjects:host,[NSNumber numberWithInt:auth],nil];
	[self.hostmaskArray addObject:tempArray];
	[hostmaskView reloadData];
}

-(IBAction)addNewHostmask:(id)sender
{
	// Check if this hostmask exists
	BOOL exists = NO;
	int i;
	for (i = 0; i < [self.hostmaskArray count]; i++){
		NSArray *hostmaskData = [self.hostmaskArray objectAtIndex:i];
		if ([[hostmaskData objectAtIndex:0] isEqualToString:[newHostmaskField stringValue]]){
			exists = YES;
		}
	}
	// If not add it, otherwise show a alert message
	if (!exists){	
		[self addHostmask:[newHostmaskField stringValue] block:[newHostmaskCheck state]];
		[sheetErrorMessage setStringValue:@" "];
		[addHostmaskPane closeSheet:self];
	}else{
		[sheetErrorMessage setStringValue:@"This hostmask already exists."];
	}
}

-(IBAction)removeSelectedHostmask:(id)sender
{
	[self.hostmaskArray removeObjectAtIndex:[hostmaskView selectedRow]];
	[hostmaskView reloadData];
}

-(void)clearData
{
	[self.hostmaskArray setArray:[NSArray array]];
	[hostmaskView reloadData];
}

-(BOOL)getAuthForHostmask:(NSString *)hostmask
{
	int index;
	for (index = 0; index < [self.hostmaskArray count]; index++){
		NSArray *tempArray = [self.hostmaskArray objectAtIndex:index];
		if ([[tempArray objectAtIndex:0] isEqualToString:hostmask] && ([[tempArray objectAtIndex:1] intValue] == 0)){
			return YES;
		}
	}
	return NO;
}


#pragma mark -
#pragma mark delegate messages

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [self.hostmaskArray count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
	NSArray *tempArray = [self.hostmaskArray objectAtIndex:row];
	
	if ([[tableColumn identifier] intValue] == 0)
		return [tempArray objectAtIndex:0];
	if ([[tableColumn identifier] intValue] == 1)
		return [tempArray objectAtIndex:1];
	return @"";
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification{
	if ([hostmaskView selectedRow] == -1 || [hostmaskView selectedRow] == 0)
		[removeHostmaskButton setEnabled:NO];
	else
		[removeHostmaskButton setEnabled:YES];
	
	userIndex = [hostmaskView selectedRow];	
}

-(void)tableView:(NSTableView *)tableView setObjectValue:(NSObject *)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row{
	NSMutableArray *tempArray = [self.hostmaskArray objectAtIndex:row];
	if ([[tableColumn identifier] intValue] == 0)
		tempArray = [NSMutableArray arrayWithObjects:object, [tempArray objectAtIndex:1], nil];
	if ([[tableColumn identifier] intValue] == 1)
		tempArray = [NSMutableArray arrayWithObjects:[tempArray objectAtIndex:0], object, nil];
	[self.hostmaskArray replaceObjectAtIndex:row withObject:tempArray];
}

-(void)dealloc{
	[hostmaskArray release];
	[super dealloc];
}

@end
