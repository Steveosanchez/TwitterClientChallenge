//
//  APGTweetsTableViewController.m
//  TwitterFeedReader
//
//  Created by Steve_Sanchez on 5/5/13.
//  Copyright (c) 2013 ApargoLLC. All rights reserved.
//

#import "APGTweetsTableViewController.h"
#import "Tweet.h"
#import "TwitterUser.h"
#import "Image.h"
#import "APGTwitterCell.h"
#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>
#import "APGRetweetViewController.h"
#import "APGTwitterFeedRefresh.h"
#import <Accounts/Accounts.h>
#import "APGSpcialTwitterCell.h"

#define kWinnerFont [UIFont fontWithName:@"HelveticaNeue-Bold" size:15]
#define kLoserFont  [UIFont fontWithName:@"HelveticaNeue-Regular" size:15]

#define DEFAULT_TITLE_FONT CTFontCreateWithName(CFSTR("HelveticaNeue-Bold"), 15, NULL)
#define DEFAULT_LIST_FONT CTFontCreateWithName(CFSTR("HelveticaNeue"), 15, NULL)
#define CELL_DEFAULT_POINT_SIZE 14
#define DEFAULT_TITLE_COLOR [UIColor colorWithRed:(56.0 / 255.0) green:(56.0 / 255.0) blue:(56.0/255.0) alpha:1.0]

#define DEFAULT_LIST_COLOR [UIColor colorWithRed:(56.0 / 255.0) green:(56.0 / 255.0) blue:(56.0/255.0) alpha:1.0]

@interface APGTweetsTableViewController ()<NSFetchedResultsControllerDelegate, NSFetchedResultsSectionInfo, APGCommonTwitterCellDelegate, APGSpecialTwitterCellDelegate>
@property (strong, nonatomic) NSManagedObjectContext *localContext;
@property (strong, nonatomic) NSFetchedResultsController *resultsController;
@property (strong, nonatomic) NSMutableArray *indexPathsForSpecialCells;
@property (strong, nonatomic) APGTwitterFeedRefresh *updateFeed;
@end

@implementation APGTweetsTableViewController
@synthesize name;
@synthesize objects;
@synthesize numberOfObjects;
@synthesize indexTitle;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mergeContexts:) name:NSManagedObjectContextDidSaveNotification object:nil];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composeTweet:)];
    [self.refreshControl addTarget:self action:@selector(refreshTable:) forControlEvents:UIControlEventValueChanged];
    
}

- (void)composeTweet:(id)sender{
    SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    
    ACAccountStore *store = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccount = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    __block ACAccount *account = nil;
    [store requestAccessToAccountsWithType:twitterAccount options:nil completion:^(BOOL granted, NSError *error){
        
        if (granted) {
            NSArray *array = [store accounts];
            account = [array objectAtIndex:0];
            if (granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.updateFeed = [[APGTwitterFeedRefresh alloc] init];
                    
                    [[CPTOperationAndRunLoopManager sharedManager] addRunLoopCPUOperation:self.updateFeed finishedTarget:self action:@selector(finishedTwitterUpdate:)];
                });
            }
            
        }
    }];
}

- (IBAction)refreshTable:(id)sender {
    
    ACAccountStore *store = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccount = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    __block ACAccount *account = nil;
    [store requestAccessToAccountsWithType:twitterAccount options:nil completion:^(BOOL granted, NSError *error){
        
        if (granted) {
            NSArray *array = [store accounts];
            account = [array objectAtIndex:0];
            if (granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.updateFeed = [[APGTwitterFeedRefresh alloc] init];
                    
                    [[CPTOperationAndRunLoopManager sharedManager] addRunLoopCPUOperation:self.updateFeed finishedTarget:self action:@selector(finishedTwitterUpdate:)];
                });
            }
            
        }
    }];
}


- (void)finishedTwitterUpdate:(APGTwitterFeedRefresh *)operation{
    self.updateFeed = nil;
    [self.refreshControl endRefreshing];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"ReplySegue"]) {
        APGRetweetViewController *controller = segue.destinationViewController;
        controller.localTweet = sender;
    }
}

#pragma mark -
#pragma mark Getter Overrides

