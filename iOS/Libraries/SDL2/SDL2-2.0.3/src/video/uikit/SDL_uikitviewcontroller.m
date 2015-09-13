/*
  Simple DirectMedia Layer
  Copyright (C) 1997-2014 Sam Lantinga <slouken@libsdl.org>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/
#include "../../SDL_internal.h"

#if SDL_VIDEO_DRIVER_UIKIT

#include "SDL_video.h"
#include "SDL_assert.h"
#include "SDL_hints.h"
#include "../SDL_sysvideo.h"
#include "../../events/SDL_events_c.h"

#include "SDL_uikitviewcontroller.h"
#include "SDL_uikitvideo.h"
#include "SDL_uikitmodes.h"
#include "SDL_uikitwindow.h"

#include "libintl.h"

#import <AVFoundation/AVFoundation.h>





int count = 0;
enum
{
    MENU_KEYBOARD = 10001,
    MENU_INFO,
    MENU_ACTION,
    MENU_ATTACK,
    MENU_INVENTORY,
    MENU_ADV_INVENTORY,
    MENU_BUILD,
    MENU_SPECIAL
};

@implementation SDL_uikitviewcontroller
{
    NSDictionary* infoActionsCharTable;
    NSDictionary* environActionsCharTable;
    CNPGridMenu* actionsMenu;
    CNPGridMenu* settingsMenu;

    JSDPad *dPad;
    JSButton* yesButton;
    JSButton* noButton;
    JSButton* nextButton;
    JSButton* prevButton;
    
    NSTimer* dpadTimer;
    
    NSMutableDictionary* actionDesc;
    NSMutableArray* userKeyBindings;
    
    MHWDirectoryWatcher* optionsFileWatcher;
    
    NSDate* keybindingsLastModificationDate;
    NSString* documentPath;
    NSString* userKeyBindingsPath;
    
    NSArray* allMenuItems;
    
    AVAudioPlayer *myAudioPlayer;
    AVAudioPlayer* soundPlayer;
    
    MYBlurIntroductionView *introductionView;
    
    UILongPressGestureRecognizer * longPressGesture;
    UIPanGestureRecognizer* panGesture;
    
    BOOL showIntroduction;
}

@synthesize window;

- (id)initWithSDLWindow:(SDL_Window *)_window
{
    self = [self init];
    if (self == nil) {
        return nil;
    }
    self.window = _window;
  /*
    infoActionsCharTable = @{ ACTION_INFO_PLAYER: @"@",
                              ACTION_INFO_MAP: @"m",
                              ACTION_INFO_MISSIONS: @"M",
                              ACTION_INFO_FACTIONS: @"#",
                              ACTION_INFO_KILLCOUNT: @")",
                              ACTION_INFO_MORALE: @"v",
                              ACTION_INFO_MESSAGELOG: @"P",
                              ACTION_INFO_HELP: @"?",
                                 };
    
    environActionsCharTable = @{ ACTION_ENVIRONMENT_OPEN: @"o",
                         ACTION_ENVIRONMENT_CLOSE: @"c",
                         ACTION_ENVIRONMENT_SMASH: @"s",
                         ACTION_ENVIRONMENT_EXAMINE: @"e",
                         ACTION_ENVIRONMENT_PICK: @"g",
                         ACTION_ENVIRONMENT_GRAB: @"G",
                         ACTION_ENVIRONMENT_BUTCHER: @"B",
                         ACTION_ENVIRONMENT_CHAT: @"C",
                         ACTION_ENVIRONMENT_LOOK: @"x",
                         ACTION_ENVIRONMENT_PEEK: @"X",
                         ACTION_ENVIRONMENT_LIST: @"V",
                         };
    */
    
    if( 1 == count )
    {
            //track = [OALAudioTrack track];
            //[track preloadFile:@"CBRadioMessageHelp_ZA01.146.wav"];
            //[track setNumberOfLoops:-1];
            //[track play];
        //[[OALSimpleAudio sharedInstance] playBg:@"CBRadioMessageHelp_ZA01.146.wav" loop:-1];
        NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:@"DTA_Eminor_Spheres.wav" ];
        myAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
        myAudioPlayer.numberOfLoops = -1; //infinite loop
        
        fileURL = [[NSURL alloc] initFileURLWithPath:@"StabStringsCinematic_ZA02.520.wav" ];
        soundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
        soundPlayer.numberOfLoops = 0;
        
        [myAudioPlayer play];
        
        showIntroduction = YES;
    }
    
    count++;

    
    return self;
}

- (void)loadView
{
    /* do nothing. */
}



-(NSArray*)createMenuItems:(NSArray*)items
{
    NSMutableArray* menuItems = [NSMutableArray array];
    for (NSDictionary* item in items )
    {
        CNPGridMenuItem *menuItem = [[CNPGridMenuItem alloc] init];
        //menuItem.icon = [UIImage imageNamed:item[@"Icon"]];
        //menuItem.icon = [self imageFromText:item[@"Command"] width:40 height:40];
        menuItem.icon = [self imageWithText:item[@"Command"] fontSize:32 rectSize:CGSizeMake(40, 40)];
        menuItem.title = item[@"Title"];
        menuItem.selectionHandler = ^(CNPGridMenuItem* menuItem){
            SDL_SendKeyboardText( [item[@"Command"] cStringUsingEncoding:NSASCIIStringEncoding] );
            [actionsMenu dismissGridMenuAnimated:YES completion:nil];
            [panGesture setEnabled:YES];
        };
        [menuItems addObject:menuItem];
    }
    
#if 0
    // append setting menu item
    CNPGridMenuItem *menuItem = [[CNPGridMenuItem alloc] init];
    menuItem.icon = [self imageWithText:@"👼" fontSize:32 rectSize:CGSizeMake(40, 40)];
    menuItem.title = @"Settings";
    menuItem.selectionHandler = ^(CNPGridMenuItem* menuItem){
        NSLog(@"Setting Pressed");
        [actionsMenu dismissGridMenuAnimated:NO completion:nil];
        [self performSelectorOnMainThread:@selector(showSettingsMenu) withObject:nil waitUntilDone:NO];
    };
    [menuItems addObject:menuItem];
#endif
    
    return [NSArray arrayWithArray:menuItems];
}

