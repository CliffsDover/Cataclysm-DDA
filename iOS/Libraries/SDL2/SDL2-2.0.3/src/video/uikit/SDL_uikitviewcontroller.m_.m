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

    JSDPad *dPad;
    JSButton* yesButton;
    JSButton* noButton;
    JSButton* nextButton;
    JSButton* prevButton;
    JSButton* settingsButton;
    
    NSTimer* dpadTimer;
    
    NSMutableDictionary* actionDesc;
    NSMutableArray* userKeyBindings;
    
    DDMenu* dropDownMenu;
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
    
    
    
    [self loadKeyBindings];
  
    NSArray* allMenuItems = [self createMenuItems:userKeyBindings];
    actionsMenu = [[CNPGridMenu alloc] initWithMenuItems:allMenuItems];
    actionsMenu.delegate = self;
    
    return self;
}

- (void)loadView
{
    /* do nothing. */
}

-(void)showActionsMenu
{
    NSMutableArray* allMenuItems = [NSMutableArray array];
    
    CNPGridMenuItem* menuItem = [[CNPGridMenuItem alloc] init];
    menuItem.icon = [UIImage imageNamed:@"Icon_Info"];
    menuItem.title = @"Infomations";
    menuItem.selectionHandler = ^(CNPGridMenuItem* menuItem){
        [self ShowInfoMenu];
    };
    [allMenuItems addObject:menuItem];
    
    
    
    menuItem = [[CNPGridMenuItem alloc] init];
    menuItem.icon = [UIImage imageNamed:@"Icon_Environment"];
    menuItem.title = @"Environment";
    menuItem.selectionHandler = ^(CNPGridMenuItem* menuItem){
        [self ShowEnvironmentActionsMenu];
    };
    [allMenuItems addObject:menuItem];
    
    
    
    menuItem = [[CNPGridMenuItem alloc] init];
    menuItem.icon = [UIImage imageNamed:@"Icon_Special"];
    menuItem.title = @"Special";
    menuItem.selectionHandler = ^(CNPGridMenuItem* menuItem){
        [self showSpecialActionsMenu];
    };
    [allMenuItems addObject:menuItem];
    
    
    
    
    menuItem = [[CNPGridMenuItem alloc] init];
    menuItem.icon = [UIImage imageNamed:@"Icon_Inventory"];
    menuItem.title = @"Inventory";
    menuItem.selectionHandler = ^(CNPGridMenuItem* menuItem){
        [self showInventoryActionsMenu];
    };
    [allMenuItems addObject:menuItem];
    
    
    
    
    menuItem = [[CNPGridMenuItem alloc] init];
    menuItem.icon = [UIImage imageNamed:@"Icon_Attack"];
    menuItem.title = @"Attack";
    menuItem.selectionHandler = ^(CNPGridMenuItem* menuItem){
        [self showAttackActionsMenu];
    };
    [allMenuItems addObject:menuItem];
    
    
    
    menuItem = [[CNPGridMenuItem alloc] init];
    menuItem.icon = [UIImage imageNamed:@"Icon_Build"];
    menuItem.title = @"Craft/Construct";
    menuItem.selectionHandler = ^(CNPGridMenuItem* menuItem){
        [self showBuildActionsMenu];
    };
    [allMenuItems addObject:menuItem];
    
    
    
    [actionsMenu setMenuItems:allMenuItems];

    [self presentGridMenu:actionsMenu animated:YES completion:^{
        NSLog(@"Grid Menu Presented");
    }];
}


