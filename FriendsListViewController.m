//
//  FriendsListViewController.m
//  Wrapp Test
//
//  Created by Giancarlo on 4/16/14.
//  Copyright (c) 2014 Giancarlo Molina. All rights reserved.
//

#import "FriendsListViewController.h"
#import "JSONKit.h"

/* ***************************************************************** */
#pragma mark extends classes to allow for neseted loops

@interface NSArray (SSArrayOfArrays)
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;
@end
@implementation NSArray (SSArrayOfArrays)
- (id)objectAtIndexPath:(NSIndexPath *)indexPath {
    return [[self objectAtIndex:[indexPath section]] objectAtIndex:[indexPath row]];
}
@end

@interface NSMutableArray (SSArrayOfArrays)
- (void)addObject:(id)anObject toSubarrayAtIndex:(NSUInteger)idx;
@end
@implementation NSMutableArray (SSArrayOfArrays)
- (void)addObject:(id)anObject toSubarrayAtIndex:(NSUInteger)idx {
    while ([self count] <= idx) {
        [self addObject:[NSMutableArray array]];
    }
    [[self objectAtIndex:idx] addObject:anObject];
}
@end

// Class for holding a Facebook friends name and ID
@interface FBFriend : NSObject
@property (nonatomic) NSString *name, *ID;
@end
@implementation FBFriend
@end

@interface FriendsListViewController ()

@end

@implementation FriendsListViewController

/* ***************************************************************** */
#pragma mark Helper methods

// gets data from Facebook Graph API, places them into custom objects in a list for sorting and indexing
-(void)getFriends {
    NSString *atString = [self.accessToken substringToIndex: 110];
    NSURLResponse *response = nil;
    NSString *urlString = [NSString stringWithFormat:@"https://graph.facebook.com/me/friends?access_token=%@", self.accessToken];
    NSURL *url = [[NSURL alloc] initWithString: urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url];
    [request setHTTPMethod: @"GET"];
    [request setValue: atString forHTTPHeaderField: @"access-token"];
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest: request returningResponse: &response error:NULL];
    JSONDecoder *parser = [[JSONDecoder alloc] init];
    NSDictionary *result = [parser objectWithData: responseData];
    NSArray *temp = [result objectForKey:@"data"];
    NSMutableArray *friends = [[NSMutableArray alloc] init];
    
    for (NSDictionary *dic in temp) {
        FBFriend *friend = [[FBFriend alloc] init];
        friend.name = [dic objectForKey:@"name"];
        friend.ID = [dic objectForKey:@"id"];
        [friends addObject:friend];
    }
    [self setListContent:[(NSArray*)friends sortedArrayUsingComparator:^NSComparisonResult(id a, id b){
        NSString *first = [(FBFriend *)a name];
        NSString *second = [(FBFriend *)b name];
        return [first compare:second];
    }]];
}

// this places all of the objects into subarrays based on first letter
- (void)setListContent:(NSArray *)inListContent {
    if (friendsList == inListContent) {
        return;
    }
    friendsList = inListContent;
    
    NSMutableArray *sections = [NSMutableArray array];
    UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];
    for (FBFriend *friend in friendsList) {
        NSInteger section = [collation sectionForObject:friend collationStringSelector:@selector(name)];
        [sections addObject:friend toSubarrayAtIndex:section];
    }
    
    NSInteger section = 0;
    for (section = 0; section < [sections count]; section++) {
        NSArray *sortedSubarray = [collation sortedArrayFromArray:[sections objectAtIndex:section] collationStringSelector:@selector(name)];
        [sections replaceObjectAtIndex:section withObject:sortedSubarray];
    }
    sectionedListContent = sections;
}

// goes through main list and places any matching objects into the filtered list
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
	[filteredListContent removeAllObjects]; // First clear the filtered array.
    for (NSArray *section in sectionedListContent) {
        for (FBFriend *friend in section) {
            NSRange range = [friend.name rangeOfString:searchText options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)];
            if(range.location >= 0 && range.length > 0)
                [filteredListContent addObject:friend];
        }
    }
}

/* ***************************************************************** */
#pragma mark Standard iOS methods overridden for custom implementation

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self getFriends];
    filteredListContent = [[NSMutableArray alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

/* ***************************************************************** */
#pragma mark UITableViewDelegate and UITableViewDataSourceDelegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return 1;
	else
        return [sectionedListContent count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return [filteredListContent count];
    else
        return [[sectionedListContent objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"friendcell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    FBFriend *temp = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView)
        temp = [filteredListContent objectAtIndex:indexPath.row];
    else
        temp = [sectionedListContent objectAtIndexPath:indexPath];
    cell.textLabel.text = temp.name;
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,  0ul);
    dispatch_async(queue, ^{
        NSData *image=[NSData dataWithContentsOfURL:[NSURL URLWithString: [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture", temp.ID]]];
        dispatch_sync(dispatch_get_main_queue(), ^{
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            cell.imageView.image = [UIImage imageWithData:image];
            [cell setNeedsLayout];
        });
    });
    return cell;
}

#pragma mark UISearchDisplayController Delegate Methods

// Tells the table to reload the data based on the new search text
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self filterContentForSearchText:searchString scope: [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    return YES;
}

// Tells the table to reload the data based on the new search text
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope: [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    return YES;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (tableView == self.searchDisplayController.searchResultsTableView) {
        return nil;
    } else {
        return [[sectionedListContent objectAtIndex:section] count] ? [[[UILocalizedIndexedCollation currentCollation] sectionTitles] objectAtIndex:section] : nil;
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return nil;
    } else {
        return [[NSArray arrayWithObject:UITableViewIndexSearch] arrayByAddingObjectsFromArray:
                [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles]];
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return 0;
    } else {
        if (title == UITableViewIndexSearch) {
            [tableView scrollRectToVisible:self.searchDisplayController.searchBar.frame animated:NO];
            return -1;
        } else {
            return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index-1];
        }
    }
}

@end