-(void)showSettingsMenu
{
    [self presentGridMenu:settingsMenu animated:YES completion:nil];
}

-(void)dismissSettingsMenu
{
    [settingsMenu dismissGridMenuAnimated:YES completion:nil];
}


-(NSArray*)createSettingsMenuItems
{
    NSArray* items = @[ @"Controls", @"Home", @"Wiki", @"Item Browser", @"Q/A", @"Rate" ];
//    NSArray* itemActions = @[
//                                ^(CNPGridMenuItem* menuItem){
//                                    
//                                    //[settingsMenu dismissGridMenuAnimated:YES completion:nil];
//                                    //[self performSelectorOnMainThread:@selector(dismissSettingsMenu) withObject:nil waitUntilDone:NO];
//                                    
//                                },
//                                ^(CNPGridMenuItem* menuItem){
//                                    NSLog( @"show home" );
//                                },
//                                ^(CNPGridMenuItem* menuItem){
//                                    NSLog( @"show wiki" );
//                                },
//                                ^(CNPGridMenuItem* menuItem){
//                                    NSLog( @"show item browser" );
//                                },
//                                ^(CNPGridMenuItem* menuItem){
//                                    NSLog( @"show Q/A" );
//                                },
//                                ^(CNPGridMenuItem* menuItem){
//                                    NSLog( @"show rate" );
//                                },
//                                 
//                              ];
//    NSArray* icons = @{ @"C", @"W", @"I", @"Q" };
    NSMutableArray* menuItems = [NSMutableArray array];
    for( NSUInteger i = 0; i < [items count]; ++i )
    {
        NSString* item = items[i];
    
        CNPGridMenuItem *menuItem = [[CNPGridMenuItem alloc] init];
        //menuItem.icon = [UIImage imageNamed:item[@"Icon"]];
        //menuItem.icon = [self imageFromText:item[@"Command"] width:40 height:40];
        menuItem.icon = [self imageWithText:@"H" fontSize:32 rectSize:CGSizeMake(40, 40)];
        menuItem.title = item;
        //menuItem.selectionHandler = itemActions[i];
        [menuItems addObject:menuItem];
    }
    
    ((CNPGridMenuItem*)menuItems[0]).selectionHandler =^ (CNPGridMenuItem* menuItem){
        
        NSLog( @"show controls" );
        [settingsMenu dismissGridMenuAnimated:YES completion:nil];
        //[self performSelectorOnMainThread:@selector(dismissSettingsMenu) withObject:nil waitUntilDone:NO];
        
    };
    
    ((CNPGridMenuItem*)menuItems[1]).selectionHandler =^ (CNPGridMenuItem* menuItem){
        
        NSLog( @"show home" );
        [settingsMenu dismissGridMenuAnimated:YES completion:nil];
        //[self performSelectorOnMainThread:@selector(dismissSettingsMenu) withObject:nil waitUntilDone:NO];
        
    };
    
    ((CNPGridMenuItem*)menuItems[2]).selectionHandler =^ (CNPGridMenuItem* menuItem){
        
        NSLog( @"show wiki" );
        [settingsMenu dismissGridMenuAnimated:YES completion:nil];
        //[self performSelectorOnMainThread:@selector(dismissSettingsMenu) withObject:nil waitUntilDone:NO];
        
    };
    
    ((CNPGridMenuItem*)menuItems[3]).selectionHandler =^ (CNPGridMenuItem* menuItem){
        
        NSLog( @"show item browser" );
        [settingsMenu dismissGridMenuAnimated:YES completion:nil];
        //[self performSelectorOnMainThread:@selector(dismissSettingsMenu) withObject:nil waitUntilDone:NO];
        
    };
    
    ((CNPGridMenuItem*)menuItems[4]).selectionHandler =^ (CNPGridMenuItem* menuItem){
        
        NSLog( @"show Q/A" );
        [settingsMenu dismissGridMenuAnimated:YES completion:nil];
        //[self performSelectorOnMainThread:@selector(dismissSettingsMenu) withObject:nil waitUntilDone:NO];
        
    };

    ((CNPGridMenuItem*)menuItems[5]).selectionHandler =^ (CNPGridMenuItem* menuItem){
        
        NSLog( @"show rate" );
        [settingsMenu dismissGridMenuAnimated:YES completion:nil];
        //[self performSelectorOnMainThread:@selector(dismissSettingsMenu) withObject:nil waitUntilDone:NO];
        
    };



    
    return [NSArray arrayWithArray:menuItems];
}


- (void)gridMenuDidTapOnBackground:(CNPGridMenu *)menu {
    
    [self dismissGridMenuAnimated:YES completion:^{
        [panGesture setEnabled:YES];
        NSLog(@"Grid Menu Dismissed With Background Tap");
    }];
}

#if 0
- (void)gridMenu:(CNPGridMenu *)menu didTapOnItem:(CNPGridMenuItem *)item {

    [self dismissGridMenuAnimated:NO completion:^{
        NSLog(@"Grid Menu Did Tap On Item: %@", item.title);
    }];
}
#endif


//-(void)TouchUpInside:(id)sender
//{
//    UIButton* button = (UIButton*)sender;
//    switch ( button.tag )
//    {
//        case 1000:
//            SDL_SendKeyboardKey( SDL_PRESSED, SDL_SCANCODE_LEFT );
//            SDL_SendKeyboardKey( SDL_RELEASED, SDL_SCANCODE_LEFT );
//            break;
//        case 1001:
//            SDL_SendKeyboardKey( SDL_PRESSED, SDL_SCANCODE_RIGHT );
//            SDL_SendKeyboardKey( SDL_RELEASED, SDL_SCANCODE_RIGHT );
//            break;
//        case 1002:
//            SDL_SendKeyboardKey( SDL_PRESSED, SDL_SCANCODE_UP );
//            SDL_SendKeyboardKey( SDL_RELEASED, SDL_SCANCODE_UP );
//            break;
//        case 1003:
//            SDL_SendKeyboardKey( SDL_PRESSED, SDL_SCANCODE_DOWN );
//            SDL_SendKeyboardKey( SDL_RELEASED, SDL_SCANCODE_DOWN );
//            break;
//        case 1004:
//            SDL_SendKeyboardKey( SDL_PRESSED, SDL_SCANCODE_RETURN );
//            SDL_SendKeyboardKey( SDL_RELEASED, SDL_SCANCODE_RETURN );
//            
//            break;
//        case 1005:
//            SDL_SendKeyboardKey( SDL_PRESSED, SDL_SCANCODE_ESCAPE );
//            SDL_SendKeyboardKey( SDL_RELEASED, SDL_SCANCODE_ESCAPE );
//            
//            break;
//
//        case 1006:
//            SDL_SendKeyboardText("<");
//            break;
//            
//        case 1007:
//            SDL_SendKeyboardText( ">" );
//            break;
//
//        default:
//            break;
//    }
//    
//    NSLog(@"TouchUpInside");
//}