-(void)showAttackActionsMenu
{
    NSArray* menuItems = @[
                           @{ @"Title": @"Fire",
                              @"Command": @"f",
                              @"Icon": @"Icon_Attack_Fire" },
                           @{ @"Title": @"Reload",
                              @"Command": @"r",
                              @"Icon": @"Icon_Attack_Reload" },
                           @{ @"Title": @"Wield",
                              @"Command": @"w",
                              @"Icon": @"Icon_Attack_Wield" },
                           @{ @"Title": @"Toggle Mode",
                              @"Command": @"F",
                              @"Icon": @"Icon_Attack_Toggle" },
                           @{ @"Title": @"Unarmed Style",
                              @"Command": @"_",
                              @"Icon": @"Icon_Attack_Unarmed" },
                           ];
    
    NSArray* allMenuItems = [self createMenuItems:menuItems];
    
    [actionsMenu setMenuItems:allMenuItems];
    [self presentGridMenu:actionsMenu animated:YES completion:^{
        NSLog(@"Grid Menu Presented");
    }];
}

-(void)showSpecialActionsMenu
{
    NSArray* menuItems = @[
                           @{ @"Title": @"Wait",
                              @"Command": @"|",
                              @"Icon": @"Icon_Special_Wait" },
                           
                           @{ @"Title": @"Sleep",
                              @"Command": @"$",
                              @"Icon": @"Icon_Special_Sleep" },
                           
                           @{ @"Title": @"Toggle SafeMode",
                              @"Command": @"!",
                              @"Icon": @"Icon_Special_ToggleSaveMode" },
                           
                           @{ @"Title": @"Toggle AutoSafe",
                              @"Command": @"\"",
                              @"Icon": @"Icon_Special_ToggleAutoSafe" },
                           
                           @{ @"Title": @"Ignore Enemy",
                              @"Command": @"'",
                              @"Icon": @"Icon_Special_IgnoreEnemy" },
                           
                           @{ @"Title": @"Save",
                              @"Command": @"S",
                              @"Icon": @"Icon_Special_Save" },
                           
                           @{ @"Title": @"Suicide",
                              @"Command": @"Q",
                              @"Icon": @"Icon_Special_Suicide" },
                           
                           @{ @"Title": @"Toggle Debug",
                              @"Command": @"~",
                              @"Icon": @"Icon_Special_Suicide" },
                           
                           @{ @"Title": @"Debug Menu",
                              @"Command": @"`",
                              @"Icon": @"Icon_Special_Suicide" },
                           ];

    NSArray* allMenuItems = [self createMenuItems:menuItems];
    
    [actionsMenu setMenuItems:allMenuItems];
    [self presentGridMenu:actionsMenu animated:YES completion:^{
        NSLog(@"Grid Menu Presented");
    }];
}


-(void)showBuildActionsMenu
{
    NSArray* menuItems = @[
                           @{ @"Title": @"Craft",
                              @"Command": @"&",
                              @"Icon": @"Icon_Build_Craft" },
                           @{ @"Title": @"Re-craft",
                              @"Command": @"-",
                              @"Icon": @"Icon_Build_Recraft" },
                           @{ @"Title": @"Construct",
                              @"Command": @"*",
                              @"Icon": @"Icon_Build_Construct" },
                           ];
    
    NSArray* allMenuItems = [self createMenuItems:menuItems];
    
    [actionsMenu setMenuItems:allMenuItems];
    [self presentGridMenu:actionsMenu animated:YES completion:^{
        NSLog(@"Grid Menu Presented");
    }];
}



