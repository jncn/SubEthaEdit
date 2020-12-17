//  SEEPreviewWebView.m
//  SubEthaEdit
//
//  Created by Jan Cornelissen on 16/12/2020.

#import "SEEPreviewWebView.h"

@implementation SEEPreviewWebView

- (void)willOpenMenu:(NSMenu *)menu withEvent:(NSEvent *)event {
    for (NSMenuItem *item in [menu itemArray]) {
        NSString *tag = item.identifier.description;
        if ([tag isEqualToString:@"WKMenuItemIdentifierOpenLinkInNewWindow"]) {
            [item setTitle:NSLocalizedString(@"Open Link in Browser",@"Web preview open link in browser contextual menu item")];
            [item setAction:@selector(openInBrowser:)];
            [item setTarget:self];
        } else if ([tag isEqualToString:@"WKMenuItemIdentifierDownloadImage"] ||
                   [tag isEqualToString:@"WKMenuItemIdentifierOpenImageInNewWindow"] ||
                   [tag isEqualToString:@"WKMenuItemIdentifierDownloadLinkedFile"]) {
            [item setHidden:YES];
        }
    }
}

- (IBAction)openInBrowser:(id)sender {
    NSURL *url = [NSURL URLWithString:self.selectedURL];
    if (url) {
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}

@end