-(void)doVolumeFade1
{
    if (myAudioPlayer.volume > 0.1) {
        myAudioPlayer.volume = myAudioPlayer.volume - 0.1;
        [self performSelector:@selector(doVolumeFade1) withObject:nil afterDelay:0.1];
    } else {
        // Stop and get the sound ready for playing again
        [myAudioPlayer stop];
//        NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:@"DTA_Eminor_Spheres.wav" ];
//        myAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
//        myAudioPlayer.numberOfLoops = -1; //infinite loop
//        [myAudioPlayer play];
//        self.player.currentTime = 0;
//        [self.player prepareToPlay];
//        self.player.volume = 1.0;
    }
}

-(void)doVolumeFade2
{
    if (myAudioPlayer.volume > 0.1) {
        myAudioPlayer.volume = myAudioPlayer.volume - 0.1;
        [self performSelector:@selector(doVolumeFade2) withObject:nil afterDelay:0.1];
    } else {
        // Stop and get the sound ready for playing again
        [myAudioPlayer stop];
        //        self.player.currentTime = 0;
        //        [self.player prepareToPlay];
        //        self.player.volume = 1.0;
    }
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self.view setNeedsDisplay];
}

- (void)viewDidAppear:(BOOL)animated
{
    //[track play];
    //[track fadeTo:0.0 duration:3.0 target:nil selector:nil];
    [super viewDidAppear:animated];
    
    
    //else
    {
        
        if (self->window->flags & SDL_WINDOW_RESIZABLE) {
            SDL_WindowData *data = self->window->driverdata;
            SDL_VideoDisplay *display = SDL_GetDisplayForWindow(self->window);
            SDL_DisplayModeData *displaymodedata = (SDL_DisplayModeData *) display->current_mode.driverdata;
            const CGSize size = data->view.bounds.size;
            int w, h;

            w = (int)(size.width * displaymodedata->scale);
            h = (int)(size.height * displaymodedata->scale);

            SDL_SendWindowEvent(self->window, SDL_WINDOWEVENT_RESIZED, w, h);
        }
        


        

        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(singleTapped)];
        singleTap.numberOfTapsRequired = 1;
        singleTap.delegate = self;
        [self.view addGestureRecognizer:singleTap];
        
        
        UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        swipeUp.numberOfTouchesRequired = 1;
        swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
        swipeUp.delegate = self;
        [self.view addGestureRecognizer:swipeUp];
        
        UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        swipeDown.numberOfTouchesRequired = 1;
        swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
        swipeDown.delegate = self;
        [self.view addGestureRecognizer:swipeDown];
        
        UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        swipeLeft.numberOfTouchesRequired = 1;
        swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
        swipeLeft.delegate = self;
        [self.view addGestureRecognizer:swipeLeft];
        
        UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        swipeRight.numberOfTouchesRequired = 1;
        swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
        swipeRight.delegate = self;
        [self.view addGestureRecognizer:swipeRight];
        
        
        panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        panGesture.minimumNumberOfTouches = 2;
        panGesture.maximumNumberOfTouches = 3;
        panGesture.delegate = self;
        [self.view addGestureRecognizer:panGesture];
        
        
        longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(hangleLongPress:)];
        longPressGesture.minimumPressDuration = 1.0;
        [self.view addGestureRecognizer:longPressGesture];

        
        
        noButton = [[JSButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-64-64-16, self.view.bounds.size.height-64, 64, 64)];
        //[[yesButton titleLabel] setText:@"Next"];
        [noButton setBackgroundImage:[UIImage imageNamed:@"No"]];
        [noButton setBackgroundImagePressed:[UIImage imageNamed:@"No_Touched"]];
        noButton.delegate = self;
        noButton.alpha = 0.3f;
        [self.view addSubview:noButton];
        
        
        yesButton = [[JSButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-64, self.view.bounds.size.height-64, 64, 64)];
        //[[noButton titleLabel] setText:@"Prev"];
        [yesButton setBackgroundImage:[UIImage imageNamed:@"Yes"]];
        [yesButton setBackgroundImagePressed:[UIImage imageNamed:@"Yes_Touched"]];
        yesButton.delegate = self;
        yesButton.alpha = 0.3f;
        [self.view addSubview:yesButton];
        
        prevButton = [[JSButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-64-64-16, self.view.bounds.size.height-64-64, 64, 64)];
        //[[yesButton titleLabel] setText:@"Next"];
        [prevButton setBackgroundImage:[UIImage imageNamed:@"Prev"]];
        [prevButton setBackgroundImagePressed:[UIImage imageNamed:@"Prev_Touched"]];
        prevButton.delegate = self;
        prevButton.alpha = 0.3f;
        [self.view addSubview:prevButton];
        
        nextButton = [[JSButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-64, self.view.bounds.size.height-64-64, 64, 64)];
        //[[yesButton titleLabel] setText:@"Next"];
        [nextButton setBackgroundImage:[UIImage imageNamed:@"Next"]];
        [nextButton setBackgroundImagePressed:[UIImage imageNamed:@"Next_Touched"]];
        nextButton.delegate = self;
        nextButton.alpha = 0.3f;
        [self.view addSubview:nextButton];
        
        
    //    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:button1 attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    //    
    //    NSDictionary *views = NSDictionaryOfVariableBindings(button1, button2, button3, button4, button5, button6, button7, button8);
    //    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[button1][button2(==button1)][button3(==button1)][button4(==button1)][button5(==button1)][button6(==button1)][button7(==button1)][button8(==button1)]|" options:NSLayoutFormatAlignAllTop metrics:nil views:views]];


        UIPinchGestureRecognizer* pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
        [self.view addGestureRecognizer:pinchGestureRecognizer];
        
        
        
        dPad = [[JSDPad alloc] initWithFrame:CGRectMake(8, self.view.bounds.size.height - 8 - 144, 144, 144)];
        dPad.delegate = self;
        dPad.alpha = 0.3f;
        [self.view addSubview:dPad];
        
        
        
        
        
        [self loadKeyBindings];
        
        allMenuItems = [self createMenuItems:userKeyBindings];
        actionsMenu = [[CNPGridMenu alloc] initWithMenuItems:allMenuItems];
        actionsMenu.delegate = self;
        
        
        NSArray* settingsMenuItems = [self createSettingsMenuItems];
    //    settingsMenu = [[CNPGridMenu alloc] initWithMenuItems:settingsMenuItems];
        settingsMenu = [[CNPGridMenu alloc] initWithMenuItems:@[]];
        [settingsMenu setMenuItems:settingsMenuItems];
        settingsMenu.delegate = self;
        
        
        
        documentPath = [[[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] path] stringByAppendingString:@"/"];
        optionsFileWatcher = [MHWDirectoryWatcher directoryWatcherAtPath:[documentPath stringByAppendingPathComponent:@"options.txt"] callback:^{
            [optionsFileWatcher stopWatching];
            [self performSelectorOnMainThread:@selector(optionsFileDidChange) withObject:nil waitUntilDone:NO];
        }];
        

        userKeyBindingsPath = [documentPath stringByAppendingPathComponent:@"keybindings.json"];
        
        NSError* e;
        NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:userKeyBindingsPath error:&e];
        keybindingsLastModificationDate = attributes[@"NSFileModificationDate"];
        
    }
    
    if( showIntroduction )
    {
        //[self doVolumeFade1];
        showIntroduction = NO;
        [self showIntroductionView];
    }
}

