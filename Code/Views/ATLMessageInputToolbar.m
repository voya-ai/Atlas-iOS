//
//  ATLUIMessageInputToolbar.m
//  Atlas
//
//  Created by Kevin Coleman on 9/18/14.
//  Copyright (c) 2015 Layer. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
#import "ATLMessageInputToolbar.h"
#import "ATLConstants.h"
#import "ATLMediaAttachment.h"
#import "ATLMessagingUtilities.h"
#import "ATLUIImageHelper.h"
#import "ATLGifPickerViewController.h"
#import "LocalDiskDataCache.h"

NSString *const ATLMessageInputToolbarDidChangeHeightNotification = @"ATLMessageInputToolbarDidChangeHeightNotification";

@interface ATLMessageInputToolbar () <UITextViewDelegate, ATLGifPickerDelegate>

@property (nonatomic) NSArray *mediaAttachments;
@property (nonatomic, copy) NSAttributedString *attributedStringForMessageParts;
@property (nonatomic) UITextView *dummyTextView;
@property (nonatomic) CGFloat textViewMaxHeight;
@property (nonatomic) CGFloat buttonCenterY;
@property (nonatomic) BOOL firstAppearance;

@end

@implementation ATLMessageInputToolbar

NSString *const ATLMessageInputToolbarAccessibilityLabel = @"Message Input Toolbar";
NSString *const ATLMessageInputToolbarTextInputView = @"Message Input Toolbar Text Input View";
NSString *const ATLMessageInputToolbarCameraButton  = @"Message Input Toolbar Camera Button";
NSString *const ATLMessageInputToolbarLocationButton  = @"Message Input Toolbar Location Button";
NSString *const ATLMessageInputToolbarSendButton  = @"Message Input Toolbar Send Button";
NSString *const ATLMessageInputToolbarGIFButton = @"Message Input Toolbar GIF Button";

// Compose View Margin Constants
static CGFloat const ATLLeftButtonHorizontalMargin = 6.0f;
static CGFloat const ATLRightButtonHorizontalMargin = 4.0f;
static CGFloat const ATLVerticalMargin = 7.0f;

// Compose View Button Constants
static CGFloat const ATLLeftAccessoryButtonWidth = 40.0f;
static CGFloat const ATLRightAccessoryButtonDefaultWidth = 46.0f;
static CGFloat const ATLRightAccessoryButtonPadding = 5.3f;
static CGFloat const ATLButtonHeight = 28.0f;

// GIF Tray Size Constants
static CGFloat const ATLGIFTrayHeight = 120.f;

+ (void)initialize
{
    ATLMessageInputToolbar *proxy = [self appearance];
    proxy.rightAccessoryButtonActiveColor = ATLBlueColor();
    proxy.rightAccessoryButtonDisabledColor = [UIColor grayColor];
    proxy.rightAccessoryButtonFont = [UIFont boldSystemFontOfSize:17];
}

