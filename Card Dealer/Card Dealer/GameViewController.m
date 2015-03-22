//
//  GameViewController.m
//  Card Dealer
//
//  Created by Christopher Fuentes on 3/21/15.
//  Copyright (c) 2015 Christopher Fuentes. All rights reserved.
//

#import "GameViewController.h"
#import "CardHandCell.h"
#import "Constants.h"
#import "Player.h"
#import "Game.h"

typedef NS_ENUM(short, TableSections) {
    kTableSectionCommunity,
    kTableSectionPlayers
};

@interface GameViewController ()

@end

@implementation GameViewController
static const NSArray *GAME_RULES_OPTIONS;
static const NSArray *GAME_RULES_OPTION_NAMES;

+ (void)initialize {
    /* Define the set of rule choices for the user */
    GAME_RULES_OPTIONS = [@[ [RuleSet texasHoldemRules], [RuleSet fiveCardStudRules] ] retain];
    
    /* Get a corresponding array of the names of those rulesets, e.g. "Texas Hold'em" */
    NSMutableArray *gameNames = [NSMutableArray arrayWithCapacity:GAME_RULES_OPTIONS.count];
    for (RuleSet *ruleSet in GAME_RULES_OPTIONS) {
        [gameNames addObject:ruleSet.name];
    }
    
    GAME_RULES_OPTION_NAMES = [[NSArray arrayWithArray:gameNames] retain];
}

#pragma mark - UIViewController LifeCycle
- (void)viewDidLoad {
    [super viewDidLoad];
    _gameInfoTable.dataSource   = self;
    _gameInfoTable.delegate     = self;
    
    /* Register our custom cell with the table for displaying cards */
    [_gameInfoTable registerNib:[UINib nibWithNibName:CARD_HAND_CELL_NIB_NAME bundle:nil]
         forCellReuseIdentifier:CARD_HAND_CELL_ID];
}


#pragma mark - UITableViewDelegate/Datasource methods

/* One row for each player + 1 row for the  */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([[Game sharedGame] hasCommunityPool]) {
        switch (section) {
                HANDLE_CASE(kTableSectionCommunity, 1);
                HANDLE_CASE(kTableSectionPlayers,   [Game sharedGame].players.count);
            default:
                NSAssert(NO, @"Unhandled section for table: %ld", (long)section);
                return 0;
                break;
        }
    } else {
        return [Game sharedGame].players.count;
    }
}

/* There are up to two sections: Community Card section (if any), and player section*/
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([[Game sharedGame] hasCommunityPool]) {
        return 2;
    } else {
        return 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([[Game sharedGame] hasCommunityPool]) {
        switch (section) {
                HANDLE_CASE(kTableSectionPlayers,   PLAYER_HANDS_SECTION_TITLE);
                HANDLE_CASE(kTableSectionCommunity, COMMUNITY_POOL_SECTION_TITLE);
                
            default:
                NSAssert(NO, @"Unhandled section for table: %ld", (long)section);
                return nil;
                break;
        }
    } else {
        return PLAYER_HANDS_SECTION_TITLE;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CardHandCell *cell = [tableView dequeueReusableCellWithIdentifier:CARD_HAND_CELL_ID];
    if (!cell) {
        cell = [[[CardHandCell alloc] initWithStyle:UITableViewCellStyleDefault
                                    reuseIdentifier:CARD_HAND_CELL_ID] autorelease];
    }
    
    if ([[Game sharedGame] hasCommunityPool] && indexPath.section == kTableSectionCommunity) {
        cell.playerNameLabel.text = COMMUNITY_CARDS_CELL_TITLE;
        [cell fillFromCards:[Game sharedGame].communityCards];
    } else {
        /* Since index path row is 0 indexed, we can add 1 to get a more natural looking enumeration. */
        cell.playerNameLabel.text   = [NSString stringWithFormat:@"Player %ld", indexPath.row + 1];
        Player *player              = [Game sharedGame].players[indexPath.row];
        [cell fillFromCards:player.hand];
    }
    
    return cell;
}

#pragma mark - UIAlertView Delegate Methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        /* Canel button, do nothing */
    } else {
        /* Get the corresponding RuleSet and start a new game */
        RuleSet *rules = GAME_RULES_OPTIONS[buttonIndex - 1];
        [[Game sharedGame] newGame:rules];
        [_gameInfoTable reloadData];
        
        _gameInfoTable.hidden = NO;
    }
}

/* Deal a new round */
- (IBAction)dealRoundPressed:(id)sender {
    [[Game sharedGame] dealRound];
    [_gameInfoTable reloadData];
}

#pragma mark - Button Actions
- (IBAction)newGamePressed:(id)sender {
    UIAlertView *av = [[[UIAlertView alloc] initWithTitle:CHOOSE_GAME_ALERT_TITLE
                                                 message:CHOOSE_GAME_ALERT_MESSAGE
                                                delegate:self
                                       cancelButtonTitle:CHOOSE_GAME_CANCEL_BUTTON_TITLE
                                        otherButtonTitles:nil] autorelease];
    
    /* Add a button for each set of rules */
    for (NSString *rulesName in GAME_RULES_OPTION_NAMES) {
        [av addButtonWithTitle:rulesName];
    }
    
    [av show];
}

#pragma mark - Dealloc
- (void)dealloc {
    [_gameInfoTable release];
    [super dealloc];
}

@end