- (NSUInteger)supportedInterfaceOrientations
{
    NSUInteger orientationMask = 0;

    const char *orientationsCString;
    if ((orientationsCString = SDL_GetHint(SDL_HINT_ORIENTATIONS)) != NULL) {
        BOOL rotate = NO;
        NSString *orientationsNSString = [NSString stringWithCString:orientationsCString
                                                            encoding:NSUTF8StringEncoding];
        NSArray *orientations = [orientationsNSString componentsSeparatedByCharactersInSet:
                                 [NSCharacterSet characterSetWithCharactersInString:@" "]];

        if ([orientations containsObject:@"LandscapeLeft"]) {
            orientationMask |= UIInterfaceOrientationMaskLandscapeLeft;
        }
        if ([orientations containsObject:@"LandscapeRight"]) {
            orientationMask |= UIInterfaceOrientationMaskLandscapeRight;
        }
        if ([orientations containsObject:@"Portrait"]) {
            orientationMask |= UIInterfaceOrientationMaskPortrait;
        }
        if ([orientations containsObject:@"PortraitUpsideDown"]) {
            orientationMask |= UIInterfaceOrientationMaskPortraitUpsideDown;
        }

    } else if (self->window->flags & SDL_WINDOW_RESIZABLE) {
        orientationMask = UIInterfaceOrientationMaskAll;  /* any orientation is okay. */
    } else {
        if (self->window->w >= self->window->h) {
            orientationMask |= UIInterfaceOrientationMaskLandscape;
        }
        if (self->window->h >= self->window->w) {
            orientationMask |= (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown);
        }
    }

    /* Don't allow upside-down orientation on the phone, so answering calls is in the natural orientation */
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        orientationMask &= ~UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    return orientationMask;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orient
{
    NSUInteger orientationMask = [self supportedInterfaceOrientations];
    return (orientationMask & (1 << orient));
}

- (BOOL)prefersStatusBarHidden
{
//    if (self->window->flags & (SDL_WINDOW_FULLSCREEN|SDL_WINDOW_BORDERLESS)) {
//        return YES;
//    } else {
//        return NO;
//    }
    return YES;
}

-(void)singleTapped
{
    //NSLog( @"Single Tapped" );
    SDL_SendKeyboardText( "." );
}


- (void) handleSwipe:(UISwipeGestureRecognizer*)gesture
{
    //NSLog( @"Double Swipe: %lu", (unsigned long)gesture.direction );
    
    if( UISwipeGestureRecognizerDirectionUp == gesture.direction )
    {
        if( !SDL_IsScreenKeyboardShown( SDL_GetFocusWindow() ) )
            SDL_StartTextInput();
//        else
//            SDL_StopTextInput();
    }
    else if( UISwipeGestureRecognizerDirectionDown == gesture.direction )
    {
        if( SDL_IsScreenKeyboardShown( SDL_GetFocusWindow() ) )
        {
            SDL_StopTextInput();
            self.lockKeyboard = NO;
        }
        //[self presentGridMenu:actionsMenu animated:YES completion:nil];
    }
    else if( UISwipeGestureRecognizerDirectionLeft == gesture.direction )
    {
        SDL_SendKeyboardText( "V" );
    }
    else if( UISwipeGestureRecognizerDirectionRight == gesture.direction )
    {
        SDL_SendKeyboardText( "m" );
    }
}

-(void)handlePanGesture:(UIPanGestureRecognizer*)gesture
{
    //NSLog( @"%lu %f", (unsigned long)gesture.numberOfTouches, [gesture translationInView:self.view].y );
    
    
    
    
    if( 2 == gesture.numberOfTouches )
    {
        [panGesture setEnabled:NO];
        
        NSError* e;
        NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:userKeyBindingsPath error:&e];
        NSDate* currentModificationDate = attributes[@"NSFileModificationDate"];
        
        if( [currentModificationDate compare:keybindingsLastModificationDate] == NSOrderedDescending )
        {
            keybindingsLastModificationDate = currentModificationDate;
            [self keybindingsFileDidChange];
        }
        
        [self presentGridMenu:actionsMenu animated:YES completion:^{
            
        }];

    }
    else if( 3 == gesture.numberOfTouches )
    {
        float alpha = dPad.alpha;
        float offsetY = [gesture translationInView:self.view].y;
        if( offsetY > 0 )
        {
            alpha -= 0.02;
            if( alpha <= 0.1 )
                alpha = 0.1;
        }
        else if( offsetY < 0 )
        {
            alpha += 0.02;
            if( alpha >= 0.9 )
                alpha = 0.9;
        }
        
        dPad.alpha = alpha;
        yesButton.alpha = alpha;
        noButton.alpha = alpha;
        nextButton.alpha = alpha;
        prevButton.alpha = alpha;
    }
    
    
    [gesture setTranslation:CGPointMake(0, 0) inView:self.view];
}

