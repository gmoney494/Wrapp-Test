//
//  ViewController.h
//  Wrapp Test
//
//  Created by Giancarlo on 4/16/14.
//  Copyright (c) 2014 Giancarlo Molina. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ViewController : UIViewController <UIWebViewDelegate> {
    IBOutlet UIWebView *webView;
    IBOutlet UIButton *loginButton;
    NSString *apiKey;
    NSString *requestedPermissions;
    NSString *aT;
}

- (IBAction)clickLogin;



@end
