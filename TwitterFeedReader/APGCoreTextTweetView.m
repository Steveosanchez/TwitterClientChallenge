//
//  APGCoreTextTweetView.m
//  dodgy
//
//  Created by Steve_Sanchez on 9/13/12.
//  Copyright (c) 2012 Apargo. All rights reserved.
//

#import "APGCoreTextTweetView.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>


@interface APGCoreTextTweetView ()<UIGestureRecognizerDelegate>{
    NSInteger _pointSize;
}
@property (unsafe_unretained, nonatomic) NSInteger pointSize;

@end
#define DEFAULT_TITLE_FONT CTFontCreateWithName(CFSTR("HelveticaNeue"), 16.0, NULL)
#define DEFAULT_LIST_FONT CTFontCreateWithName(CFSTR("HelveticaNeue"), 16, NULL)
#define CELL_DEFAULT_POINT_SIZE 14
#define DEFAULT_TITLE_COLOR [UIColor colorWithRed:(77.0 / 255.0) green:(76.0 / 255.0) blue:(76.0/255.0) alpha:1.0]

#define DEFAULT_LIST_COLOR [UIColor colorWithRed:(183.0 / 255.0) green:(23.0 / 255.0) blue:(27.0/255.0) alpha:1.0]



@interface CoreTextDrawDelegate : UIView{
    APGCoreTextTweetView *_aView;
}
- (CoreTextDrawDelegate *)initWithView:(APGCoreTextTweetView*)aView;
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx;
@end


@implementation CoreTextDrawDelegate

- (CoreTextDrawDelegate*)initWithView:(APGCoreTextTweetView *)theView{
    if ((self = [super init])) {
        self->_aView = theView;
    }
    return self;
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx{
    [_aView drawIntoLayer:layer inContext:ctx];
}

@end

@implementation APGCoreTextTweetView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(processURLSelection:)];
        [self addGestureRecognizer:tapGesture];
    }
    
    return self;
}

- (void)processURLSelection:(UIGestureRecognizer *)gesture{
    [self.localDelegate didSelectView];
}

- (id)coreTextDrawDelegate{
    if (self->_coreTextDrawDelegate == nil) {
        self->_coreTextDrawDelegate = [[CoreTextDrawDelegate alloc] initWithView:self];
    }
    return self->_coreTextDrawDelegate;
}


- (void)drawIntoLayer:(CALayer *)layer inContext:(CGContextRef)ctx{
    CGContextSetTextMatrix(ctx, CGAffineTransformIdentity);
    CGContextTranslateCTM(ctx, 0, ([self bounds]).size.height);
    CGContextScaleCTM(ctx, 1.0, -1.0);
    NSAttributedString *stringToDraw = [self buildAttributedString];
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)stringToDraw);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectMake(0, 0, self.frame.size.width, self.frame.size.height));
    CTFrameRef frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, NULL);
    
    //CFRelease(frameSetter);
    CTFrameDraw(frame, ctx);
    CFRelease(path);
}

- (void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    [self setNeedsDisplay];
    [self.layer.sublayers makeObjectsPerformSelector:@selector(setNeedsDisplay)];
}

- (NSAttributedString *)buildAttributedString{
    //CFStringRef fontName;
    CTFontRef mainBodyFont = CTFontCreateWithName(CFSTR("HelveticaNeue"), 16.0, NULL);
    
    //CTFontRef urlLinkFont = DEFAULT_LIST_FONT;
    
    CGColorRef mainBodyColor = CGColorRetain(DEFAULT_TITLE_COLOR.CGColor);
    CGColorRef listColorLocal = CGColorRetain([UIColor colorWithRed:(183.0 / 255.0) green:(23.0 / 255.0) blue:(27.0/255.0) alpha:1.0].CGColor);
    
    
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
    
    if (self.tweetText.length == 0) {
        return nil;
    }
    NSMutableAttributedString *tweetTextAttributedString = [[NSMutableAttributedString alloc] initWithString:self.tweetText attributes:nil];
    [tweetTextAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)mainBodyFont range:[self.tweetText rangeOfString:self.tweetText]];
    [tweetTextAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(__bridge id)(mainBodyColor) range:[self.tweetText rangeOfString:self.tweetText]];
    CFRelease(mainBodyColor);
    
    NSArray *array = [self.tweetText componentsSeparatedByString:@" "];
    
    NSMutableDictionary *dictionaryOfRanges = [NSMutableDictionary dictionary];
    for (NSString *string in array) {
        if (string.length == 0) {
            continue;
        }
        unichar charicter = [string characterAtIndex:0];
        unichar passedChar[1];
        passedChar[0] = charicter;
        NSString *firstChar = [NSString stringWithCharacters:passedChar length:1];
        if ([firstChar isEqualToString:@"#"] && [string length] > 1) {
            NSRange rangeOfHashTag = [self.tweetText rangeOfString:string];
            [dictionaryOfRanges setValue:[NSValue valueWithRange:rangeOfHashTag] forKey:@"hash"];
        }
        
        if ([string rangeOfString:@"com/"].length > 0 || [string rangeOfString:@".am"].length > 0 || [string rangeOfString:@".ly"].length > 0 || [string rangeOfString:@"http"].length > 0) {
            NSRange rangeOfHttp = [self.tweetText rangeOfString:string];
            [dictionaryOfRanges setValue:[NSValue valueWithRange:rangeOfHttp] forKey:@"url"];
        }
        
        if ([string rangeOfString:@"@"].length > 0 && [string length] > 1) {
            NSRange rangeOfUsernames = [self.tweetText rangeOfString:string];
            [dictionaryOfRanges setValue:[NSValue valueWithRange:rangeOfUsernames] forKey:@"username"];
        }
        
        
    }
    
    
    NSRange hashRange = [dictionaryOfRanges[@"hash"] rangeValue];
    NSRange urlRange = [dictionaryOfRanges[@"url"] rangeValue];
    NSRange userNameRange = [dictionaryOfRanges[@"username"] rangeValue];
    
   if (hashRange.length > 0) {
        [tweetTextAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(__bridge id)(listColorLocal) range:hashRange];
    }
    
    if (urlRange.length > 0) {
        [tweetTextAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(__bridge id)(listColorLocal) range:urlRange];
    }
    
    if (userNameRange.length > 0) {
        [tweetTextAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(__bridge id)(listColorLocal) range:userNameRange];
    }
    CFRelease(listColorLocal);
    
    return (NSAttributedString *)tweetTextAttributedString;
    
}


@end