-(void)showInventoryActionsMenu
{
    NSArray* menuItems = @[
                           @{ @"Title": @"View Inventory",
                              @"Command": @"i",
                              @"Icon": @"Icon_Inventory_View" },
                           
                           @{ @"Title": @"Compare",
                              @"Command": @"I",
                              @"Icon": @"Icon_Inventory_Compare" },
                           
//                           @{ @"Title": @"Swap Letters",
//                              @"Command": @"=",
//                              @"Icon": @"Icon_Inventory_Swap" },
                           
                           @{ @"Title": @"Apply/Use Item",
                              @"Command": @"a",
                              @"Icon": @"Icon_Inventory_Use" },
                           
                           @{ @"Title": @"Apply/Use Wielded",
                              @"Command": @"A",
                              @"Icon": @"Icon_Inventory_Use_Wielded" },
                           
                           @{ @"Title": @"Wear",
                              @"Command": @"W",
                              @"Icon": @"Icon_Inventory_Wear" },
                           
                           @{ @"Title": @"Take Off",
                              @"Command": @"T",
                              @"Icon": @"Icon_Inventory_TakeOff" },
                           
                           @{ @"Title": @"Eat/Drink/Consume",
                              @"Command": @"E",
                              @"Icon": @"Icon_Inventory_Eat" },
                           
                           @{ @"Title": @"Read",
                              @"Command": @"R",
                              @"Icon": @"Icon_Inventory_Read" },
                           
                           @{ @"Title": @"Wield",
                              @"Command": @"w",
                              @"Icon": @"Icon_Inventory_Wield" },
                           
                           @{ @"Title": @"Reload",
                              @"Command": @"r",
                              @"Icon": @"Icon_Inventory_Reload" },
                           
                           ];
    
    NSArray* allMenuItems = [self createMenuItems:menuItems];
    
    [actionsMenu setMenuItems:allMenuItems];
    [self presentGridMenu:actionsMenu animated:YES completion:^{
        NSLog(@"Grid Menu Presented");
    }];
}

-(void)ShowEnvironmentActionsMenu
{
    NSArray* menuItems = @[
                           @{ @"Title": @"Open",
                              @"Command": @"o",
                              @"Icon": @"Icon_Environment_Open" },
                           @{ @"Title": @"Close",
                              @"Command": @"c",
                              @"Icon": @"Icon_Environment_Close" },
                           @{ @"Title": @"Smash",
                              @"Command": @"s",
                              @"Icon": @"Icon_Environment_Smash" },
                           @{ @"Title": @"Examine",
                              @"Command": @"e",
                              @"Icon": @"Icon_Environment_Examine" },
                           @{ @"Title": @"Pick",
                              @"Command": @"g",
                              @"Icon": @"Icon_Environment_Pick" },
                           @{ @"Title": @"Grab",
                              @"Command": @"G",
                              @"Icon": @"Icon_Environment_Grab" },
                           @{ @"Title": @"Butcher",
                              @"Command": @"B",
                              @"Icon": @"Icon_Environment_Butcher" },
//                           @{ @"Title": @"Chat",
//                              @"Command": @"C",
//                              @"Icon": @"Icon_Environment_Chat" },
                           @{ @"Title": @"Look",
                              @"Command": @"x",
                              @"Icon": @"Icon_Environment_Look" },
                           @{ @"Title": @"Peek",
                              @"Command": @"X",
                              @"Icon": @"Icon_Environment_Peek" },
                           @{ @"Title": @"List All",
                              @"Command": @"V",
                              @"Icon": @"Icon_Environment_List" },
                           ];
    
    
    NSArray* allMenuItems = [self createMenuItems:menuItems];
    
    [actionsMenu setMenuItems:allMenuItems];
    [self presentGridMenu:actionsMenu animated:YES completion:^{
        NSLog(@"Grid Menu Presented");
    }];
}

-(NSArray*)createMenuItems:(NSArray*)items
{
    NSMutableArray* allMenuItems = [NSMutableArray array];
    for (NSDictionary* item in items )
    {
        CNPGridMenuItem *menuItem = [[CNPGridMenuItem alloc] init];
        //menuItem.icon = [UIImage imageNamed:item[@"Icon"]];
        //menuItem.icon = [self imageFromText:item[@"Command"] width:40 height:40];
        menuItem.icon = [self imageWithText:item[@"Command"] fontSize:40 rectSize:CGSizeMake(40, 40)];
        menuItem.title = item[@"Title"];
        menuItem.selectionHandler = ^(CNPGridMenuItem* menuItem){
            SDL_SendKeyboardText( [item[@"Command"] cStringUsingEncoding:NSASCIIStringEncoding] );
            [actionsMenu dismissGridMenuAnimated:YES completion:nil];
        };
        [allMenuItems addObject:menuItem];
    }
    return [NSArray arrayWithArray:allMenuItems];
}

