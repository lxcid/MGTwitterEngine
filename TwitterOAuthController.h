//
//  TwitterOAuthController.h
//  energy-efficiency
//
//  Created by Stan Chang Khin Boon on 4/7/11.
//  Copyright 2011 buUuk. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TwitterOAuthControllerDelegate;

@class MGTwitterEngine;

@interface TwitterOAuthController : UIViewController<UIWebViewDelegate> {
  MGTwitterEngine *twitter_;
  
  UIWebView *webView_;
  UIImageView *backgroundView_;
  UIView *blockerView_;
  UIToolbar *pinCopyPromptBar_;
  
  BOOL firstLoad_;
  BOOL loading_;
  
  id<TwitterOAuthControllerDelegate> delegate_;
}

@property (nonatomic, retain) MGTwitterEngine *twitter;

@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) UIImageView *backgroundView;
@property (nonatomic, retain) UIView *blockerView;
@property (nonatomic, readonly) UIToolbar *pinCopyPromptBar;

@property (nonatomic, assign) BOOL firstLoad;
@property (nonatomic, assign) BOOL loading;

@property (nonatomic, assign) id<TwitterOAuthControllerDelegate> delegate;

- (id)initWithTwitter:(MGTwitterEngine *)theTwitter;

- (void)cancel:(id)sender;
- (void)denied;
- (void)gotOAuthPin:(NSString *)theOAuthPin;
- (NSString *)locateOAuthPinInWebView:(UIWebView *)theWebView;
- (void)showPinCopyPrompt;

@end

@protocol TwitterOAuthControllerDelegate<NSObject>
@optional
- (void)twitterOAuthControllerFailed:(TwitterOAuthController *)theTwitterOAuthController;
- (void)OAuthTwitterControllerCanceled:(TwitterOAuthController *)theTwitterOAuthController;

@end