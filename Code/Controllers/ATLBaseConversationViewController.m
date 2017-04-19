//
//  ATLBaseConversationViewController.m
//  Atlas
//
//  Created by Kevin Coleman on 10/27/14.
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

#import "ATLBaseConversationViewController.h"
#import "ATLConversationView.h"
#import "DAKeyboardControl.h"

static inline BOOL atl_systemVersionLessThan(NSString * _Nonnull systemVersion) {
    return [[[UIDevice currentDevice] systemVersion] compare:systemVersion options:NSNumericSearch] == NSOrderedAscending;
}

@interface ATLBaseConversationViewController ()

@property (nonatomic) ATLConversationView *view;
@property (nonatomic) NSMutableArray *typingParticipantIDs;
@property (nonatomic) NSLayoutConstraint *typingIndicatorViewBottomConstraint;
@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic) CGFloat keyboardInset;
@property (nonatomic) BOOL canScroll;

@property (nonatomic, getter=isFirstAppearance) BOOL firstAppearance;

@end

@implementation ATLBaseConversationViewController

@dynamic view;

static CGFloat const ATLTypingIndicatorHeight = 20;
static CGFloat const ATLMaxScrollDistanceFromBottom = 150;

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self baseCommonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        [self baseCommonInit];
    }
    return self;
}

- (void)baseCommonInit
{
    _displaysAddressBar = NO;
    _typingParticipantIDs = [NSMutableArray new];
    _firstAppearance = YES;
}

- (void)loadView
{
    self.view = [ATLConversationView new];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Add message input tool bar
    self.messageInputToolbar = [self initializeMessageInputToolbar];
    // Fixes an ios9 bug that causes the background of the input accessory view to be black when being presented on screen.
    self.messageInputToolbar.translucent = NO;
    // An apparent system bug causes a view controller to not be deallocated
    // if the view controller's own inputAccessoryView property is used.
    
    
    [self.view addSubview:self.messageInputToolbar];
//    self.view.inputAccessoryView = self.messageInputToolbar;
    self.messageInputToolbar.containerViewController = self;
    
    // Add typing indicator
    self.typingIndicatorController = [[ATLTypingIndicatorViewController alloc] init];
    [self addChildViewController:self.typingIndicatorController];
    [self.view addSubview:self.typingIndicatorController.view];
    [self.typingIndicatorController didMoveToParentViewController:self];
    [self configureTypingIndicatorLayoutConstraints];
    
    // Add address bar if needed
    if (self.displaysAddressBar) {
        self.addressBarController = [[ATLAddressBarViewController alloc] init];
        [self addChildViewController:self.addressBarController];
        [self.view addSubview:self.addressBarController.view];
        [self.addressBarController didMoveToParentViewController:self];
        [self configureAddressbarLayoutConstraints];
    }
    [self atl_baseRegisterForNotifications];
}

- (ATLMessageInputToolbar *)initializeMessageInputToolbar
{
    return [ATLMessageInputToolbar new];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Workaround for a modal dismissal causing the message toolbar to remain offscreen on iOS 8.
    if (self.presentedViewController) {
        [self.view becomeFirstResponder];
    }
    if (self.addressBarController && self.firstAppearance) {
        [self updateTopCollectionViewInset];
    }
    [self updateBottomCollectionViewInset];
    
    if (self.isFirstAppearance) {
        self.firstAppearance = NO;
        // We use the content size of the actual collection view when calculating the ammount to scroll. Hence, we layout the collection view before scrolling to the bottom.
        //        [self.view layoutIfNeeded];
        self.canScroll = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.canScroll = YES;
            [self scrollToBottomAnimated:NO];
            self.canScroll = NO;
            
            if (self.displaysAddressBar) {
                [self updateTopCollectionViewInset];
            }
        });
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.messageInputToolbar.translucent = YES;
    self.canScroll = YES;
}

