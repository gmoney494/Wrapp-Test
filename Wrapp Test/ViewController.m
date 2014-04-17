//
//  ViewController.m
//  Wrapp Test
//
//  Created by Giancarlo on 4/16/14.
//  Copyright (c) 2014 Giancarlo Molina. All rights reserved.
//

#import "ViewController.h"
#import "FriendsListViewController.h"

@interface ViewController ()

@end

@implementation ViewController

/* ***************************************************************** */
#pragma mark IBAction method

// method that initiates the login sequence when login button is pressed
- (IBAction)clickLogin {
    webView.hidden = NO;
    loginButton.hidden = YES;
    
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
    
    NSString *redirectUrlString = @"http://www.facebook.com/connect/login_success.html";
    NSString *authFormatString = @"https://graph.facebook.com/oauth/authorize?client_id=%@&redirect_uri=%@&scope=%@&type=user_agent&display=touch";
    
    NSString *urlString = [NSString stringWithFormat:authFormatString, apiKey, redirectUrlString, @"publish_stream"];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [webView loadRequest:request];
}

/* ***************************************************************** */
#pragma mark Helper methods

//checks string for a FB access token, if found, it cuts it out calls another function for saving
-(void)checkForAccessToken:(NSString *)urlString {
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"access_token=(.*)&" options:0 error:&error];
    if (regex != nil) {
        NSTextCheckingResult *firstMatch = [regex firstMatchInString:urlString options:0 range:NSMakeRange(0, [urlString length])];
        if (firstMatch) {
            NSRange accessTokenRange = [firstMatch rangeAtIndex:1];
            NSString *accessToken = [urlString substringWithRange:accessTokenRange];
            accessToken = [accessToken stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [self accessTokenFound:accessToken];
        }
    }
}

// if token found, save it and present new controller
- (void)accessTokenFound:(NSString *)token {
    aT = token;
    webView.hidden = YES;
    [self performSegueWithIdentifier:@"toFriends" sender:self];
}

/* ***************************************************************** */
#pragma mark Standard iOS methods overridden for custom implementation

- (void)viewDidLoad {
    [super viewDidLoad];
    
    apiKey = @"462721623861087"; // set key for Facebook
    webView.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

// sets the token for the next view controller
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"toFriends"]) {
        FriendsListViewController *list = segue.destinationViewController;
        [list setAccessToken:aT];
    }
}

/* ***************************************************************** */
#pragma mark UIWebViewDelegate Methods

// meant for the redirect urls, checks for access token
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *urlString = request.URL.absoluteString;
    [self checkForAccessToken:urlString];
    
    return TRUE;
}

@end