- (NSManagedObjectContext *)localContext{
    if (!self->_localContext) {
        self->_localContext = [[NSManagedObjectContext alloc] init];
        self->_localContext.persistentStoreCoordinator = [CPTDataAccess sharedAccess].managedObjectContext.persistentStoreCoordinator;
        self->_localContext.undoManager = nil;
        [self->_localContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    }
    return self->_localContext;
}

- (NSFetchedResultsController *)resultsController{
    if (!self->_resultsController) {
        NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"Tweet"];
        [fetch setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO]]];
        self->_resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetch managedObjectContext:self.localContext sectionNameKeyPath:nil cacheName:nil];
        self->_resultsController.delegate = self;
        NSError *error = nil;
        if (![self->_resultsController performFetch:&error]) {
            NSLog(@"There was an error fetching the Items error \n %@ \n user info \n %@", error, error.userInfo);
        }
    }
    
    return self->_resultsController;
}

- (NSMutableArray *)indexPathsForSpecialCells{
    if (!self->_indexPathsForSpecialCells) {
        self->_indexPathsForSpecialCells = [NSMutableArray array];
    }
    return self->_indexPathsForSpecialCells;
}

#pragma mark Core Data Operations

- (void)mergeContexts: (NSNotification *)notification{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(mergeContexts:) withObject:notification waitUntilDone:NO];
        return;
    }
    [self.localContext mergeChangesFromContextDidSaveNotification:notification];
}


#pragma mark - FetchedResultsController

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller{
    [self.tableView endUpdates];
}
- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type{
    switch (type) {
        case NSFetchedResultsChangeInsert:{
            [self.self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
            break;
        }
        case NSFetchedResultsChangeDelete:{
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
            break;
        }
            
        default:
            break;
    }
}



- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath{
    
    
    switch (type) {
        case NSFetchedResultsChangeInsert:{
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
        }
        case NSFetchedResultsChangeDelete:{
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
        }
        case NSFetchedResultsChangeUpdate:{
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
        }
        case NSFetchedResultsChangeMove:{
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
        }
            
        default:
            break;
    }
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller{
    [self.tableView beginUpdates];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"number of objects == %d", [[[self.resultsController sections] objectAtIndex:0] numberOfObjects]);
    return [[[self.resultsController sections] objectAtIndex:0] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TwitterCell";
    static NSString *SpecialCellIdentifier = @"SpecialCell";
    
    UITableViewCell *retVal = nil;
    
    if ([self.indexPathsForSpecialCells containsObject:indexPath]) {
        APGSpcialTwitterCell *cell = [tableView dequeueReusableCellWithIdentifier:SpecialCellIdentifier forIndexPath:indexPath];
        cell.localTweet = [self.resultsController objectAtIndexPath:indexPath];
        cell.cellDelegate = self;
        retVal = cell;
    }else{
        APGTwitterCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        Tweet *tweet = [self.resultsController objectAtIndexPath:indexPath];
        cell.profileImage.image = nil;
        cell.tweetObject = tweet;
        cell.localDelegate = self;
        cell.adjustedText.tweetText = tweet.body;
        
        CALayer *theLayer = [CALayer layer];
        theLayer.contentsScale = [[UIScreen mainScreen] scale];
        
        CGRect bounds = [cell.adjustedText bounds];
        theLayer.position = CGPointMake(bounds.size.width/2, bounds.size.height/2);
        
        theLayer.bounds = bounds;
        theLayer.backgroundColor = [[UIColor  clearColor] CGColor];
        [theLayer setDelegate:cell.adjustedText.coreTextDrawDelegate];
        
        CALayer* viewLayer = [cell.adjustedText layer];
        NSArray* subLayers = [viewLayer sublayers];
            // Remove any previous CALayer
        for (CALayer* aSubLayer in subLayers) {
            aSubLayer.delegate = nil;
            [aSubLayer removeFromSuperlayer];
        }
        
        [[cell.adjustedText layer] addSublayer:theLayer];
        [cell.adjustedText setNeedsDisplay];
        [theLayer setNeedsDisplay];
        [theLayer display];
        
        retVal = cell;
    }

    
    return retVal;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    CGFloat retVal = CGFLOAT_MIN;
    
    CTFontRef urlLinkFont = DEFAULT_LIST_FONT;
    
    CGColorRef listColorLocal = CGColorRetain(DEFAULT_LIST_COLOR.CGColor);
    
    
    CGFloat lineSpacing = 6.0;
    CGFloat headIndent = 0.0;
    
    CTParagraphStyleSetting listParagraphStyle[2];
    listParagraphStyle[0].spec = kCTParagraphStyleSpecifierLineSpacing;
    listParagraphStyle[0].valueSize = sizeof(CGFloat);
    listParagraphStyle[0].value = &lineSpacing;
    listParagraphStyle[1].spec = kCTParagraphStyleSpecifierHeadIndent;
    listParagraphStyle[1].valueSize = sizeof(CGFloat);
    listParagraphStyle[1].value = &headIndent;
    
        //CTParagraphStyleRef styleForListParagraph = CTParagraphStyleCreate((const CTParagraphStyleSetting*) &listParagraphStyle, 2);
    
    CTParagraphStyleSetting titleParagraphStyle[1];
    titleParagraphStyle[0].spec = kCTParagraphStyleSpecifierLineSpacing;
    titleParagraphStyle[0].valueSize = sizeof(CGFloat);
    titleParagraphStyle[0].value = &lineSpacing;
    
    CTParagraphStyleRef styleForTitleParagraph = CTParagraphStyleCreate((const CTParagraphStyleSetting*) &titleParagraphStyle, 1);
    
    NSDictionary *titleAttributeDictionary = [NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)urlLinkFont,(NSString*)kCTFontAttributeName, (__bridge id)listColorLocal,(NSString*)kCTForegroundColorAttributeName, (__bridge id)styleForTitleParagraph, kCTParagraphStyleAttributeName,  nil];
    Tweet *tweet = [self.resultsController objectAtIndexPath:indexPath];
    
    NSMutableAttributedString *tweetTextAttributedString = [[NSMutableAttributedString alloc] initWithString:tweet.body attributes:titleAttributeDictionary];
    
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)tweetTextAttributedString);
    CGSize sizeOfTextBox = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, CFRangeMake(0, 0), NULL, CGSizeMake(193.0, CGFLOAT_MAX), NULL);
    CFRelease(listColorLocal);
    retVal = sizeOfTextBox.height + 76.0;
    return retVal;
}