-(void)hangleLongPress:(UILongPressGestureRecognizer*)gesture
{
    if( gesture.state == UIGestureRecognizerStateEnded )
    {
        NSLog( @"Long Press Ended" );
    }
    else if( gesture.state == UIGestureRecognizerStateBegan )
    {
        NSLog( @"Long Press Began" );
        if( !SDL_IsScreenKeyboardShown( SDL_GetFocusWindow() ) )
        {
            self.lockKeyboard = YES;
            SDL_StartTextInput();
        }
    }
}


-(void)handlePinchGesture:(UIPinchGestureRecognizer*)pinchGestureRecognier
{
    float threshold = 0.1f;
    
    if( pinchGestureRecognier.state == UIGestureRecognizerStateEnded )
    {
        NSLog( @"%f", pinchGestureRecognier.scale );
        if( pinchGestureRecognier.scale > ( 1.0f + threshold ) )
            SDL_SendKeyboardText( "Z" );
        else if( pinchGestureRecognier.scale < ( 1.0f - threshold ) )
            SDL_SendKeyboardText( "z" );
        pinchGestureRecognier.scale = 1.0f;
    }
    
}




- (UIImage *)imageWithText:(NSString *)text fontSize:(CGFloat)fontSize rectSize:(CGSize)rectSize {
    
    // 描画する文字列のフォントを設定。
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    
    // オフスクリーン描画のためのグラフィックスコンテキストを作る。
    if (UIGraphicsBeginImageContextWithOptions != NULL)
        UIGraphicsBeginImageContextWithOptions(rectSize, NO, 0.0f);
    else
        UIGraphicsBeginImageContext(rectSize);
    
    /* Shadowを付ける場合は追加でこの部分の処理を行う。
     CGContextRef ctx = UIGraphicsGetCurrentContext();
     CGContextSetShadowWithColor(ctx, CGSizeMake(1.0f, 1.0f), 5.0f, [[UIColor grayColor] CGColor]);
     */
    
    // 文字列の描画領域のサイズをあらかじめ算出しておく。
    CGSize textAreaSize = [text sizeWithFont:font constrainedToSize:rectSize];
    
    // 描画対象領域の中央に文字列を描画する。
    [text drawInRect:CGRectMake((rectSize.width - textAreaSize.width) * 0.5f,
                                (rectSize.height - textAreaSize.height) * 0.5f,
                                textAreaSize.width,
                                textAreaSize.height)
            withFont:font
       lineBreakMode:NSLineBreakByWordWrapping
           alignment:NSTextAlignmentCenter];
    
    // コンテキストから画像オブジェクトを作成する。
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

-(void)dpadTimerHandler:(NSTimer *)timer
{
    //NSLog( @"dpadTimerHandler" );
    
    switch( [[timer userInfo][@"Direction"] integerValue] )
    {
        case JSDPadDirectionLeft:
            SDL_SendKeyboardKey( SDL_PRESSED, SDL_SCANCODE_LEFT );
            SDL_SendKeyboardKey( SDL_RELEASED, SDL_SCANCODE_LEFT );
            break;
            
        case JSDPadDirectionRight:
            SDL_SendKeyboardKey( SDL_PRESSED, SDL_SCANCODE_RIGHT );
            SDL_SendKeyboardKey( SDL_RELEASED, SDL_SCANCODE_RIGHT );
            break;
            
        case JSDPadDirectionUp:
            SDL_SendKeyboardKey( SDL_PRESSED, SDL_SCANCODE_UP );
            SDL_SendKeyboardKey( SDL_RELEASED, SDL_SCANCODE_UP );
            break;
            
        case JSDPadDirectionDown:
            SDL_SendKeyboardKey( SDL_PRESSED, SDL_SCANCODE_DOWN );
            SDL_SendKeyboardKey( SDL_RELEASED, SDL_SCANCODE_DOWN );
            break;
            
        case JSDPadDirectionUpLeft:
            SDL_SendKeyboardText( "y" );
            break;
            
        case JSDPadDirectionUpRight:
            SDL_SendKeyboardText( "u" );
            break;
            
        case JSDPadDirectionDownLeft:
            SDL_SendKeyboardText( "b" );
            break;
            
        case JSDPadDirectionDownRight:
            SDL_SendKeyboardText( "n" );
            break;
            
        default:
            break;
            
    }
    
    //dpadTimer = [NSTimer scheduledTimerWithTimeInterval:0.333 target:self selector:@selector(dpadTimerHandler:) userInfo:@{@"Direction": [timer userInfo][@"Direction"]} repeats:NO];
    
//    [dpadTimer fire];
    
}

#pragma mark - JSDPadDelegate
- (NSString *)stringForDirection:(JSDPadDirection)direction
{
    NSString *string = nil;
    
    switch (direction) {
        case JSDPadDirectionNone:
            string = @"None";
            SDL_SendKeyboardText( "." );
            break;
        case JSDPadDirectionUp:
            string = @"Up";
            SDL_SendKeyboardKey( SDL_PRESSED, SDL_SCANCODE_UP );
            SDL_SendKeyboardKey( SDL_RELEASED, SDL_SCANCODE_UP );
            if( dpadTimer && [dpadTimer isValid] )
            {
                [dpadTimer invalidate];
                dpadTimer = nil;
            }
            dpadTimer = [NSTimer scheduledTimerWithTimeInterval:0.333 target:self selector:@selector(dpadTimerHandler:) userInfo:@{@"Direction": [NSNumber numberWithInteger:JSDPadDirectionUp]} repeats:YES];
            
            //[dpadTimer fire];
            //SDL_SendKeyboardText( "8" );
            break;
        case JSDPadDirectionDown:
            string = @"Down";
            SDL_SendKeyboardKey( SDL_PRESSED, SDL_SCANCODE_DOWN );
            SDL_SendKeyboardKey( SDL_RELEASED, SDL_SCANCODE_DOWN );
            if( dpadTimer && [dpadTimer isValid] )
            {
                [dpadTimer invalidate];
                dpadTimer = nil;
            }
            dpadTimer = [NSTimer scheduledTimerWithTimeInterval:0.333 target:self selector:@selector(dpadTimerHandler:) userInfo:@{@"Direction": [NSNumber numberWithInteger:JSDPadDirectionDown]} repeats:YES];
            
            //[dpadTimer fire];
            //SDL_SendKeyboardText( "2" );
            break;
        case JSDPadDirectionLeft:
            string = @"Left";
            SDL_SendKeyboardKey( SDL_PRESSED, SDL_SCANCODE_LEFT );
            SDL_SendKeyboardKey( SDL_RELEASED, SDL_SCANCODE_LEFT );
            if( dpadTimer && [dpadTimer isValid] )
            {
                [dpadTimer invalidate];
                dpadTimer = nil;
            }
            dpadTimer = [NSTimer scheduledTimerWithTimeInterval:0.333 target:self selector:@selector(dpadTimerHandler:) userInfo:@{@"Direction": [NSNumber numberWithInteger:JSDPadDirectionLeft]} repeats:YES];
            
            //[dpadTimer fire];

            //SDL_SendKeyboardText( "h" );
            break;
        case JSDPadDirectionRight:
            string = @"Right";
            SDL_SendKeyboardKey( SDL_PRESSED, SDL_SCANCODE_RIGHT );
            SDL_SendKeyboardKey( SDL_RELEASED, SDL_SCANCODE_RIGHT );
            if( dpadTimer && [dpadTimer isValid] )
            {
                [dpadTimer invalidate];
                dpadTimer = nil;
            }
            dpadTimer = [NSTimer scheduledTimerWithTimeInterval:0.333 target:self selector:@selector(dpadTimerHandler:) userInfo:@{@"Direction": [NSNumber numberWithInteger:JSDPadDirectionRight]} repeats:YES];
            
            //[dpadTimer fire];
            //SDL_SendKeyboardText( "l" );
            break;
        case JSDPadDirectionUpLeft:
            string = @"Up Left";
            SDL_SendKeyboardText( "y" );
            if( dpadTimer && [dpadTimer isValid] )
            {
                [dpadTimer invalidate];
                dpadTimer = nil;
            }
            dpadTimer = [NSTimer scheduledTimerWithTimeInterval:0.333 target:self selector:@selector(dpadTimerHandler:) userInfo:@{@"Direction": [NSNumber numberWithInteger:JSDPadDirectionUpLeft]} repeats:YES];
            break;
        case JSDPadDirectionUpRight:
            string = @"Up Right";
            SDL_SendKeyboardText( "u" );
            if( dpadTimer && [dpadTimer isValid] )
            {
                [dpadTimer invalidate];
                dpadTimer = nil;
            }
            dpadTimer = [NSTimer scheduledTimerWithTimeInterval:0.333 target:self selector:@selector(dpadTimerHandler:) userInfo:@{@"Direction": [NSNumber numberWithInteger:JSDPadDirectionUpRight]} repeats:YES];
            break;
        case JSDPadDirectionDownLeft:
            string = @"Down Left";
            SDL_SendKeyboardText( "b" );
            if( dpadTimer && [dpadTimer isValid] )
            {
                [dpadTimer invalidate];
                dpadTimer = nil;
            }
            dpadTimer = [NSTimer scheduledTimerWithTimeInterval:0.333 target:self selector:@selector(dpadTimerHandler:) userInfo:@{@"Direction": [NSNumber numberWithInteger:JSDPadDirectionDownLeft]} repeats:YES];
            break;
        case JSDPadDirectionDownRight:
            string = @"Down Right";
            SDL_SendKeyboardText( "n" );
            if( dpadTimer && [dpadTimer isValid] )
            {
                [dpadTimer invalidate];
                dpadTimer = nil;
            }
            dpadTimer = [NSTimer scheduledTimerWithTimeInterval:0.333 target:self selector:@selector(dpadTimerHandler:) userInfo:@{@"Direction": [NSNumber numberWithInteger:JSDPadDirectionDownRight]} repeats:YES];
            break;
        default:
            string = @"NO";
            break;
    }
    
    return string;
}


- (void)dPad:(JSDPad *)dPad didPressDirection:(JSDPadDirection)direction
{
    [longPressGesture setEnabled:NO];
    [self stringForDirection:direction];
    //NSLog(@"Changing direction to: %@", [self stringForDirection:direction]);
    //[self updateDirectionLabel];
    
}

- (void)dPadDidReleaseDirection:(JSDPad *)dpad
{
    //NSLog(@"Releasing DPad");
    //[self updateDirectionLabel];
    [dpadTimer invalidate];
    dpadTimer = nil;
    [longPressGesture setEnabled:YES];
}


#pragma mark - JSButtonDelegate

- (void)buttonPressed:(JSButton *)button
{
    [longPressGesture setEnabled:NO];
    
    
}

- (void)buttonReleased:(JSButton *)button
{
    if ([button isEqual:yesButton])
    {
        SDL_SendKeyboardKey( SDL_PRESSED, SDL_SCANCODE_RETURN );
        SDL_SendKeyboardKey( SDL_RELEASED, SDL_SCANCODE_RETURN );
    }
    else if ([button isEqual:noButton])
    {
        SDL_SendKeyboardKey( SDL_PRESSED, SDL_SCANCODE_ESCAPE );
        SDL_SendKeyboardKey( SDL_RELEASED, SDL_SCANCODE_ESCAPE );
    }
    else if( [button isEqual:prevButton])
    {
        SDL_SendKeyboardText("<");
    }
    else if( [button isEqual:nextButton] )
    {
        SDL_SendKeyboardText(">");
    }
    [longPressGesture setEnabled:YES];
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isKindOfClass:[dPad class]] || [touch.view isKindOfClass:[yesButton class]] )
    {
        return NO;
    }
    
    return YES;
}

