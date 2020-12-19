//  SEEWebPreviewViewController.m
//  was : WebPreviewWindowController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Jul 07 2003.
//  refactored to be a ViewController by liz

#import "TCMMMSession.h"
#import "SEEWebPreviewViewController.h"
#import "PlainTextDocument.h"
#import "FoldableTextStorage.h"
#import "DocumentMode.h"
#import "SEEScopedBookmarkManager.h"
#import "PopUpButton.h"
#import "SEEWebPreview.h"
#import "SEEPreviewWebView.h"

@class PopUpButton;

static NSString *WebPreviewWindowSizePreferenceKey =@"WebPreviewWindowSize";
static NSString *WebPreviewRefreshModePreferenceKey=@"WebPreviewRefreshMode";

@interface SEEWebPreviewViewController () <WKNavigationDelegate, WKScriptMessageHandler>
@property (nonatomic, strong) IBOutlet SEEPreviewWebView *webView;
@property (nonatomic, strong) IBOutlet WebView *oWebView;
@property (nonatomic, strong) IBOutlet NSTextField *oBaseUrlTextField;
@property (nonatomic, strong) IBOutlet PopUpButton *oRefreshPopupButton;
@property (nonatomic, strong) IBOutlet NSTextField *oStatusTextField;

@property (nonatomic, strong) PlainTextDocument *plainTextDocument;
@property (nonatomic, weak) NSTimer *delayedRefreshTimer;

@property (nonatomic) SEEWebPreviewRefreshType refreshType;
@property (nonatomic) BOOL shallCache;
@property (nonatomic) CGPoint scrollPosition;

@property (nonatomic, weak) id documentDidChangeObserver;
@property (nonatomic, weak) id documentDidSaveObserver;

@end

@implementation SEEWebPreviewViewController

@synthesize plainTextDocument=_plainTextDocument;
@synthesize refreshType=_refreshType;

- (instancetype)initWithPlainTextDocument:(PlainTextDocument *)aDocument {
    self=[super initWithNibName:@"SEEWebPreviewViewController" bundle:nil];
    _plainTextDocument=aDocument;
    _shallCache=YES;
    NSNumber *refreshTypeNumber=[[[aDocument documentMode] defaults] objectForKey:WebPreviewRefreshModePreferenceKey];
    _refreshType=kWebPreviewRefreshDelayed;
    if (refreshTypeNumber) {
        int refreshType=[refreshTypeNumber intValue];
        if (refreshType>0 && refreshType <=kWebPreviewRefreshDelayed) {
            _refreshType=refreshType;
        }
    }

	__weak typeof(self) weakSelf = self;
	self.documentDidChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:PlainTextDocumentDidChangeTextStorageNotification object:aDocument queue:nil usingBlock:^(NSNotification *note) {
		typeof(self) strongSelf = weakSelf;

		if ([strongSelf refreshType] == kWebPreviewRefreshAutomatic) {
			[strongSelf refresh:strongSelf];
		} else if ([strongSelf refreshType] == kWebPreviewRefreshDelayed) {
			[strongSelf triggerDelayedWebPreviewRefresh];
		}
	}];
	
	self.documentDidSaveObserver = [[NSNotificationCenter defaultCenter] addObserverForName:PlainTextDocumentDidSaveShouldReloadWebPreviewNotification object:aDocument queue:nil usingBlock:^(NSNotification *note) {
		typeof(self) strongSelf = weakSelf;

		if ([strongSelf refreshType] == kWebPreviewRefreshOnSave) {
			[strongSelf refreshAndEmptyCache:strongSelf];
		}
	}];
	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(somePlainTextDocumentDidSave:) name:PlainTextDocumentDidSaveNotification object:nil];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self.documentDidSaveObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.documentDidChangeObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark
- (void)setPlainTextDocument:(PlainTextDocument *)aDocument {
    _plainTextDocument = aDocument;
    if (!aDocument) {
        [self.webView stopLoading:self];
    }
}

- (PlainTextDocument *)plainTextDocument {
    return _plainTextDocument;
}

#pragma mark
- (NSURL *)baseURL {
    return [NSURL URLWithString:[self.oBaseUrlTextField stringValue]];
}

- (void)setBaseURL:(NSURL *)aBaseURL {
    [self.oBaseUrlTextField setStringValue:[aBaseURL absoluteString]];
}