- (CGFloat)tabBarHeight
{
    return self.hidesBottomBarWhenPushed ? 0 : self.tabBarController.tabBar.bounds.size.height;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    // Determine the frame for the messageInputToolbar
    CGFloat toolbarHeight = self.messageInputToolbar.frame.size.height;
    CGFloat tabBarHeight = [self tabBarHeight];
    CGRect frame = self.messageInputToolbar.frame;
    CGFloat keyboardY = self.view.bounds.size.height - self.keyboardInset;
    
    if (self.keyboardInset > 0) {
        frame.origin.y =  keyboardY - toolbarHeight;
    } else {
        frame.origin.y =  keyboardY - tabBarHeight - toolbarHeight;
    }
    
    CGFloat maxY = self.view.bounds.size.height - tabBarHeight - toolbarHeight;
    frame.origin.y = MIN(frame.origin.y, maxY);
    
    frame.size.width = self.view.bounds.size.width;

    self.messageInputToolbar.frame = frame;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.messageInputToolbar.translucent = NO;
    if (atl_systemVersionLessThan(@"10.0")) {
        // Workaround for view's content flashing onscreen after pop animation concludes on iOS 9.
        BOOL isPopping = ![self.navigationController.viewControllers containsObject:self];
        if (isPopping) {
            [self.messageInputToolbar.textInputView resignFirstResponder];
        }
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public Setters 

- (void)setCollectionView:(UICollectionView *)collectionView
{
    _collectionView = collectionView;
    _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.collectionView];
    [self configureCollectionViewLayoutConstraints];
}

- (void)setTypingIndicatorInset:(CGFloat)typingIndicatorInset
{
    _typingIndicatorInset = typingIndicatorInset;
    [UIView animateWithDuration:0.1 animations:^{
        [self updateBottomCollectionViewInset];
    }];
}

#pragma mark - Public Methods

- (BOOL)shouldScrollToBottom
{
    // Returns YES if the last row of the collection view is currently visible
    NSArray<NSIndexPath *> *indexPathsForVisibleItems = self.collectionView.indexPathsForVisibleItems;
    
    NSInteger lastSectionIndex = [self.collectionView numberOfSections] - 1;
    NSInteger lastRowIndex = [self.collectionView numberOfItemsInSection:lastSectionIndex] - 1;
    NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:lastRowIndex inSection:lastSectionIndex];
    
    return [indexPathsForVisibleItems containsObject:lastIndexPath];
}

- (void)scrollToBottomAnimated:(BOOL)animated
{
    if (!self.canScroll) {
        return;
    }
    CGSize contentSize = self.collectionView.contentSize;
    [self.collectionView setContentOffset:[self bottomOffsetForContentSize:contentSize] animated:animated];
}

#pragma mark - Content Inset Management  

- (void)updateTopCollectionViewInset
{
    [self.addressBarController.view layoutIfNeeded];
    
    UIEdgeInsets contentInset = self.collectionView.contentInset;
    UIEdgeInsets scrollIndicatorInsets = self.collectionView.scrollIndicatorInsets;
    CGRect frame = [self.view convertRect:self.addressBarController.addressBarView.frame fromView:self.addressBarController.addressBarView.superview];
    
    contentInset.top = CGRectGetMaxY(frame);
    scrollIndicatorInsets.top = contentInset.top;
    self.collectionView.contentInset = contentInset;
    self.collectionView.scrollIndicatorInsets = scrollIndicatorInsets;
}

- (void)updateBottomCollectionViewInset
{
    [self.messageInputToolbar layoutIfNeeded];
    
    UIEdgeInsets insets = self.collectionView.contentInset;
    CGFloat toolbarInset = self.view.bounds.size.height - CGRectGetMinY(self.messageInputToolbar.frame);
    
    insets.bottom = toolbarInset + self.typingIndicatorInset;
    self.collectionView.scrollIndicatorInsets = insets;
    self.collectionView.contentInset = insets;
    self.typingIndicatorViewBottomConstraint.constant = -toolbarInset;
}

#pragma mark - Notification Handlers