-(void)ShowInfoMenu
{
    NSArray* menuItems = @[
                           @{ @"Title": @"Player",
                              @"Command": @"@",
                              @"Icon": @"Icon_Info_Player" },
                           @{ @"Title": @"Map",
                              @"Command": @"m",
                              @"Icon": @"Icon_Info_Map" },
                           @{ @"Title": @"Missions",
                              @"Command": @"M",
                              @"Icon": @"Icon_Info_Missions" },
                           @{ @"Title": @"Factions",
                              @"Command": @"#",
                              @"Icon": @"Icon_Info_Factions" },
                           @{ @"Title": @"Kill Count",
                              @"Command": @")",
                              @"Icon": @"Icon_Info_KillCount" },
                           @{ @"Title": @"Morale",
                              @"Command": @"v",
                              @"Icon": @"Icon_Info_Morale" },
                           @{ @"Title": @"Message Lob",
                              @"Command": @"P",
                              @"Icon": @"Icon_Info_MessageLog" },
                           @{ @"Title": @"Help",
                              @"Command": @"?",
                              @"Icon": @"Icon_Info_Help" }
                           ];
    
    //NSArray* allMenuItems = [self createMenuItems:menuItems];
    //NSArray* allMenuItems = [self createMenuItems:userKeyBindings];

    //[actionsMenu setMenuItems:allMenuItems];
    [self presentGridMenu:actionsMenu animated:YES completion:^{
        NSLog(@"Grid Menu Presented");
    }];
    
}