- (void)updateBaseURL {
    NSURL *fileURL;
    if ((fileURL=[[self plainTextDocument] fileURL])) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]]) {
            [self.oBaseUrlTextField setStringValue:[fileURL absoluteString]];
        }
    } 
}

#pragma mark

-(void)reloadWebViewCachingAllowed:(BOOL)aFlag {
    _shallCache=aFlag;
    
    NSURL *baseURL=[NSURL URLWithString:@"http://localhost/"];
    NSString *potentialURLString = [self.oBaseUrlTextField stringValue];
    if ([potentialURLString length] > 0) {
    	NSURL *tryURL = [NSURL URLWithString:potentialURLString];
//    	NSLog(@"%s %@ %@",__FUNCTION__,[tryURL debugDescription],[tryURL standardizedURL]);
    	if ([[tryURL host] length] > 0 || [[tryURL scheme] isEqualToString:@"file"]) {
    		baseURL = tryURL;
    	} else if ([potentialURLString characterAtIndex:0] == '/') {
    		tryURL = [NSURL URLWithString:[@"file://" stringByAppendingString:potentialURLString]];
    		baseURL = tryURL;
    	} else {
    		tryURL = [NSURL URLWithString:[@"http://" stringByAppendingString:potentialURLString]];
    		baseURL = tryURL;
    		[self.oBaseUrlTextField setStringValue:[tryURL absoluteString]];
    	}
    }

//	NSLog(@"%s using URL: %@",__FUNCTION__,baseURL);
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:baseURL];
    [request setMainDocumentURL:baseURL];
    
    FoldableTextStorage *textStorage = (FoldableTextStorage *)[[self plainTextDocument] textStorage];
    NSString *string=[[textStorage fullTextStorage] string];
    
    SEEWebPreview *preview = self.plainTextDocument.documentMode.webPreview;
    
    NSStringEncoding encoding = [textStorage encoding];
    NSString *IANACharSetName=(NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(encoding));
    
    void (^previewBlock)(NSString *html) = ^(NSString *html){
        [request setHTTPBody:[html dataUsingEncoding:encoding]];
        [NSOperationQueue TCM_performBlockOnMainThreadSynchronously:^{
            // `allowingReadAccessToURL` is the key to load resources like images and css
            [self.webView loadFileURL:baseURL allowingReadAccessToURL:[baseURL URLByDeletingLastPathComponent]];
            [self.webView loadHTMLString:html baseURL:baseURL];
//            [self.webView loadData:[html dataUsingEncoding:encoding] MIMEType:@"text/html" characterEncodingName:IANACharSetName baseURL:baseURL];
        }];
    };
    
    if (preview) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            previewBlock([preview webPreviewForText:string]);
        });
    } else {
        previewBlock(string);
    }
}

#pragma mark
-(IBAction)refreshAndEmptyCache:(id)aSender {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    id cacheClass = NSClassFromString([@"Web" stringByAppendingString:@"Cache"]);
    [cacheClass setValue:@(YES) forKey:@"disabled"];
    [self reloadWebViewCachingAllowed:NO];
    [cacheClass setValue:@(NO) forKey:@"disabled"];
}

-(IBAction)refresh:(id)aSender {
    [self reloadWebViewCachingAllowed:YES];
}

- (SEEWebPreviewRefreshType)refreshType {
    return _refreshType;
}

- (void)setRefreshType:(SEEWebPreviewRefreshType)aRefreshType {
    [[[[self plainTextDocument] documentMode] defaults] setObject:[NSNumber numberWithInt:aRefreshType] forKey:WebPreviewRefreshModePreferenceKey];
    if ([self view]) {
        int index=[self.oRefreshPopupButton indexOfItemWithTag:aRefreshType];
        if (index!=-1) {
            _refreshType=aRefreshType;
            [self.oRefreshPopupButton selectItemAtIndex:index];
        }
    } else {
        _refreshType=aRefreshType;
    }
}

-(IBAction)changeRefreshType:(id)aSender {
    [self setRefreshType:[[aSender selectedItem] tag]];
}