- (void)messageInputToolbarDidChangeHeight:(NSNotification *)notification
{
    if (!self.messageInputToolbar.superview) {
       return;
    }
    
    CGRect toolbarFrame = self.messageInputToolbar.frame;
    CGFloat keyboardOnscreenHeight = CGRectGetHeight(self.view.frame) - CGRectGetMinY(toolbarFrame);
    if (keyboardOnscreenHeight == self.keyboardHeight) return;
    
    BOOL messagebarDidGrow = keyboardOnscreenHeight > self.keyboardHeight;
    self.keyboardHeight = keyboardOnscreenHeight;
    
     self.typingIndicatorViewBottomConstraint.constant = -self.collectionView.scrollIndicatorInsets.bottom;
    [self updateBottomCollectionViewInset];
    
    if ([self shouldScrollToBottom] && messagebarDidGrow) {
        [self scrollToBottomAnimated:YES];
    }
}

- (void)textViewTextDidBeginEditing:(NSNotification *)notification
{
    [self scrollToBottomAnimated:YES];
}

#pragma mark - Helpers

- (CGPoint)bottomOffsetForContentSize:(CGSize)contentSize
{
    CGFloat contentSizeHeight = contentSize.height;
    CGFloat collectionViewFrameHeight = self.collectionView.frame.size.height;
    CGFloat collectionViewBottomInset = self.collectionView.contentInset.bottom;
    CGFloat collectionViewTopInset = self.collectionView.contentInset.top;
    CGPoint offset = CGPointMake(0, MAX(-collectionViewTopInset, contentSizeHeight - (collectionViewFrameHeight - collectionViewBottomInset)));
    return offset;
}

- (void)updateViewConstraints
{
    CGFloat typingIndicatorBottomConstraintConstant = -self.collectionView.scrollIndicatorInsets.bottom;
    if (self.messageInputToolbar.superview) {
        CGRect toolbarFrame = [self.view convertRect:self.messageInputToolbar.frame fromView:self.messageInputToolbar.superview];
        CGFloat keyboardOnscreenHeight = CGRectGetHeight(self.view.frame) - CGRectGetMinY(toolbarFrame);
        if (-keyboardOnscreenHeight > typingIndicatorBottomConstraintConstant) {
            typingIndicatorBottomConstraintConstant = -keyboardOnscreenHeight;
        }
    }
    self.typingIndicatorViewBottomConstraint.constant = typingIndicatorBottomConstraintConstant;
    [super updateViewConstraints];
}

#pragma mark - Auto Layout

- (void)configureCollectionViewLayoutConstraints
{
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.collectionView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.collectionView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.collectionView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.collectionView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
}

- (void)configureTypingIndicatorLayoutConstraints
{
    // Typing Indicator
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.typingIndicatorController.view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.typingIndicatorController.view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.typingIndicatorController.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:ATLTypingIndicatorHeight]];
    self.typingIndicatorViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.typingIndicatorController.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
    [self.view addConstraint:self.typingIndicatorViewBottomConstraint];
}

- (void)configureAddressbarLayoutConstraints
{
    // Address Bar
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.addressBarController.view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.addressBarController.view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.addressBarController.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.addressBarController.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
}

#pragma mark - Notification Registration 

- (void)atl_baseRegisterForNotifications
{
    __weak typeof(self) weakSelf = self;
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView, BOOL opening, BOOL closing) {
        NSLog(@"frame => %@", NSStringFromCGRect(keyboardFrameInView));
    
        CGRect keyboardEndFrameIntersectingView = CGRectIntersection(weakSelf.view.bounds, keyboardFrameInView);
        weakSelf.keyboardInset = keyboardEndFrameIntersectingView.size.height;
        
//        if (opening || closing) {
//            [UIView beginAnimations:nil context:nil];
//            [UIView setAnimationDuration:0.1];
//        }
        [weakSelf.view setNeedsLayout];
        [weakSelf.view layoutIfNeeded];
        [weakSelf updateBottomCollectionViewInset];
        
//        if (opening || closing) {
//            [UIView commitAnimations];
//        }
    }];

    // ATLMessageInputToolbar Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewTextDidBeginEditing:) name:UITextViewTextDidBeginEditingNotification object:self.messageInputToolbar.textInputView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageInputToolbarDidChangeHeight:) name:ATLMessageInputToolbarDidChangeHeightNotification object:self.messageInputToolbar];
}

@end