- (void)gridMenuDidTapOnBackground:(CNPGridMenu *)menu {
    [self dismissGridMenuAnimated:YES completion:^{
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

-(void)MenuTouched:(id)sender
{
    UIButton* button = (UIButton*)sender;
    switch ( button.tag )
    {
        case MENU_KEYBOARD:
            if( SDL_IsScreenKeyboardShown( SDL_GetFocusWindow() ) )
                SDL_StopTextInput();
            else
                SDL_StartTextInput();
            break;
            
        case MENU_INFO:
            [self ShowInfoMenu];
            break;
            
        case MENU_ACTION:
            [self ShowEnvironmentActionsMenu];
            break;
            
        case MENU_ATTACK:
            [self showAttackActionsMenu];
            break;
            
        case MENU_INVENTORY:
            [self showInventoryActionsMenu];
            break;
            
        case MENU_ADV_INVENTORY:
            NSLog( @"case MENU_ADV_INVENTORY not implemented yet.");
            break;
            
        case MENU_SPECIAL:
            [self showSpecialActionsMenu];
            break;
            
        case MENU_BUILD:
            [self showBuildActionsMenu];
            break;
            
            
        default:
            break;
    }
}

-(void)TouchUpInside:(id)sender
{
    UIButton* button = (UIButton*)sender;
    switch ( button.tag )
    {
        case 1000:
            SDL_SendKeyboardKey( SDL_PRESSED, SDL_SCANCODE_LEFT );
            SDL_SendKeyboardKey( SDL_RELEASED, SDL_SCANCODE_LEFT );
            break;
        case 1001:
            SDL_SendKeyboardKey( SDL_PRESSED, SDL_SCANCODE_RIGHT );
            SDL_SendKeyboardKey( SDL_RELEASED, SDL_SCANCODE_RIGHT );
            break;
        case 1002:
            SDL_SendKeyboardKey( SDL_PRESSED, SDL_SCANCODE_UP );
            SDL_SendKeyboardKey( SDL_RELEASED, SDL_SCANCODE_UP );
            break;
        case 1003:
            SDL_SendKeyboardKey( SDL_PRESSED, SDL_SCANCODE_DOWN );
            SDL_SendKeyboardKey( SDL_RELEASED, SDL_SCANCODE_DOWN );
            break;
        case 1004:
            SDL_SendKeyboardKey( SDL_PRESSED, SDL_SCANCODE_RETURN );
            SDL_SendKeyboardKey( SDL_RELEASED, SDL_SCANCODE_RETURN );
            
            break;
        case 1005:
            SDL_SendKeyboardKey( SDL_PRESSED, SDL_SCANCODE_ESCAPE );
            SDL_SendKeyboardKey( SDL_RELEASED, SDL_SCANCODE_ESCAPE );
            
            break;

        case 1006:
            SDL_SendKeyboardText("<");
            break;
            
        case 1007:
            SDL_SendKeyboardText( ">" );
            break;

        default:
            break;
    }
    
    NSLog(@"TouchUpInside");
}

- (void)viewDidLayoutSubviews
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
    
    
    UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    panGesture.minimumNumberOfTouches = 2;
    panGesture.maximumNumberOfTouches = 3;
    panGesture.delegate = self;
    [self.view addGestureRecognizer:panGesture];
    
    
    
    
    UIButton* button;
//    UIButton* button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//    button.frame = CGRectMake(16, 32+200, 48, 48);
//    [button setTitle:@"L" forState:UIControlStateNormal];
//    [button setBackgroundColor:[UIColor grayColor]];
//    [button setAlpha:0.5];
//    [self.view addSubview:button];
//    [button setTag:1000];
//    [button addTarget:self
//                   action:@selector(TouchUpInside:)
//         forControlEvents: UIControlEventTouchDown];
//    
//    
//    button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//    button.frame = CGRectMake(96+16, 32+200, 48, 48);
//    [button setTitle:@"R" forState:UIControlStateNormal];
//    [button setBackgroundColor:[UIColor grayColor]];
//    [button setAlpha:0.5];
//    [self.view addSubview:button];
//    [button setTag:1001];
//    [button addTarget:self
//               action:@selector(TouchUpInside:)
//     forControlEvents: UIControlEventTouchDown];
//    
//    
//    button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//    button.frame = CGRectMake(48+16, -16+200, 48, 48);
//    [button setTitle:@"U" forState:UIControlStateNormal];
//    [button setBackgroundColor:[UIColor grayColor]];
//    [button setAlpha:0.5];
//    [self.view addSubview:button];
//    [button setTag:1002];
//    [button addTarget:self
//               action:@selector(TouchUpInside:)
//     forControlEvents: UIControlEventTouchDown];
//    
//    
//    button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//    button.frame = CGRectMake(48+16, 80+200, 48, 48);
//    [button setTitle:@"D" forState:UIControlStateNormal];
//    [button setBackgroundColor:[UIColor grayColor]];
//    [button setAlpha:0.5];
//    [self.view addSubview:button];
//    [button setTag:1003];
//    [button addTarget:self
//               action:@selector(TouchUpInside:)
//     forControlEvents: UIControlEventTouchDown];
    
    
    
    button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(450, 32+200, 32, 32);
    [button setTitle:@"A" forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor grayColor]];
    [button setAlpha:0.5];
    //[self.view addSubview:button];
    [button setTag:1004];
    [button addTarget:self
               action:@selector(TouchUpInside:)
     forControlEvents: UIControlEventTouchUpInside];
    
    noButton = [[JSButton alloc] initWithFrame:CGRectMake(450-32, 232+16, 64, 64)];
    //[[yesButton titleLabel] setText:@"Next"];
    [noButton setBackgroundImage:[UIImage imageNamed:@"No"]];
    [noButton setBackgroundImagePressed:[UIImage imageNamed:@"No_Touched"]];
    noButton.delegate = self;
    [self.view addSubview:noButton];
    
    
    button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(64+450, 32+200, 32, 32);
    [button setTitle:@"B" forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor grayColor]];
    [button setAlpha:0.5];
    //[self.view addSubview:button];
    [button setTag:1005];
    [button addTarget:self
               action:@selector(TouchUpInside:)
     forControlEvents: UIControlEventTouchUpInside];
    
    yesButton = [[JSButton alloc] initWithFrame:CGRectMake(514-16, 232+16, 64, 64)];
    //[[noButton titleLabel] setText:@"Prev"];
    [yesButton setBackgroundImage:[UIImage imageNamed:@"Yes"]];
    [yesButton setBackgroundImagePressed:[UIImage imageNamed:@"Yes_Touched"]];
    yesButton.delegate = self;
    [self.view addSubview:yesButton];
    
    
    
    
    button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(450, -32+200, 32, 32);
    [button setTitle:@"<" forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor grayColor]];
    [button setAlpha:0.5];
    //[self.view addSubview:button];
    [button setTag:1006];
    [button addTarget:self
               action:@selector(TouchUpInside:)
     forControlEvents: UIControlEventTouchUpInside];
    
    prevButton = [[JSButton alloc] initWithFrame:CGRectMake(450-32, 168+16, 64, 64)];
    //[[yesButton titleLabel] setText:@"Next"];
    [prevButton setBackgroundImage:[UIImage imageNamed:@"Prev"]];
    [prevButton setBackgroundImagePressed:[UIImage imageNamed:@"Prev_Touched"]];
    prevButton.delegate = self;
    [self.view addSubview:prevButton];
    
    
    button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(64+450, -32+200, 32, 32);
    [button setTitle:@">" forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor grayColor]];
    [button setAlpha:0.5];
    //[self.view addSubview:button];
    [button setTag:1007];
    [button addTarget:self
               action:@selector(TouchUpInside:)
     forControlEvents: UIControlEventTouchUpInside];
    
    nextButton = [[JSButton alloc] initWithFrame:CGRectMake(514-16, 168+16, 64, 64)];
    //[[yesButton titleLabel] setText:@"Next"];
    [nextButton setBackgroundImage:[UIImage imageNamed:@"Next"]];
    [nextButton setBackgroundImagePressed:[UIImage imageNamed:@"Next_Touched"]];
    nextButton.delegate = self;
    [self.view addSubview:nextButton];
    
    
    
    settingsButton = [[JSButton alloc] initWithFrame:CGRectMake(8, 8, 32, 32)];
    //[[yesButton titleLabel] setText:@"Next"];
    [settingsButton setBackgroundImage:[UIImage imageNamed:@"Next"]];
    [settingsButton setBackgroundImagePressed:[UIImage imageNamed:@"Next_Touched"]];
    settingsButton.delegate = self;
    //[self.view addSubview:settingsButton];
    
    
    
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeSystem];
    button1.tag = MENU_KEYBOARD;
    button1.translatesAutoresizingMaskIntoConstraints = NO;
    [button1 setTitle:@"Btn1" forState:UIControlStateNormal];
    [button1 addTarget:self
               action:@selector(MenuTouched:)
     forControlEvents: UIControlEventTouchUpInside];
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeSystem];
    button2.tag = MENU_INFO;
    button2.translatesAutoresizingMaskIntoConstraints = NO;
    [button2 setTitle:@"Btn2" forState:UIControlStateNormal];
    [button2 addTarget:self
                action:@selector(MenuTouched:)
      forControlEvents: UIControlEventTouchUpInside];
    
    UIButton *button3 = [UIButton buttonWithType:UIButtonTypeSystem];
    button3.tag = MENU_ACTION;
    button3.translatesAutoresizingMaskIntoConstraints = NO;
    [button3 setTitle:@"Btn3" forState:UIControlStateNormal];
    [button3 addTarget:self
                action:@selector(MenuTouched:)
      forControlEvents: UIControlEventTouchUpInside];
    
    UIButton *button4 = [UIButton buttonWithType:UIButtonTypeSystem];
    button4.tag = MENU_ATTACK;
    button4.translatesAutoresizingMaskIntoConstraints = NO;
    [button4 setTitle:@"Btn4" forState:UIControlStateNormal];
    [button4 addTarget:self
                action:@selector(MenuTouched:)
      forControlEvents: UIControlEventTouchUpInside];
    
    UIButton *button5 = [UIButton buttonWithType:UIButtonTypeSystem];
    button5.translatesAutoresizingMaskIntoConstraints = NO;
    button5.tag = MENU_INVENTORY;
    [button5 setTitle:@"Btn5" forState:UIControlStateNormal];
    [button5 addTarget:self
                action:@selector(MenuTouched:)
      forControlEvents: UIControlEventTouchUpInside];
    
    UIButton *button6 = [UIButton buttonWithType:UIButtonTypeSystem];
    button6.tag = MENU_ADV_INVENTORY;
    button6.translatesAutoresizingMaskIntoConstraints = NO;
    [button6 setTitle:@"Btn6" forState:UIControlStateNormal];
    [button6 addTarget:self
                action:@selector(MenuTouched:)
      forControlEvents: UIControlEventTouchUpInside];
    
    UIButton *button7 = [UIButton buttonWithType:UIButtonTypeSystem];
    button7.tag = MENU_BUILD;
    button7.translatesAutoresizingMaskIntoConstraints = NO;
    [button7 setTitle:@"Btn7" forState:UIControlStateNormal];
    [button7 addTarget:self
                action:@selector(MenuTouched:)
      forControlEvents: UIControlEventTouchUpInside];
    
    UIButton *button8 = [UIButton buttonWithType:UIButtonTypeSystem];
    button8.tag = MENU_SPECIAL;
    button8.translatesAutoresizingMaskIntoConstraints = NO;
    [button8 setTitle:@"Btn8" forState:UIControlStateNormal];
    [button8 addTarget:self
                action:@selector(MenuTouched:)
      forControlEvents: UIControlEventTouchUpInside];
    
