//
//  SyntaxHighlighter.h
//  SyntaxTestBench
//
//  Created by Martin Pittenauer on Thu Mar 04 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SyntaxDefinition.h"

extern NSString * const kSyntaxHighlightingIsDirtyAttributeName;
extern NSString * const kSyntaxHighlightingIsDirtyAttributeValue;

@interface SyntaxHighlighter : NSObject {
    SyntaxDefinition *I_syntaxDefinition;
}

/*"Initizialisation"*/
- (id)initWithSyntaxDefinition:(SyntaxDefinition *)aSyntaxDefinition;

/*"Accessors"*/
- (SyntaxDefinition *)syntaxDefinition;
- (void)setSyntaxDefinition:(SyntaxDefinition *)aSyntaxDefinition;

/*"Document Interaction"*/
- (BOOL)colorizeDirtyRanges:(NSTextStorage *)aTextStorage;
- (void)cleanUpTextStorage:(NSTextStorage *)aTextStorage;

@end
