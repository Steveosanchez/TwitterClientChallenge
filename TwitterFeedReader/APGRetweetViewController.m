//
//  APGRetweetViewController.m
//  dodgy
//
//  Created by Steve_Sanchez on 9/8/12.
//  Copyright (c) 2012 Apargo. All rights reserved.
//

#import "APGRetweetViewController.h"
#import "CPTNetworkRetryOperation.h"
#import "Tweet.h"
#import <Accounts/Accounts.h>

@interface APGRetweetViewController ()<UITextFieldDelegate>{
    CPTNetworkRetryOperation *_retryOperation;
    NSString *_pathForJsonFile;

}

@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;
@property (weak, nonatomic) IBOutlet UITextView *tweetTextField;
@property (strong, nonatomic) CPTNetworkRetryOperation *retryOperation;
@property (strong, nonatomic) NSString *pathForJsonFile;
@end

@implementation APGRetweetViewController
@synthesize toolBar;
@synthesize tweetTextField;
- (void)viewDidLoad{
    [super viewDidLoad];
    self.tweetTextField.text = [NSString stringWithFormat:@"@%@", self.localTweet.userID];
    
    [self.tweetTextField becomeFirstResponder];
    
    UIBarButtonItem *customBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(postTweet:)];
    
    UIBarButtonItem *customBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPost:)];
    
    UIBarButtonItem *fixedSpaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpaceItem.width = 170;
    
    [self.toolBar setItems:@[customBarButtonItem, fixedSpaceItem, customBarButton]];
}
- (IBAction)cancelPost:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)postTweet:(id)sender {
    ACAccountStore *store = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccount = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    __block ACAccount *account = nil;
    [store requestAccessToAccountsWithType:twitterAccount options:nil completion:^(BOOL granted, NSError *error){
        
        if (granted) {
            NSArray *array = [store accounts];
            account = [array objectAtIndex:0];
            
            
            SLRequest *tweetRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1.1/statuses/update.json"]] parameters:@{ @"status" : self.tweetTextField.text, @"in_reply_to_status_id" : self.localTweet.tweetId }];
            
            tweetRequest.account = account;
            
            NSURLRequest *signedRequest = [tweetRequest preparedURLRequest];
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.retryOperation = [[CPTNetworkRetryOperation alloc] initWithRequest:signedRequest];
                
                [[CPTOperationAndRunLoopManager sharedManager] addNetworkManagementOperation:self.retryOperation finishedTarget:self action:@selector(finishProcessFavorite:)];
                
            });
            
        }
    }];
}

- (void)finishProcessFavorite:(CPTNetworkRetryOperation *)operation{
    self.retryOperation = nil;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidUnload
{
    [self setTweetTextField:nil];
    toolBar = nil;
    [self setToolBar:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