//    [self.view addSubview:button1];
//    [self.view addSubview:button2];
//    [self.view addSubview:button3];
//    [self.view addSubview:button4];
//    [self.view addSubview:button5];
//    [self.view addSubview:button6];
//    [self.view addSubview:button7];
//    [self.view addSubview:button8];
    
    
//    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:button1 attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
//    
//    NSDictionary *views = NSDictionaryOfVariableBindings(button1, button2, button3, button4, button5, button6, button7, button8);
//    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[button1][button2(==button1)][button3(==button1)][button4(==button1)][button5(==button1)][button6(==button1)][button7(==button1)][button8(==button1)]|" options:NSLayoutFormatAlignAllTop metrics:nil views:views]];


    UIPinchGestureRecognizer* pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    [self.view addGestureRecognizer:pinchGestureRecognizer];
    
    
    
    dPad = [[JSDPad alloc] initWithFrame:CGRectMake(8, self.view.bounds.size.height - 8 - 144, 144, 144)];
    dPad.delegate = self;
    [self.view addSubview:dPad];
    
    
    DDMenuItem *item1 = [[DDMenuItem alloc]initMenuItemWithTitle:@"SectionA" icon:[self imageWithText:@"A" fontSize:40 rectSize:CGSizeMake(40, 40)] withCompletionHandler:^(BOOL finished){
        
    }];
    dropDownMenu = [[DDMenu alloc] initWithItems:@[item1,item1,item1,item1,item1] textColor:[UIColor lightGrayColor] hightLightTextColor:[UIColor whiteColor] backgroundColor:[UIColor blackColor] forViewController:self];
    
    
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
    NSLog( @"Single Tapped" );
    SDL_SendKeyboardText( "." );
}


