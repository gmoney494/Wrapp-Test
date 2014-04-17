//
//  FriendsListViewController.h
//  Wrapp Test
//
//  Created by Giancarlo on 4/16/14.
//  Copyright (c) 2014 Giancarlo Molina. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FriendsListViewController : UIViewController <UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDataSource, UITableViewDelegate> {
    IBOutlet UISearchBar *searchBar;
    IBOutlet UITableView *table;
    
    NSArray *friendsList; // Main content list
    NSMutableArray *filteredListContent; // The content filtered as a result of a search.
    NSArray *sectionedListContent; // The content filtered into alphabetical sections.
}

@property (assign) NSString *accessToken;

@end