#pragma mark - NSViewController overrides
-(void)loadView {
    [super loadView];

    self.oRefreshPopupButton.lineDrawingEdge = CGRectMinXEdge;
    [self.oRefreshPopupButton setLineColor:[NSColor tertiaryLabelColor]];
    [self.oStatusTextField setStringValue:@""];
    
    WKPreferences *prefs = self.webView.configuration.preferences;
    [prefs setValue:@YES forKey:@"developerExtrasEnabled"];
    
    WKUserContentController *contentController = self.webView.configuration.userContentController;
    [contentController addScriptMessageHandler:self name:@"scriptHoverHandler"];
    [contentController addScriptMessageHandler:self name:@"scriptUpdateScrollPosition"];
    NSURL *scriptURL = [[NSBundle mainBundle] URLForResource:@"WebPreviewScript" withExtension:@"js"];
    NSString *scriptString = [NSString stringWithContentsOfURL:scriptURL encoding:NSUTF8StringEncoding error:NULL];
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:scriptString injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
    [contentController addUserScript:userScript];

	[self updateBaseURL];
    [self setRefreshType:_refreshType];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"scriptHoverHandler"]) {
        [self.oStatusTextField setStringValue:message.body];
        [self.webView setSelectedURL:message.body];
    }
    
    if ([message.name isEqualToString:@"scriptUpdateScrollPosition"]) {
        NSArray *position = [message.body componentsSeparatedByString:@","];
        self.scrollPosition = CGPointMake([position[0] floatValue], [position[1] floatValue]);
    }
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSString *script = [NSString stringWithFormat:@"window.scrollTo(%f,%f);", self.scrollPosition.x, self.scrollPosition.y];
    [self.webView evaluateJavaScript:script completionHandler:nil];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    decisionHandler(WKNavigationResponsePolicyAllow);
}

#pragma mark - CSS-update

- (void)somePlainTextDocumentDidSave:(NSNotification *)aNotification {
    NSString *savedFileName = [[[aNotification object] fileURL] lastPathComponent];
    if ([[[savedFileName pathExtension] lowercaseString] isEqualToString:@"css"]) {
        if ([[[[self plainTextDocument] textStorage] string] rangeOfString:savedFileName options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [self refreshAndEmptyCache:self];
        }
    }
}


#pragma mark -
#pragma mark ### WebResourceLoadDelegate ###
- (id)webView:(WebView *)sender identifierForInitialRequest:(NSURLRequest *)request fromDataSource:(WebDataSource *)dataSource {
	static NSInteger counter = 0;
	NSURL *url = request.URL;
	if (![request valueForHTTPHeaderField:@"LocalContentAndThisIsTheEncoding"]) {
		if (url.isFileURL && ![[SEEScopedBookmarkManager sharedManager] canAccessURL:url]) {
			counter++;
			if (counter == 1) {
				if ([[SEEScopedBookmarkManager sharedManager] startAccessingURL:url]) {
					[self reloadWebViewCachingAllowed:NO];
				}
			}
			counter--;
		}
	}
	return url;
}

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource {
	if (![request valueForHTTPHeaderField:@"LocalContentAndThisIsTheEncoding"]) {
		NSMutableURLRequest *mutableRequest = [request mutableCopy];
		[mutableRequest setCachePolicy:_shallCache ? NSURLRequestReturnCacheDataElseLoad : NSURLRequestReloadIgnoringCacheData];
		return mutableRequest;
	}
    return request;
}

- (void)webView:(WebView *)sender resource:(id)identifier didFinishLoadingFromDataSource:(WebDataSource *)dataSource {
	if ([identifier isKindOfClass:[NSURL class]]) {
		NSURL *url = identifier;
		if (url.isFileURL) {
			[[SEEScopedBookmarkManager sharedManager] stopAccessingURL:url];
		}
	}
}

- (void)webView:(WebView *)webView decidePolicyForMIMEType:(NSString *)type request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id < WebPolicyDecisionListener >)listener {
	[listener use];
}

#pragma mark - Refresh timer

#define WEBPREVIEWDELAYEDREFRESHINTERVAL 1.2

- (void)triggerDelayedWebPreviewRefresh {
	NSTimer *timer = self.delayedRefreshTimer;
	if ([timer isValid]) {
		[timer setFireDate:[NSDate dateWithTimeIntervalSinceNow:WEBPREVIEWDELAYEDREFRESHINTERVAL]];
	} else {
		timer = [NSTimer timerWithTimeInterval:WEBPREVIEWDELAYEDREFRESHINTERVAL
										target:self
									  selector:@selector(delayedWebPreviewRefreshAction:)
									  userInfo:nil
									   repeats:NO];
		timer.tolerance = 0.5;

		[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
		self.delayedRefreshTimer = timer;
	}
}

- (void)delayedWebPreviewRefreshAction:(NSTimer *)aTimer {
    [self refresh:self];
}

@end
