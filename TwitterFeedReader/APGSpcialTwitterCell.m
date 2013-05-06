//
//  APGSpcialTwitterCell.m
//  dodgy
//
//  Created by Steve_Sanchez on 9/8/12.
//  Copyright (c) 2012 Apargo. All rights reserved.
//

#import "APGSpcialTwitterCell.h"
#import "Tweet.h"
#import "CPTNetworkRetryOperation.h"
#import <Accounts/Accounts.h>

@interface APGSpcialTwitterCell(){
    CPTNetworkRetryOperation *_retryOperation;
    NSString *_pathForJsonFile;
}
@property (strong, nonatomic) CPTNetworkRetryOperation *retryOperation;
@property (strong, nonatomic) NSString *pathForJsonFile;

@end
@implementation APGSpcialTwitterCell
@synthesize replyButton;
@synthesize retweetButton;
@synthesize favoriteButton;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        UISwipeGestureRecognizer *swipeGest = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(processSwipeFromSpecialCell:)];
        swipeGest.direction = UISwipeGestureRecognizerDirectionRight;
        [self addGestureRecognizer:swipeGest];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)processSwipeFromSpecialCell:(UISwipeGestureRecognizer *)gesture{
    if ([self.cellDelegate respondsToSelector:@selector(didSwiptToTheRight:)]) {
        [self.cellDelegate didSwiptToTheRight:(UITableViewCell*)gesture.view];
    }
}
- (IBAction)processFavorite:(id)sender {
    
    ACAccountStore *store = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccount = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    __block ACAccount *account = nil;
    [store requestAccessToAccountsWithType:twitterAccount options:nil completion:^(BOOL granted, NSError *error){
        
        if (granted) {
            NSArray *array = [store accounts];
            account = [array objectAtIndex:0];
            
            
            SLRequest *tweetRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1.1/favorites/create.json"]] parameters:@{ @"id" : self.localTweet.tweetId}];
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
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Retweet sent" message:@"You have sent a retweet" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    
    if ([self.cellDelegate respondsToSelector:@selector(didSwiptToTheRight:)]) {
        [self.cellDelegate didSwiptToTheRight:self];
    }
    [UIView animateWithDuration:.5 animations:^{
        CGRect frameHolder = self.favoriteButton.frame;
        self.favoriteButton.frame = CGRectMake(frameHolder.origin.x, frameHolder.origin.y, frameHolder.size.width + 10, frameHolder.size.height + 10);
        self.favoriteButton.frame = frameHolder;
        
    }];
}
- (IBAction)processRetweet:(id)sender {
    ACAccountStore *store = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccount = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    __block ACAccount *account = nil;
    [store requestAccessToAccountsWithType:twitterAccount options:nil completion:^(BOOL granted, NSError *error){
        
        if (granted) {
            NSArray *array = [store accounts];
            account = [array objectAtIndex:0];
            
            
            SLRequest *tweetRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1.1/statuses/retweet/%@.json", self.localTweet.tweetId]] parameters:nil];
            tweetRequest.account = account;
            
            NSURLRequest *signedRequest = [tweetRequest preparedURLRequest];
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.retryOperation = [[CPTNetworkRetryOperation alloc] initWithRequest:signedRequest];
                
                [[CPTOperationAndRunLoopManager sharedManager] addNetworkManagementOperation:self.retryOperation finishedTarget:self action:@selector(finishProcessFavorite:)];
                
            });
            
        }
    }];
}
- (IBAction)replyTweet:(id)sender {
    [self.cellDelegate didSelectReply:self];
}

@end
