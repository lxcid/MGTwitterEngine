    //
//  TwitterOAuthController.m
//  energy-efficiency
//
//  Created by Stan Chang Khin Boon on 4/7/11.
//  Copyright 2011 buUuk. All rights reserved.
//

#import "TwitterOAuthController.h"
#import <QuartzCore/QuartzCore.h>
#import "MGTwitterEngine.h"
#import "OAMutableURLRequest.h"

static NSString* const kTwitterLoadingBackgroundImage = @"TwitterOAuthController.bundle/images/twitter_load.png";


@interface NSString (TwitterOAuth)

- (BOOL)OAuthTwitter_isNumeric;

@end

@implementation NSString (TwitterOAuth)

- (BOOL)OAuthTwitter_isNumeric {
  const char *theRaw = (const char *)[self UTF8String];
  int theRawLength = strlen(theRaw);
  for (int i = 0; i < theRawLength; i++) {
    if ((theRaw[i] < '0') || (theRaw[i] > '9')) {
      return NO;
    }
  }
  return YES;
}

@end



@implementation TwitterOAuthController

@synthesize twitter = twitter_;

@synthesize webView = webView_;
@synthesize backgroundView = backgroundView_;
@synthesize blockerView = blockerView_;

@synthesize firstLoad = firstLoad_;
@synthesize loading = loading_;

@synthesize delegate = delegate_;

- (id)initWithTwitter:(MGTwitterEngine *)theTwitter {
  self = [super init];
  if (self) {
    self.twitter = theTwitter;
    
    self.firstLoad = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pasteboardChanged:) name:UIPasteboardChangedNotification object:nil];
    
    //[self.twitter OAuthRequestToken];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [super dealloc];
}

- (void)loadView {
  [super loadView];
  
  // Controller's view
  self.view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 460)] autorelease];
  self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  
  // Background view
  self.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:kTwitterLoadingBackgroundImage]] autorelease];
  self.backgroundView.frame = CGRectMake(0, 0, 320, 460);
  self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [self.view addSubview:self.backgroundView];
  
  // Web view
  self.webView = [[[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 320, 460)] autorelease];
  self.webView.alpha = 0.0;
  self.webView.delegate = self;
  self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  if ([self.webView respondsToSelector:@selector(setDetectsPhoneNumbers:)]) {
    [((id) self.webView) setDetectsPhoneNumbers:NO];
  }
  if ([self.webView respondsToSelector:@selector(setDataDetectorTypes:)]) {
    [((id) self.webView) setDataDetectorTypes:0];
  }
  [self.view addSubview:self.webView];
  
  // Blocker view
  self.blockerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 60)] autorelease];
  self.blockerView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
  self.blockerView.center = CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2);
  self.blockerView.alpha = 0.0;
  self.blockerView.clipsToBounds = YES;
  if ([self.blockerView.layer respondsToSelector:@selector(setCornerRadius:)]) {
    [((id) self.blockerView.layer) setCornerRadius:10];
  }
  
  UILabel *theLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 5, self.blockerView.bounds.size.width, 15)] autorelease];
  theLabel.text = @"Please Wait…";
  theLabel.backgroundColor = [UIColor clearColor];
  theLabel.textColor = [UIColor whiteColor];
  theLabel.textAlignment = UITextAlignmentCenter;
  theLabel.font = [UIFont boldSystemFontOfSize:15];
  [self.blockerView addSubview:theLabel];
  
  UIActivityIndicatorView *theSpinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
  theSpinner.center = CGPointMake(self.blockerView.bounds.size.width / 2, self.blockerView.bounds.size.height / 2 + 10);
  [theSpinner startAnimating];
  [self.blockerView addSubview: theSpinner];
  
  [self.view addSubview:self.blockerView];
}


- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  NSURLRequest *theURLRequest = [self.twitter authorizeURLRequest];
  [self.webView loadRequest:theURLRequest];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  self.webView.delegate = nil;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
  [super viewDidUnload];
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
  
  // TODO: (stan@buuuk.com) Clean up memory.
}

#pragma mark -
#pragma mark Notifications

- (void)pasteboardChanged:(NSNotification *)theNotification {
  UIPasteboard *thePasteboard = [UIPasteboard generalPasteboard];
  
  if ([theNotification.userInfo objectForKey:UIPasteboardChangedTypesAddedKey] == nil) {
    return; // No meaningful change
  }
  
  NSString *theCopied = thePasteboard.string;
  
  if ((theCopied.length != 7) || (![theCopied OAuthTwitter_isNumeric])) {
    return;
  }
  
  [self gotOAuthPin:theCopied];
}

#pragma mark -
#pragma mark UIWebViewDelegate methods

- (void)webViewDidFinishLoad:(UIWebView *)theWebView {
  self.loading = NO;
  if (self.firstLoad) {
    /*
    [self.webView performSelector:@selector(stringByEvaluatingJavaScriptFromString:)
                       withObject:@"window.scrollBy(0,200)"
                       afterDelay:0];
    */
    self.firstLoad = NO;
  } else {
    NSString *theOAuthPin = [self locateOAuthPinInWebView:theWebView];
    
    if (theOAuthPin.length) {
      [self gotOAuthPin:theOAuthPin];
      return;
    }
    
    NSString *theFormCount = [self.webView stringByEvaluatingJavaScriptFromString:@"document.forms.length"];
    
    if ([theFormCount isEqualToString:@"0"]) {
      [self showPinCopyPrompt];
    }
  }
  
  [UIView animateWithDuration:0.2 animations:^{
    self.blockerView.alpha = 0.0;
  }];
  if ([self.webView isLoading]) {
    self.webView.alpha = 0.0;
  } else {
    self.webView.alpha = 1.0;
  }
}