- (void) handleSwipe:(UISwipeGestureRecognizer*)gesture
{
    NSLog( @"Double Swipe: %lu", (unsigned long)gesture.direction );
    
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
            SDL_StopTextInput();
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
    NSLog( @"%lu %f", (unsigned long)gesture.numberOfTouches, [gesture translationInView:self.view].y );
    
    
    if( 2 == gesture.numberOfTouches )
    {
        //[self presentGridMenu:actionsMenu animated:YES completion:nil];
        [dropDownMenu showMenu];

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
        settingsButton.alpha = alpha;

    }
    
    
    [gesture setTranslation:CGPointMake(0, 0) inView:self.view];
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

-(UIImage *)imageFromText:(NSString *)text width:(float)width height:(float)height
{
    // set the font type and size
    UIFont *font = [UIFont systemFontOfSize:24.0];
    CGSize size  = CGSizeMake(width, height);// [text sizeWithFont:font];
    
    // check if UIGraphicsBeginImageContextWithOptions is available (iOS is 4.0+)
    //if (UIGraphicsBeginImageContextWithOptions != NULL)
        UIGraphicsBeginImageContextWithOptions(size,NO,0.0);
    //else
        // iOS is < 4.0
    //    UIGraphicsBeginImageContext(size);
    
    // optional: add a shadow, to avoid clipping the shadow you should make the context size bigger
    
//    CGContextRef ctx = UIGraphicsGetCurrentContext();
//    CGContextSetShadowWithColor(ctx, CGSizeMake(1.0, 1.0), 5.0, [[UIColor grayColor] CGColor]);
    
    // draw in context, you can use  drawInRect/drawAtPoint:withFont:
    //[text drawAtPoint:CGPointMake(0.0, 0.0) withFont:font];
    //[text drawInRect:CGRectMake(0, 0, width, height) withFont:font];
    [text drawInRect:CGRectMake(0, 0, width, height) withAttributes:@{NSFontAttributeName:font, NSForegroundColorAttributeName:[UIColor whiteColor]}];
    //[text drawAtPoint:CGPointMake(1.0, 8.0) withAttributes:@{NSFontAttributeName:font}];
    
    // transfer image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    [image retain];
    UIGraphicsEndImageContext();
    
    return image;
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
    NSLog( @"dpadTimerHandler" );
    
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
    NSLog(@"Changing direction to: %@", [self stringForDirection:direction]);
    //[self updateDirectionLabel];
}

- (void)dPadDidReleaseDirection:(JSDPad *)dpad
{
    NSLog(@"Releasing DPad");
    //[self updateDirectionLabel];
    [dpadTimer invalidate];
    dpadTimer = nil;
}


#pragma mark - JSButtonDelegate

- (void)buttonPressed:(JSButton *)button
{
    
    
    
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
                            
                            NSLog( @"%@: %@", [NSString stringWithUTF8String:gettext( [item[@"name"] cStringUsingEncoding:NSUTF8StringEncoding] ) ], binding[@"key"] );
                            
                            [defaultKeyBindings addObject:@{@"Title": [NSString stringWithUTF8String:gettext( [item[@"name"] cStringUsingEncoding:NSUTF8StringEncoding] ) ],
                                                            @"Command": binding[@"key"],
                                                            @"Icon": @""}];
                        }
                        
                        
                        continue;
                    }
                }
            }
        }
    }
    
    
    
    
    NSString* documentPath = [[[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] path] stringByAppendingString:@"/"];
    
    
    
    NSString* userKeyBindingsPath = [documentPath stringByAppendingPathComponent:@"keybindings.json"];
    
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
                            NSLog( @"%@: %@", [NSString stringWithUTF8String:gettext( [actionDesc[ item[@"id"] ] cStringUsingEncoding:NSUTF8StringEncoding] ) ], binding[@"key"][0] );
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

@end

#endif /* SDL_VIDEO_DRIVER_UIKIT */

/* vi: set ts=4 sw=4 expandtab: */