- (id)init
{
    self = [super init];
    if (self) {
        self.accessibilityLabel = ATLMessageInputToolbarAccessibilityLabel;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        NSBundle *resourcesBundle = ATLResourcesBundle();
        self.leftAccessoryImage = [UIImage imageNamed:@"camera_dark" inBundle:resourcesBundle compatibleWithTraitCollection:nil];
        self.rightAccessoryImage = [UIImage imageNamed:@"location_dark" inBundle:resourcesBundle compatibleWithTraitCollection:nil];
        self.displaysRightAccessoryImage = YES;
        self.firstAppearance = YES;
        
        self.leftAccessoryButton = [[UIButton alloc] init];
        self.leftAccessoryButton.accessibilityLabel = ATLMessageInputToolbarCameraButton;
        self.leftAccessoryButton.contentMode = UIViewContentModeScaleAspectFit;
        [self.leftAccessoryButton setImage:self.leftAccessoryImage forState:UIControlStateNormal];
        [self.leftAccessoryButton addTarget:self action:@selector(leftAccessoryButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.leftAccessoryButton];
        
        self.textInputView = [[ATLMessageComposeTextView alloc] init];
        self.textInputView.accessibilityLabel = ATLMessageInputToolbarTextInputView;
        self.textInputView.delegate = self;
        self.textInputView.layer.borderColor = ATLGrayColor().CGColor;
        self.textInputView.layer.borderWidth = 0.5;
        self.textInputView.layer.cornerRadius = 5.0f;
        [self addSubview:self.textInputView];
        
        self.verticalMargin = ATLVerticalMargin;
        
        self.rightAccessoryButton = [[UIButton alloc] init];
        [self.rightAccessoryButton addTarget:self action:@selector(rightAccessoryButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        self.rightAccessoryButtonTitle = @"Send";
        [self addSubview:self.rightAccessoryButton];
        [self configureRightAccessoryButtonState];
        
        self.gifPicker = [ATLGifPickerViewController new];
        [self.gifPicker.view setHidden:YES];
        [self.gifPicker setGifPickerDelegate:self];
        [self addSubview:self.gifPicker.view];
        
        UISwipeGestureRecognizer *upSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showGifPicker)];
        [upSwipeGesture setDirection:UISwipeGestureRecognizerDirectionUp];
        [self addGestureRecognizer:upSwipeGesture];
        
        UISwipeGestureRecognizer *downSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(hideGifPicker)];
        [downSwipeGesture setDirection:UISwipeGestureRecognizerDirectionDown];
        [self addGestureRecognizer:downSwipeGesture];
        
        // Calling sizeThatFits: or contentSize on the displayed UITextView causes the cursor's position to momentarily appear out of place and prevent scrolling to the selected range. So we use another text view for height calculations.
        self.dummyTextView = [[ATLMessageComposeTextView alloc] init];
        self.maxNumberOfLines = 8;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.firstAppearance) {
        [self configureRightAccessoryButtonState];
        self.firstAppearance = NO;
    }
    
    // set the font for the dummy text view as well
    self.dummyTextView.font = self.textInputView.font;
    
    // We layout the views manually since using Auto Layout seems to cause issues in this context (i.e. an auto height resizing text view in an input accessory view) especially with iOS 7.1.
    CGRect frame = self.frame;
    CGRect leftButtonFrame = self.leftAccessoryButton.frame;
    CGRect rightButtonFrame = self.rightAccessoryButton.frame;
    CGRect textViewFrame = self.textInputView.frame;
    
    if (!self.leftAccessoryButton) {
        leftButtonFrame.size.width = 0;
    } else {
        leftButtonFrame.size.width = ATLLeftAccessoryButtonWidth;
    }
    
    // This makes the input accessory view work with UISplitViewController to manage the frame width.
    if (self.containerViewController) {
        CGRect windowRect = [self.containerViewController.view.superview convertRect:self.containerViewController.view.frame toView:nil];
        frame.size.width = windowRect.size.width;
        frame.origin.x = windowRect.origin.x;
    }
    
    leftButtonFrame.size.height = ATLButtonHeight;
    leftButtonFrame.origin.x = ATLLeftButtonHorizontalMargin;
    
    if (self.rightAccessoryButtonFont && (self.textInputView.text.length || !self.displaysRightAccessoryImage)) {
        rightButtonFrame.size.width = CGRectIntegral([ATLLocalizedString(@"atl.messagetoolbar.send.key", self.rightAccessoryButtonTitle, nil) boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:0 attributes:@{NSFontAttributeName: self.rightAccessoryButtonFont} context:nil]).size.width + ATLRightAccessoryButtonPadding;
    } else {
        rightButtonFrame.size.width = ATLRightAccessoryButtonDefaultWidth;
    }
    
    rightButtonFrame.size.height = ATLButtonHeight;
    rightButtonFrame.origin.x = CGRectGetWidth(frame) - CGRectGetWidth(rightButtonFrame) - ATLRightButtonHorizontalMargin;
    
    textViewFrame.origin.x = CGRectGetMaxX(leftButtonFrame) + ATLLeftButtonHorizontalMargin;
    textViewFrame.origin.y = self.verticalMargin;
    textViewFrame.size.width = CGRectGetMinX(rightButtonFrame) - CGRectGetMinX(textViewFrame) - ATLRightButtonHorizontalMargin;
    
    self.dummyTextView.attributedText = self.textInputView.attributedText;
    CGSize fittedTextViewSize = [self.dummyTextView sizeThatFits:CGSizeMake(CGRectGetWidth(textViewFrame), MAXFLOAT)];
    textViewFrame.size.height = ceil(MIN(fittedTextViewSize.height, self.textViewMaxHeight));
    
    textViewFrame.origin.y = CGRectGetHeight(frame) - self.verticalMargin - textViewFrame.size.height;
    
    //TODO move height value into configurable property or variable
    frame.size.height = _gifsEnabled ? ATLGIFTrayHeight : CGRectGetHeight(textViewFrame) + self.verticalMargin * 2;
    frame.origin.y -= frame.size.height - CGRectGetHeight(self.frame);
    
    // Only calculate button centerY once to anchor it to bottom of bar.
    if (!self.buttonCenterY) {
        self.buttonCenterY = (CGRectGetHeight(frame) - CGRectGetHeight(leftButtonFrame)) / 2;
    }
    leftButtonFrame.origin.y = frame.size.height - leftButtonFrame.size.height - self.buttonCenterY;
    rightButtonFrame.origin.y = frame.size.height - rightButtonFrame.size.height - self.buttonCenterY;
    
    BOOL heightChanged = CGRectGetHeight(frame) != CGRectGetHeight(self.frame);
    
    self.leftAccessoryButton.frame = leftButtonFrame;
    self.rightAccessoryButton.frame = rightButtonFrame;
    self.textInputView.frame = textViewFrame;
    
    //position the gif picker if necessary
    if(_gifsEnabled)
    {
        [_gifPicker.view setHidden:NO];
        CGRect gifPickerFrame = CGRectMake(ATLLeftButtonHorizontalMargin,
                                           self.verticalMargin,
                                           self.frame.size.width - self.verticalMargin * 2,
                                           self.frame.size.height - textViewFrame.size.height - self.verticalMargin * 3);
        [_gifPicker.view setFrame:gifPickerFrame];
    }
    else
        [_gifPicker.view setHidden:YES];
    
    // Setting one's own frame like this is a no-no but seems to be the lesser of evils when working around the layout issues mentioned above.
    self.frame = frame;
    
    if (heightChanged) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ATLMessageInputToolbarDidChangeHeightNotification object:self];
    }
}