#pragma mark -
#pragma mark Cell Delegate 

- (void)didSwipeToTheLeft:(UITableViewCell *)cell{
        //[self performSegueWithIdentifier:@"TwitterOptions" sender:cell];
    NSIndexPath *indexPathForRow = [self.tableView indexPathForCell:cell];
    [self.indexPathsForSpecialCells addObject:indexPathForRow];
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[indexPathForRow] withRowAnimation:UITableViewRowAnimationLeft];
    [self.tableView endUpdates];
}

- (void)didSwiptToTheRight:(UITableViewCell *)cell{
    NSIndexPath *localIndexPath = [self.tableView indexPathForCell:cell];
    [self.indexPathsForSpecialCells removeObject:localIndexPath];
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[localIndexPath] withRowAnimation:UITableViewRowAnimationRight];
    [self.tableView endUpdates];
}

- (void)didSelectReply:(UITableViewCell *)tweet{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:tweet];
    Tweet *tweetObj = [self.resultsController objectAtIndexPath:indexPath];
    
    [self performSegueWithIdentifier:@"ReplySegue" sender:tweetObj];
}

- (void)didSelectURL:(UITableViewCell *)cell{
    
    NSIndexPath *index = [self.tableView indexPathForCell:cell];
    Tweet *tweet = [self.resultsController objectAtIndexPath:index];
    NSString *tweetText = tweet.body;
    
    NSArray *tweetcomponents = [tweetText componentsSeparatedByString:@" "];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    for (NSString *word in tweetcomponents) {
        if ([word rangeOfString:@"http:"].length > 0 || [word rangeOfString:@"bit"].length > 0 || [word rangeOfString:@".am"].length > 0) {
            [dict setObject:word forKey:@"url"];
        }
    }
    
    NSString *urlString = dict[@"url"];
    if (!urlString) {
        return;
    }
    
    NSURL *loadingURL = [NSURL URLWithString:urlString];
    [[UIApplication sharedApplication] openURL:loadingURL];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