-(void)loadKeyBindings
{
    NSString* basePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/"];
    NSString* defaultKeyBindingsPath = [basePath stringByAppendingPathComponent:@"data/raw/keybindings.json"];
    
    
    NSError *e = nil;
    
    
    NSMutableArray* defaultKeyBindings = [NSMutableArray array];
    NSArray *defaultKeyBindingsJSONArray = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:defaultKeyBindingsPath] options:NSJSONReadingMutableContainers error:&e];
    actionDesc = [NSMutableDictionary dictionary];
    if (!defaultKeyBindingsJSONArray) {
        NSLog(@"Error parsing JSON: %@", e);
    } else {
        for(NSDictionary *item in defaultKeyBindingsJSONArray)
        {
            if( [item[@"category"] isEqualToString:@"DEFAULTMODE"] )
            {
                for (NSDictionary* binding in item[@"bindings"])
                {
                    if( [binding[@"input_method"] isEqualToString:@"keyboard"] )
                    {
                        if( actionDesc[ item[@"id"] ] == nil )
                        {
                            actionDesc[ item[@"id"] ] = item[@"name"];
                            
                            //NSLog( @"%@: %@", [NSString stringWithUTF8String:gettext( [item[@"name"] cStringUsingEncoding:NSUTF8StringEncoding] ) ], binding[@"key"] );
                            
                            [defaultKeyBindings addObject:@{@"Title": [NSString stringWithUTF8String:gettext( [item[@"name"] cStringUsingEncoding:NSUTF8StringEncoding] ) ],
                                                            @"Command": binding[@"key"],
                                                            @"Icon": @""}];
                        }
                        
                        
                        continue;
                    }
                }
                
                if( actionDesc[ item[@"id"] ] == nil )
                    actionDesc[ item[@"id"] ] = item[@"name"];
                    
            }
        }
    }
    
    
    
    
    
    
    if( [[NSFileManager defaultManager] fileExistsAtPath:userKeyBindingsPath] )
    {
        userKeyBindings = [NSMutableArray array];
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:userKeyBindingsPath] options:NSJSONReadingMutableContainers error:&e];
        
        if (!jsonArray) {
            NSLog(@"Error parsing JSON: %@", e);
        } else {
            for(NSDictionary *item in jsonArray) {
                
                if( [item[@"category"] isEqualToString:@"DEFAULTMODE"] )
                {
                    //NSLog(@"Item: %@", item);
                    for (NSDictionary* binding in item[@"bindings"])
                    {
                        if( [binding[@"input_method"] isEqualToString:@"keyboard"] )
                        {
                            //input_context::getattrlist(<#const char *#>, <#void *#>, <#void *#>, <#size_t#>, <#unsigned int#>)
                            //NSLog( @"%@: %@", [NSString stringWithUTF8String:gettext( [actionDesc[ item[@"id"] ] cStringUsingEncoding:NSUTF8StringEncoding] ) ], binding[@"key"][0] );
                            [userKeyBindings addObject:@{@"Title": [NSString stringWithUTF8String:gettext( [actionDesc[ item[@"id"] ] cStringUsingEncoding:NSUTF8StringEncoding] ) ],
                                                         @"Command": binding[@"key"][0],
                                                         @"Icon": @""}];
                            continue;
                        }
                    }
                }
            }
        }
    }
    else
    {
        userKeyBindings = [NSMutableArray arrayWithArray:defaultKeyBindings];
    }
    
    NSArray *sorted = [userKeyBindings sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
    {
        NSString* obj1String = obj1[@"Command"];
        NSString* obj2String = obj2[@"Command"];
        return [obj1String compare:obj2String];
    }];
    
    userKeyBindings = [NSMutableArray arrayWithArray:sorted];
   
}
                          
                          
- (void)optionsFileDidChange
{
    NSLog(@"options.txt files changed" );
    
    [self loadKeyBindings];
    
    NSArray* newMenuItems = [self createMenuItems:userKeyBindings];
    //actionsMenu = [[CNPGridMenu alloc] initWithMenuItems:allMenuItems];
    [actionsMenu setMenuItems:newMenuItems];
    //actionsMenu.delegate = self;
    
    [optionsFileWatcher startWatching];
    
}