- (void)paste:(id)sender
{
    NSData *gifData = [[UIPasteboard generalPasteboard] dataForPasteboardType:@"com.compuserve.gif"];
    if(gifData) {
        
        //GIF approach #1: Works, but requires the GIF data to be saved to a file
        //temporary -- save the GIF clipboard data to a local file URL
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        NSURL *baseURL = [NSURL fileURLWithPath:basePath isDirectory:YES];
        NSURL *outputDirURL = [NSURL URLWithString:@"com.layer.atlas" relativeToURL:baseURL];
        NSURL *outputURL = [NSURL URLWithString:@"clipboard_gif.gif" relativeToURL:outputDirURL];
        [[NSFileManager defaultManager] createDirectoryAtURL:outputDirURL withIntermediateDirectories:YES attributes:nil error:nil];
        [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
        
        [gifData writeToURL:outputURL atomically:YES];
        ATLMediaAttachment *mediaAttachment = [ATLMediaAttachment mediaAttachmentWithFileURL:outputURL thumbnailSize:ATLDefaultGIFThumbnailSize];
        [self insertMediaAttachment:mediaAttachment withEndLineBreak:YES];
        
        //GIF approach #2: Does not work
        /*
         UIImage *image = ATLAnimatedImageWithAnimatedGIFData(gifData);
         ATLMediaAttachment *mediaAttachment = [ATLMediaAttachment mediaAttachmentWithGIF:image metadata:nil thumbnailSize:ATLDefaultGIFThumbnailSize];
         [self insertMediaAttachment:mediaAttachment withEndLineBreak:YES];
         }
         NSData *imageData = [[UIPasteboard generalPasteboard] dataForPasteboardType:ATLPasteboardImageKey];
         if (imageData) {
         UIImage *image = [UIImage imageWithData:imageData];
         ATLMediaAttachment *mediaAttachment = [ATLMediaAttachment mediaAttachmentWithImage:image
         metadata:nil
         thumbnailSize:ATLDefaultThumbnailSize];
         [self insertMediaAttachment:mediaAttachment withEndLineBreak:YES];
         */
    }
}

#pragma mark - Public Methods

- (void)setMaxNumberOfLines:(NSUInteger)maxNumberOfLines
{
    _maxNumberOfLines = maxNumberOfLines;
    self.textViewMaxHeight = self.maxNumberOfLines * self.textInputView.font.lineHeight;
    [self setNeedsLayout];
}

- (void)insertMediaAttachment:(ATLMediaAttachment *)mediaAttachment withEndLineBreak:(BOOL)endLineBreak;
{
    UITextView *textView = self.textInputView;
    
    NSMutableAttributedString *attributedString = [textView.attributedText mutableCopy];
    NSAttributedString *lineBreak = [[NSAttributedString alloc] initWithString:@"\n" attributes:@{NSFontAttributeName: self.textInputView.font}];
    if (attributedString.length > 0 && ![textView.text hasSuffix:@"\n"]) {
        [attributedString appendAttributedString:lineBreak];
    }
    
    NSMutableAttributedString *attachmentString = (mediaAttachment.mediaMIMEType == ATLMIMETypeTextPlain) ? [[NSAttributedString alloc] initWithString:mediaAttachment.textRepresentation] : [[NSAttributedString attributedStringWithAttachment:mediaAttachment] mutableCopy];
    [attributedString appendAttributedString:attachmentString];
    if (endLineBreak) {
        [attributedString appendAttributedString:lineBreak];
    }
    [attributedString addAttribute:NSFontAttributeName value:textView.font range:NSMakeRange(0, attributedString.length)];
    if (textView.textColor) {
        [attributedString addAttribute:NSForegroundColorAttributeName value:textView.textColor range:NSMakeRange(0, attributedString.length)];
    }
    textView.attributedText = attributedString;
    if ([self.inputToolBarDelegate respondsToSelector:@selector(messageInputToolbarDidType:)]) {
        [self.inputToolBarDelegate messageInputToolbarDidType:self];
    }
    [self setNeedsLayout];
    [self configureRightAccessoryButtonState];
}

- (NSArray *)mediaAttachments
{
    NSAttributedString *attributedString = self.textInputView.attributedText;
    if (!_mediaAttachments || ![attributedString isEqualToAttributedString:self.attributedStringForMessageParts]) {
        self.attributedStringForMessageParts = attributedString;
        _mediaAttachments = [self mediaAttachmentsFromAttributedString:attributedString];
    }
    return _mediaAttachments;
}

- (void)setLeftAccessoryImage:(UIImage *)leftAccessoryImage
{
    _leftAccessoryImage = leftAccessoryImage;
    [self.leftAccessoryButton setImage:leftAccessoryImage  forState:UIControlStateNormal];
}

- (void)setRightAccessoryImage:(UIImage *)rightAccessoryImage
{
    _rightAccessoryImage = rightAccessoryImage;
    [self.rightAccessoryButton setImage:rightAccessoryImage forState:UIControlStateNormal];
}

- (void)setRightAccessoryButtonActiveColor:(UIColor *)rightAccessoryButtonActiveColor
{
    _rightAccessoryButtonActiveColor = rightAccessoryButtonActiveColor;
    [self.rightAccessoryButton setTitleColor:rightAccessoryButtonActiveColor forState:UIControlStateNormal];
}

- (void)setRightAccessoryButtonDisabledColor:(UIColor *)rightAccessoryButtonDisabledColor
{
    _rightAccessoryButtonDisabledColor = rightAccessoryButtonDisabledColor;
    [self.rightAccessoryButton setTitleColor:rightAccessoryButtonDisabledColor forState:UIControlStateDisabled];
}

- (void)setRightAccessoryButtonFont:(UIFont *)rightAccessoryButtonFont
{
    _rightAccessoryButtonFont = rightAccessoryButtonFont;
    [self.rightAccessoryButton.titleLabel setFont:rightAccessoryButtonFont];
}

-(void)showGifPicker
{
    if(_gifsEnabled)
        return;
    
    _gifsEnabled = YES;
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
    [UIView animateWithDuration:.3f animations:^{
        [self layoutIfNeeded];
    }];
    
    [_gifPicker newRequesterForQuery:[self getGIFSearchText]];
}

-(void)hideGifPicker
{
    _gifsEnabled = NO;
    
    [_gifPicker clearAllCells];
    
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
    [UIView animateWithDuration:.3f animations:^{
        [self layoutIfNeeded];
    }];
}

#pragma mark - Actions

- (void)leftAccessoryButtonTapped
{
    if(self.textInputView.text.length)
    {
        _gifsEnabled = !_gifsEnabled;
        [self setNeedsLayout];
        [self layoutIfNeeded];
        
        if(_gifsEnabled)
        {
            [_gifPicker newRequesterForQuery:[self getGIFSearchText]];
        }
    }
    else
        [self.inputToolBarDelegate messageInputToolbar:self didTapLeftAccessoryButton:self.leftAccessoryButton];
}

- (void)rightAccessoryButtonTapped
{
    [self acceptAutoCorrectionSuggestion];
    if ([self.inputToolBarDelegate respondsToSelector:@selector(messageInputToolbarDidEndTyping:)]) {
        [self.inputToolBarDelegate messageInputToolbarDidEndTyping:self];
    }
    [self.inputToolBarDelegate messageInputToolbar:self didTapRightAccessoryButton:self.rightAccessoryButton];
    self.textInputView.text = @"";
    [self setNeedsLayout];
    self.mediaAttachments = nil;
    self.attributedStringForMessageParts = nil;
    [self configureRightAccessoryButtonState];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    if (self.rightAccessoryButton.imageView) {
        [self configureRightAccessoryButtonState];
    }
    
    if(self.leftAccessoryButton.imageView) {
        [self configureLeftAccessoryButtonState];
    }
    
    if (textView.text.length > 0 && [self.inputToolBarDelegate respondsToSelector:@selector(messageInputToolbarDidType:)]) {
        [self.inputToolBarDelegate messageInputToolbarDidType:self];
    } else if (textView.text.length == 0 && [self.inputToolBarDelegate respondsToSelector:@selector(messageInputToolbarDidEndTyping:)]) {
        [self.inputToolBarDelegate messageInputToolbarDidEndTyping:self];
    }
    
    if(_gifsEnabled)
        [_gifPicker newRequesterForQuery:[self getGIFSearchText]];
    
    [self setNeedsLayout];
    
    CGRect line = [textView caretRectForPosition:textView.selectedTextRange.start];
    CGFloat overflow = line.origin.y + line.size.height - (textView.contentOffset.y + textView.bounds.size.height - textView.contentInset.bottom - textView.contentInset.top);
    if (overflow > 0) {
        // We are at the bottom of the visible text and introduced a line feed, scroll down. Scroll caret to visible area
        CGPoint offset = textView.contentOffset;
        offset.y += overflow;
        
        // Cannot animate with setContentOffset:animated: or caret will not appear
        [UIView animateWithDuration:.2 animations:^{
            [textView setContentOffset:offset];
        }];
    }
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    // Workaround for automatic scrolling not occurring in some cases.
    [textView scrollRangeToVisible:textView.selectedRange];
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange
{
    return YES;
}

#pragma mark - <ATLGifPickerDelegate> methods
-(void)gifSelectedAtURL:(NSString *)url
{
    NSURL *outputURL = [[LocalDiskDataCache defaultCache] fileLocationForDataStoredAtKey:url];
    ATLMediaAttachment *mediaAttachment = [ATLMediaAttachment mediaAttachmentWithFileURL:outputURL thumbnailSize:ATLDefaultGIFThumbnailSize];
    if([self.inputToolBarDelegate respondsToSelector:@selector(messageInputToolbar:didRequestAttachmentSend:)])
        [self.inputToolBarDelegate messageInputToolbar:self didRequestAttachmentSend:mediaAttachment];
}

#pragma mark - Helpers

- (NSArray *)mediaAttachmentsFromAttributedString:(NSAttributedString *)attributedString
{
    NSMutableArray *mediaAttachments = [NSMutableArray new];
    [attributedString enumerateAttribute:NSAttachmentAttributeName inRange:NSMakeRange(0, attributedString.length) options:0 usingBlock:^(id attachment, NSRange range, BOOL *stop) {
        if ([attachment isKindOfClass:[ATLMediaAttachment class]]) {
            ATLMediaAttachment *mediaAttachment = (ATLMediaAttachment *)attachment;
            [mediaAttachments addObject:mediaAttachment];
            return;
        }
        NSAttributedString *attributedSubstring = [attributedString attributedSubstringFromRange:range];
        NSString *substring = attributedSubstring.string;
        NSString *trimmedSubstring = [substring stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmedSubstring.length == 0) {
            return;
        }
        ATLMediaAttachment *mediaAttachment = [ATLMediaAttachment mediaAttachmentWithText:trimmedSubstring];
        [mediaAttachments addObject:mediaAttachment];
    }];
    return mediaAttachments;
}

- (void)acceptAutoCorrectionSuggestion
{
    // This is a workaround to accept the current auto correction suggestion while not resigning as first responder. From: http://stackoverflow.com/a/27865136
    [self.textInputView.inputDelegate selectionWillChange:self.textInputView];
    [self.textInputView.inputDelegate selectionDidChange:self.textInputView];
}

- (NSString *)getGIFSearchText
{
    NSString *currentlyTypedText = _textInputView.text;
    if (currentlyTypedText.length > 0) {
        return currentlyTypedText;
    }
    
    if ([_inputToolBarDelegate respondsToSelector:@selector(messageInputToolbarDidRequestLastMessage:)]) {
        LYRMessage *lastSentMessage = [_inputToolBarDelegate messageInputToolbarDidRequestLastMessage:self];
        if (lastSentMessage != nil && lastSentMessage.parts.count > 0) {
            
            LYRMessagePart *messagePart = [lastSentMessage.parts firstObject];
            if ([messagePart.MIMEType isEqualToString:ATLMIMETypeTextPlain]) {
                return [[NSString alloc] initWithData:messagePart.data encoding:NSUTF8StringEncoding];
            }
        }
    }
    
    return @"";
}

#pragma mark - Send Button Enablement

- (void)configureLeftAccessoryButtonState
{
    if(self.textInputView.text.length) {
        [self configureLeftAccessoryButtonForGIF];
    } else {
        [self configureLeftAccessoryButtonForCamera];
    }
}

-(void)configureLeftAccessoryButtonForCamera
{
    self.leftAccessoryButton.accessibilityLabel = ATLMessageInputToolbarCameraButton;
    [self.leftAccessoryButton setImage:self.leftAccessoryImage forState:UIControlStateNormal];
    [self.leftAccessoryButton setTitle:nil forState:UIControlStateNormal];
    [self.leftAccessoryButton addTarget:self action:@selector(leftAccessoryButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.leftAccessoryButton];
}

-(void)configureLeftAccessoryButtonForGIF
{
    self.leftAccessoryButton.accessibilityLabel = ATLMessageInputToolbarGIFButton;
    [self.leftAccessoryButton setImage:nil forState:UIControlStateNormal];
    self.leftAccessoryButton.contentEdgeInsets = UIEdgeInsetsZero;
    self.leftAccessoryButton.titleLabel.font = self.rightAccessoryButtonFont;
    
    [self.leftAccessoryButton setTitle:@"GIF" forState:UIControlStateNormal];
    [self.leftAccessoryButton setTitleColor:self.rightAccessoryButtonActiveColor forState:UIControlStateNormal];
    [self.leftAccessoryButton setTitleColor:self.rightAccessoryButtonDisabledColor forState:UIControlStateDisabled];
    [self.leftAccessoryButton setEnabled:YES];
}

- (void)configureRightAccessoryButtonState
{
    if (self.textInputView.text.length) {
        [self configureRightAccessoryButtonForText];
        self.rightAccessoryButton.enabled = YES;
    } else {
        if (self.displaysRightAccessoryImage) {
            [self configureRightAccessoryButtonForImage];
            self.rightAccessoryButton.enabled = YES;
        } else {
            [self configureRightAccessoryButtonForText];
            self.rightAccessoryButton.enabled = NO;
        }
    }
}

- (void)configureRightAccessoryButtonForText
{
    self.rightAccessoryButton.accessibilityLabel = ATLMessageInputToolbarSendButton;
    [self.rightAccessoryButton setImage:nil forState:UIControlStateNormal];
    self.rightAccessoryButton.contentEdgeInsets = UIEdgeInsetsMake(2, 0, 0, 0);
    self.rightAccessoryButton.titleLabel.font = self.rightAccessoryButtonFont;
    [self.rightAccessoryButton setTitle:ATLLocalizedString(@"atl.messagetoolbar.send.key", self.rightAccessoryButtonTitle, nil) forState:UIControlStateNormal];
    [self.rightAccessoryButton setTitleColor:self.rightAccessoryButtonActiveColor forState:UIControlStateNormal];
    [self.rightAccessoryButton setTitleColor:self.rightAccessoryButtonDisabledColor forState:UIControlStateDisabled];
    if (!self.displaysRightAccessoryImage && !self.textInputView.text.length) {
        self.rightAccessoryButton.enabled = NO;
    } else {
        self.rightAccessoryButton.enabled = YES;
    }
}

- (void)configureRightAccessoryButtonForImage
{
    self.rightAccessoryButton.enabled = YES;
    self.rightAccessoryButton.accessibilityLabel = ATLMessageInputToolbarLocationButton;
    self.rightAccessoryButton.contentEdgeInsets = UIEdgeInsetsZero;
    [self.rightAccessoryButton setTitle:nil forState:UIControlStateNormal];
    [self.rightAccessoryButton setImage:self.rightAccessoryImage forState:UIControlStateNormal];
}


@end