- (void)webViewDidStartLoad:(UIWebView *)theWebView {
  self.loading = YES;
  
  [UIView animateWithDuration:0.2 animations:^{
    self.blockerView.alpha = 1.0;
  }];
}

- (BOOL)webView:(UIWebView *)theWebView shouldStartLoadWithRequest:(NSURLRequest *)theRequest navigationType:(UIWebViewNavigationType)theNavigationType {
  NSData *theData = [theRequest HTTPBody];
  char *theRaw = theData ? (char *) [theData bytes] : "";
  
  if (theRaw && strstr(theRaw, "cancel=")) {
    [self denied];
    return NO;
  }
  if (theNavigationType != UIWebViewNavigationTypeOther) {
    self.webView.alpha = 0.1;
  }
  return YES;
}

#pragma mark -
#pragma mark Actions methods

- (void)denied {
	if ([self.delegate respondsToSelector:@selector(twitterOAuthControllerFailed:)]) {
    [self.delegate twitterOAuthControllerFailed:self];
  }
  // TODO: (stan@buuuk.com) It is a better practice to let its parent call this, same goes to those at the bottom.
	[self performSelector:@selector(dismissModalViewControllerAnimated:) withObject:(id)kCFBooleanTrue afterDelay:0.0];
}

- (void)gotOAuthPin:(NSString *)theOAuthPin {
  [self.twitter setOAuthPin:theOAuthPin];
	[self.twitter OAuthAccessToken];
	
  // TODO: (stan@buuuk.com) On my implementation I do not need username so I did not expose this.
	if ([self.delegate respondsToSelector:@selector(OAuthTwitterController:authenticatedWithUsername:)]) {
    [self.delegate OAuthTwitterController:self authenticatedWithUsername:self.twitter.username];
  }
	[self performSelector:@selector(dismissModalViewControllerAnimated:) withObject:(id)kCFBooleanTrue afterDelay:0.0];
}

- (void)cancel:(id)sender {
	if ([self.delegate respondsToSelector:@selector(OAuthTwitterControllerCanceled:)]) {
    [self.delegate OAuthTwitterControllerCanceled:self];
  }
	[self performSelector:@selector(dismissModalViewControllerAnimated:) withObject:(id)kCFBooleanTrue afterDelay:0.0];
}

#pragma mark -
#pragma mark Other methods

- (void)showPinCopyPrompt {
  if (self.pinCopyPromptBar.superview) {
    return; // Already shown
  }
  self.pinCopyPromptBar.center = CGPointMake(self.pinCopyPromptBar.bounds.size.width / 2, -(self.pinCopyPromptBar.bounds.size.height / 2));
  [self.view insertSubview:self.pinCopyPromptBar aboveSubview:self.webView];
  
  [UIView animateWithDuration:0.2 animations:^{
    CGFloat theHeight = self.pinCopyPromptBar.bounds.size.height / 2;
    if (self.navigationController) {
      if (![self.navigationController isNavigationBarHidden]) {
        theHeight += self.navigationController.navigationBar.frame.size.height;
      }
    }
    self.pinCopyPromptBar.center = CGPointMake(self.pinCopyPromptBar.bounds.size.width / 2,  theHeight);
  }];
}

- (NSString *)locateOAuthPinInWebView:(UIWebView *)theWebView {
  NSString *theJS = @""
  "var d = document.getElementById('oauth-pin');"
  "if (d == null) d = document.getElementById('oauth_pin');"
  "if (d) d = d.innerHTML;"
  "if (d == null) {"
    "var r = new RegExp('\\\\s[0-9]+\\\\s');"
    "d = r.exec(document.body.innerHTML);"
    "if (d.length > 0) d = d[0];"
  "}"
  "d.replace(/^\\s*/, '').replace(/\\s*$/, '');"
  "d;";
  NSString *theOAuthPin = [theWebView stringByEvaluatingJavaScriptFromString:theJS];
  
  if (theOAuthPin.length > 0) {
    return theOAuthPin;
  }
  
  NSString *theHTML = [theWebView stringByEvaluatingJavaScriptFromString:@"document.body.innerText"];
  
  if (theHTML.length == 0) {
    return nil;
  }
  
  const char *theRawHTML = (const char *)[theHTML UTF8String];
  int theLength = strlen(theRawHTML);
  int theChunkLength = 0;
  
  for (int i = 0; i < theLength; i++) {
    if (theRawHTML[i] < '0' || theRawHTML[i] > '9') {
      if (theChunkLength == 7) {
        char *theBuffer = (char *)malloc(theChunkLength + 1);
        
        memmove(theBuffer, &theRawHTML[i - theChunkLength], theChunkLength);
        theBuffer[theChunkLength] = 0;
        
        theOAuthPin = [NSString stringWithUTF8String:theBuffer];
        free(theBuffer);
        return theOAuthPin;
      }
      theChunkLength = 0;
    } else {
      theChunkLength++;
    }
  }
  
  return nil;
}

- (UIToolbar *)pinCopyPromptBar {
  if (pinCopyPromptBar_ == nil) {
    CGRect theBounds = self.view.bounds;
    pinCopyPromptBar_ = [[[UIToolbar alloc] initWithFrame:CGRectMake(0, 44, theBounds.size.width, 44)] autorelease];
    pinCopyPromptBar_.barStyle = UIBarStyleBlackTranslucent;
    pinCopyPromptBar_.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    pinCopyPromptBar_.items = [NSArray arrayWithObjects:
                               [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
                               [[[UIBarButtonItem alloc] initWithTitle:@"Select and Copy the PIN" style:UIBarButtonItemStylePlain target:nil action:nil] autorelease],
                               [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
                               nil];
  }
  return pinCopyPromptBar_;
}

@end