- (void)keybindingsFileDidChange
{
    NSLog(@"keybindings.json files changed" );
    
    [self loadKeyBindings];
    
    NSArray* newMenuItems = [self createMenuItems:userKeyBindings];
    //actionsMenu = [[CNPGridMenu alloc] initWithMenuItems:allMenuItems];
    [actionsMenu setMenuItems:newMenuItems];
    //actionsMenu.delegate = self;
}

-(void)showIntroductionView
{
    introductionView = [[MYBlurIntroductionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    introductionView.delegate = self;
    [introductionView setBackgroundColor:[UIColor blackColor]];
    
    
    MYIntroductionPanel *panelStory1 = [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"Cataclysm: Dark Days Ahead" description:@"You emerge from the shelter into the dim light of an overcast day, and look around for the first time since the disaster." image:nil];
    MYIntroductionPanel *panelStory2 = [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"Cataclysm: Dark Days Ahead" description:@"The world as you knew it is gone and in its place, a twisted mockery of all that was once familiar." image:nil];
    
    MYIntroductionPanel *panelStory3 = [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"Cataclysm: Dark Days Ahead" description:@"Everything was cast aside in that frantic race for the shelter. You have no food, nothing to drink, no weapons. Nothing but your ingenuity and the fierce determination to survive against appalling odds." image:nil];
    
    MYIntroductionPanel *panelStory4 = [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"Cataclysm: Dark Days Ahead" description:@"A grim prospect faces you. Perhaps worse even than the nightmares of last night, when you were tortured by dreams of the dead themselves rising to jealously tear life from the living." image:nil];
    
    MYIntroductionPanel *panelStory5 = [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"Cataclysm: Dark Days Ahead" description:@"You cast your eyes up the road and begin to walk towards a house in the far distance. Things may be bad right now, but you've got a sinking feeling that there are darker days ahead." image:nil];
    
    MYIntroductionPanel *panelTitle = [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"Cataclysm: Dark Days Ahead" description:nil image:nil];
    
    
    MYIntroductionPanel *panelControlDPad = [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"How To Play" description:@"Use the D-Pad to move your character or cursor." video:@"DPad"];
    
    MYIntroductionPanel *panelControlActionButtons = [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"How To Play" description:@"Use the action buttons to confirm or cancel actions. They work like the RETURN and ESC keys on the keyboard" video:@"ConfirmCancel"];
    
    MYIntroductionPanel *panelControlTabButtons= [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"How To Play" description:@"Use the tab buttons to move to next/previous tab, or descend/ascend stairs. They work like the > and < keys on the keyboard." video:@"TabStair"];
    
    MYIntroductionPanel *panelGesturesSwipeUpAndDown= [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"How To Play" description:@"Swipe up to show the keyboard. Swipe down to hide it." video:@"SwipeUp"];
    
    MYIntroductionPanel *panelGesturesLongPress= [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"How To Play" description:@"Long press empty space to show locked keyboard. It can be used to type long strings." video:@"LongPress"];
    
    MYIntroductionPanel *panelGesturesSwipeRight= [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"How To Play" description:@"Swipe right to show map. It works like pressing m key on the keyboard." video:@"SwipeRight"];
    
    MYIntroductionPanel *panelGesturesSwipeLeft= [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"How To Play" description:@"Swipe left to list all items/creatures around the player. It works like pressing V key on the keyboard." video:@"SwipeLeft"];
    
    MYIntroductionPanel *panelGesturesPause= [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"How To Play" description:@"Single tap to pause character, or keep moving while driving. It works like pressing . key on the keyboard." video:@"PauseDrive"];
    
    MYIntroductionPanel *panelGesturesDoubleSwipe= [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"How To Play" description:@"Two-finger swipe in any directions to show show all the controls. Tap empty space to dismiss." video:@"DoubleSwipe"];
    
    MYIntroductionPanel *panelGesturesTripleSwipe= [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"How To Play" description:@"Three-finger swipe up to increase opacity of the onscreen controls. Three-finger swipe down to decrease the opacity." video:@"3FingersSwipe"];
    
    
    MYIntroductionPanel *panelCredits= [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"Credits" description:@"Original author:    Project Manager:    Website/Forum:\nWhales (retired)    KevinGranade        GlyphGryph\n\nCurrent Main Developers/Github Managers:\nKevinGranade, Rivet-the-Zombie, BevapDin, Coolthulu, i2amroy\n\nCataclysm:Dark Days Ahead is the result of contributions from over 300 volunteers. You can download compiled versions of Cataclysm DDA for Linux, Mac and Windows systems for free at http://en.cataclysmdda.com\n\nFor a full list of contributors please see:\nhttps://github.com/CleverRaven/Cataclysm-DDA/contributors\nCataclysm: Dark Days Ahead is released under CC-BY-SA 3.0." image:nil];
    
    
    MYIntroductionPanel *panelChangeLanguage= [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"How To Change Language" description:@"Go to Options->Interface->Language to change language." video:@"ChangeLanguage"];
    
    MYIntroductionPanel *panelChangeTileSet= [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"How To Change Tileset" description:@"Go to Options->Interface->Graphics->Choose tileset to change tileset." video:@"ChangeTileset"];
    
    MYIntroductionPanel *panelBeta1= [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"About iOS Version" description:@"This beta version is brought you by Dancing Bottle.\n\nPlease report bugs/issues in the forum at http://dancingbottle.com/" image:nil];
    
    
    //[introductionView setBackgroundColor:[UIColor blackColor]];
    
    [introductionView buildIntroductionWithPanels:@[ //panelStory1,
                                                     //panelStory2,
                                                     //panelStory3,
                                                     //panelStory4,
                                                     //panelStory5,
                                                     //panelTitle,
                                                     panelControlActionButtons,
                                                     panelControlTabButtons,
                                                     panelControlDPad,
                                                     panelGesturesSwipeUpAndDown,
                                                     panelGesturesLongPress,
                                                     panelGesturesSwipeRight,
                                                     panelGesturesSwipeLeft,
                                                     panelGesturesPause,
                                                     panelGesturesDoubleSwipe,
                                                     panelGesturesTripleSwipe,
                                                     panelChangeLanguage,
                                                     panelChangeTileSet,
                                                     panelCredits,
                                                     panelBeta1 ]];
    [self.view addSubview:introductionView];

}



#pragma mark - MYIntroductionDelegate Methods
-(void)introduction:(MYBlurIntroductionView *)introductionView didFinishWithType:(MYFinishType)finishType
{
    [self doVolumeFade1];
    
    
    [soundPlayer play];
    
    //[self doVolumeFade2];
    
    SDL_WindowData *data = self->window->driverdata;
    SDL_VideoDisplay *display = SDL_GetDisplayForWindow(self->window);
    SDL_DisplayModeData *displaymodedata = (SDL_DisplayModeData *) display->current_mode.driverdata;
    const CGSize size = data->view.bounds.size;
    int w, h;
    
    w = (int)(size.width * displaymodedata->scale);
    h = (int)(size.height * displaymodedata->scale);
    
    SDL_SendWindowEvent(self->window, SDL_WINDOWEVENT_EXPOSED, w, h);
}

-(void)introduction:(MYBlurIntroductionView *)introductionView didChangeToPanel:(MYIntroductionPanel *)panel withIndex:(NSInteger)panelIndex
{
    
}


@end

#endif /* SDL_VIDEO_DRIVER_UIKIT */

/* vi: set ts=4 sw=4 expandtab: */
