//
//  UserDefaults.m
//  IRCBot
//
//  Created by Ben K on 2010/09/13.
//  All code is provided under the New BSD license.
//

#import "UserDefaults.h"

@implementation UserDefaults



#pragma mark -
#pragma mark Initialization

// Awake from nib
-(void)awakeFromNib{
	//NSLog(@"IRCBot - Application Awake from Nib\n");
	
	// Hide the resize indicators on the windows
	[mainWindow setShowsResizeIndicator:NO]; [prefWindow setShowsResizeIndicator:NO]; [prefWindow center];
	[toolBar setSelectedItemIdentifier:@"Account_Settings"];
	
	// Check if this is the first start of the application
	// If it is show a setup window
	if (![self firstStart]){
		[startWindow center];	
		[startWindow makeKeyAndOrderFront:self];
		// Start modal session
		session = [NSApp beginModalSessionForWindow:startWindow];
		[[NSApplication sharedApplication] runModalSession:session];
	}else{
		[mainWindow makeKeyAndOrderFront:self];
		
		// Get password for username, stored in keychain
		NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
		NSString *savedUsername = [standardUserDefaults objectForKey:@"username"];
		
		[usernameField setStringValue:savedUsername];
		[prefs setPane:0];
		
		// Check where the password is stored
		if (![standardUserDefaults boolForKey:@"pass_in_plist"]){
			EMGenericKeychainItem *keychainItem = [EMGenericKeychainItem genericKeychainItemForService:@"IRCBot" withUsername:savedUsername];
			if (keychainItem != nil)
				[passwordField setStringValue:[NSString stringWithFormat:@"%@",[keychainItem password]]];
			else
				NSRunAlertPanel(@"Failed to retrive password from keychain",@"IRCBot couldn't access your irc password stored in the keychain.",@"OK",nil,nil);
		}else{
			if ([standardUserDefaults objectForKey:@"password"]){
				NSString* aStr = [[NSString alloc] initWithData:[standardUserDefaults objectForKey:@"password"] encoding:NSUTF8StringEncoding];
				[passwordField setStringValue:aStr];
				[aStr release];
			}else
				NSRunAlertPanel(@"Failed to retrive password from the .plist",@"Please re-enter the password in the IRCBot preferences.",@"OK",nil,nil);
		}
	}
}

// Save all the initial setup data to the .plist
-(IBAction)finishInitialSetup:(id)sender{
	
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	if (standardUserDefaults) {
		[standardUserDefaults setObject:[uName stringValue] forKey:@"username"];
		[EMGenericKeychainItem addGenericKeychainItemForService:@"IRCBot" withUsername:[uName stringValue] password:[uPassword stringValue]];
		[passwordField setStringValue:[uPassword stringValue]];
		[usernameField setStringValue:[uName stringValue]];
		
		[standardUserDefaults setObject:[uRealname stringValue] forKey:@"realname"];
		[standardUserDefaults setObject:[uNick stringValue] forKey:@"nickname"];
		[standardUserDefaults setInteger:1 forKey:@"timeout"];
		[standardUserDefaults setObject:[NSString stringWithFormat:@"%@: |+",[uNick stringValue]] forKey:@"triggers"];
		[standardUserDefaults setObject:@"irc.freenode.net" forKey:@"irc_server"];
		[standardUserDefaults setObject:@"6667" forKey:@"irc_port"];
		[standardUserDefaults setObject:@"#jzbot" forKey:@"ircHome"];
		[standardUserDefaults synchronize];
	}
	[usersData addHostmask:[hostMask stringValue] block:NO];
	[self setFirstStart:YES];
	
	// End modal session
	[NSApp endModalSession:session];
	// Close the setup window and show the main window
	[startWindow orderOut:self];
	[mainWindow center];
	[mainWindow setAlphaValue:0.0];
	[mainWindow makeKeyAndOrderFront:self];
	[prefs setPane:0];
	
	// Fade in the main window
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:mainWindow, NSViewAnimationTargetKey, NSViewAnimationFadeInEffect,NSViewAnimationEffectKey,nil];
	NSViewAnimation *animation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:dict]];
	[animation startAnimation];
	[animation release];	
}


//Reset app and show setup window 
-(IBAction)resetApplication:(id)sender{
	
	// Ask user if he's sure
	int answer = NSRunAlertPanel(@"Are you sure you want to reset IRCBot?",@"This will remove all your settings.", @"Cancel",@"Reset", nil);
	if(answer != NSAlertDefaultReturn){
		// Close all windows
		[mainWindow orderOut:self];
		[prefWindow orderOut:self];
		
		// Delete .plist
		NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
		[standardUserDefaults removePersistentDomainForName:@"com.mcspider.ircbot"];
		[standardUserDefaults synchronize];
		
		// Clear textFields
		[passwordField setStringValue:@""];
		[usernameField setStringValue:@""];
		[uName setStringValue:@""];
		[uPassword setStringValue:@""];
		[uNick setStringValue:@""];
		[uRealname setStringValue:@""];
		[hostMask setStringValue:@""];
		
		// Clear hostmask data
		[usersData clearData];
		
		// Start modal session and open setupwindow.
		session = [NSApp beginModalSessionForWindow:startWindow];
		[[NSApplication sharedApplication] runModalSession:session];
		[startWindow makeFirstResponder: uName];	
		[startWindow center];	
		[startWindow makeKeyAndOrderFront:self];
	}
}

// Set the setup bool in the .plist to true
-(void)setFirstStart:(BOOL)boolean
{
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	if (standardUserDefaults) {
		[standardUserDefaults setBool:boolean forKey:@"setup"];
		[standardUserDefaults synchronize];
	}
}

// Check the setup bool in the .plist
-(BOOL)firstStart{
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	if (standardUserDefaults)
		return [standardUserDefaults boolForKey:@"setup"];
	return NO;
}



#pragma mark -
#pragma mark Preferences

// IBAction invoked on pressing the OK button in the preferences
-(IBAction)savePreferences:(id)sender{
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];	
	[standardUserDefaults setObject:[usersData hostmaskArray] forKey:@"hostmasks"];		
	
	//NSString *actions = @"~/Library/Application Support/IRCBot/Functions.plist";
	NSString *actions = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/contents/resources/Actions.plist"];
	[ircActions.actionsArray writeToFile:[actions stringByExpandingTildeInPath] atomically:YES];	

	
	// Save the password to the appropriate location
	if (![passwordInPlistCheck state]){
		if ([standardUserDefaults objectForKey:@"password"])
			[standardUserDefaults removeObjectForKey:@"password"];	
		NSString *savedUsername = [standardUserDefaults objectForKey:@"username"];
		EMGenericKeychainItem *keychainItem = [EMGenericKeychainItem genericKeychainItemForService:@"IRCBot" withUsername:savedUsername];
		// if the password or username has been changed
		if (![[keychainItem password] isEqualToString:[passwordField stringValue]] || ![savedUsername isEqualToString:[usernameField stringValue]]){
			// If the keychain item already exits modify it
			if (keychainItem != nil){
				keychainItem.password = [passwordField stringValue];
				keychainItem.username = [usernameField stringValue];
			}else{
				[EMGenericKeychainItem addGenericKeychainItemForService:@"IRCBot" withUsername:[usernameField stringValue] password:[passwordField stringValue]];
			}
		}
	}else{
		NSData* aData = [[passwordField stringValue] dataUsingEncoding:NSUTF8StringEncoding];		
		[standardUserDefaults setObject:aData forKey:@"password"];	
	}
	
	[standardUserDefaults setObject:[usernameField stringValue] forKey:@"username"];	
	// Close the preferences window
	//[prefWindow orderOut:self];
}

-(BOOL)windowShouldClose:(NSWindow *)sender{	
	if (sender == prefWindow){
		[self savePreferences:nil];
		//NSLog(@"Saving Prefrences");
		return YES;
	}
	return YES;
}

-(void)dealloc{
	[super dealloc];
}

@end