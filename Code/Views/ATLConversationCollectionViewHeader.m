//
//  ATLUIConversationCollectionViewHeader.m
//  Atlas
//
//  Created by Kevin Coleman on 9/10/14.
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
#import "ATLConversationCollectionViewHeader.h"
#import "ATLConstants.h"
#import "ATLMessagingUtilities.h"

@interface ATLConversationCollectionViewHeader ()

@property (nonatomic) UILabel *dateLabel;
@property (nonatomic) UILabel *participantLabel;
@property (nonatomic) UIView *dateSeparatorView;

@end

@implementation ATLConversationCollectionViewHeader

NSString *const ATLConversationViewHeaderIdentifier = @"ATLConversationViewHeaderIdentifier";

CGFloat const ATLConversationViewHeaderParticipantLeftPadding = 60;
CGFloat const ATLConversationViewHeaderHorizontalPadding = 15;
CGFloat const ATLConversationViewHeaderTopPadding = 10;
CGFloat const ATLConversationViewHeaderDateBottomPadding = 15;
CGFloat const ATLConversationViewHeaderParticipantNameBottomPadding = 3;
CGFloat const ATLConversationViewHeaderEmptyHeight = 1;

+ (ATLConversationCollectionViewHeader *)sharedHeader
{
    static ATLConversationCollectionViewHeader *_sharedHeader;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedHeader = [ATLConversationCollectionViewHeader new];
    });
    return _sharedHeader;
}

+ (void)initialize
{
    ATLConversationCollectionViewHeader *proxy = [self appearance];
    proxy.participantLabelTextColor = [UIColor colorWithRed:0.0 green:185.0/255.0 blue:185.0/255.0 alpha:1.0];
    proxy.participantLabelFont = [UIFont fontWithName:@"Roboto-Bold" size:12.0];
    proxy.dateLabelFont = [UIFont fontWithName:@"Roboto-Bold" size:15.0];
    proxy.dateLabelTextColor = [UIColor colorWithRed:105.0/255.0 green:110.0/255.0 blue:120.0/255.0 alpha:1.0];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self lyr_commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self lyr_commonInit];
    }
    return self;
}

- (void)lyr_commonInit
{
    self.dateLabel = [[UILabel alloc] init];
    self.dateLabel.textAlignment = NSTextAlignmentLeft;
    
    self.dateLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:15.0];
    self.dateLabel.textColor = [UIColor colorWithRed:105.0/255.0 green:110.0/255.0 blue:120.0/255.0 alpha:1.0];
    self.dateLabel.translatesAutoresizingMaskIntoConstraints = YES;
    [self addSubview:self.dateLabel];
    self.dateSeparatorView  = [[UIView alloc] init];
    self.dateSeparatorView.backgroundColor = [UIColor colorWithRed:216.0/255.0 green:216.0/255.0 blue:216.0/255.0 alpha:1.0];
    [self addSubview:self.dateSeparatorView];
    
    self.participantLabel = [[UILabel alloc] init];
    self.participantLabel.font = _participantLabelFont;
    self.participantLabel.textColor = _participantLabelTextColor;
    self.participantLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.participantLabel.accessibilityLabel = ATLConversationViewHeaderIdentifier;
    [self addSubview:self.participantLabel];
    
    _leftConstraint = [NSLayoutConstraint new];
    _rightConstraint = [NSLayoutConstraint new];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.dateLabel.attributedText = nil;
    self.participantLabel.attributedText = nil;
    self.dateLabel.text = nil;
    self.participantLabel.text = nil;
}

- (void)updateWithAttributedStringForDate:(NSAttributedString *)date
{
    if (!date) {
        [self.dateSeparatorView removeConstraints:self.dateSeparatorView.constraints];
        [self.dateSeparatorView removeFromSuperview];
        
        [self setNeedsLayout];
        return;
    }
    else {
        self.dateLabel.attributedText = date;
        [self.dateLabel sizeToFit];
        self.dateLabel.adjustsFontSizeToFitWidth = YES;
        self.dateLabel.numberOfLines = 1;
        if (date.string.length > 0) {
            [self addSubview:self.dateSeparatorView];
            [self configureDateLabelConstraints];
        } else {
            [self.dateSeparatorView removeConstraints:self.dateSeparatorView.constraints];
            [self.dateSeparatorView removeFromSuperview];
        }
        [self setNeedsLayout];
    }
}

- (void)updateWithParticipantName:(NSAttributedString *)participantName
{
    if (participantName.length) {
        self.participantLabel.attributedText = participantName;
        if (participantName.length > 12) {
            [self configureParticipantLabelConstraintsForIncoming];
            
        } else {
            [self configureParticipantLabelConstraintsForOutgoing];
        }
    } else {
        self.participantLabel.attributedText = [[NSAttributedString alloc] initWithString:@"" attributes:nil];
    }
    [self setNeedsLayout];
}

- (void)setParticipantLabelFont:(UIFont *)participantLabelFont
{
//    _participantLabelFont = participantLabelFont;
//    self.participantLabel.font = participantLabelFont;
}

- (void)setParticipantLabelTextColor:(UIColor *)participantLabelTextColor
{
//    _participantLabelTextColor = participantLabelTextColor;
//    self.participantLabel.textColor = participantLabelTextColor;
}

- (void)setDateLabelFont:(UIFont *)dateLabelFont
{
    //    _dateLabelFont = dateLabelFont;
    //    self.dateLabel.font = dateLabelFont;
}

- (void)setDateLabelTextColor:(UIColor *)dateLabelTextColor
{
    //    _dateLabelTextColor = dateLabelTextColor;
    //    self.dateLabel.textColor = dateLabelTextColor;
}

+ (CGFloat)headerHeightWithDateString:(NSAttributedString *)dateString participantName:(NSAttributedString *)participantName inView:(UIView *)view
{
    if (!dateString && !participantName) return ATLConversationViewHeaderEmptyHeight;
    
    ATLConversationCollectionViewHeader *header = [self sharedHeader];
    // Temporarily adding the view to the hierarchy so that UIAppearance property values will be set based on containment.
    [view addSubview:header];
    [header removeFromSuperview];
    
    CGFloat height = 0;
    height += ATLConversationViewHeaderTopPadding;
    NSString *string = dateString.string;
    
    if (string.length) {
        [header updateWithAttributedStringForDate:dateString];
        CGSize dateSize = [header.dateLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
        height += dateSize.height + ATLConversationViewHeaderDateBottomPadding;
    }
    
    if (participantName.length) {
        [header updateWithParticipantName:participantName];
        CGSize participantSize = [header.participantLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
        height += participantSize.height + ATLConversationViewHeaderParticipantNameBottomPadding;
    }
    
    return height;
}

- (void)configureDateLabelConstraints
{
    [self.dateLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.dateSeparatorView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.dateLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:ATLConversationViewHeaderTopPadding]];
    
    [self addConstraint: [NSLayoutConstraint constraintWithItem:self.dateLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:ATLConversationViewHeaderHorizontalPadding]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.dateSeparatorView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.dateLabel attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.dateSeparatorView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.dateLabel attribute:NSLayoutAttributeRight multiplier:1.0 constant:ATLConversationViewHeaderHorizontalPadding]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.dateSeparatorView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:-ATLConversationViewHeaderHorizontalPadding]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.dateSeparatorView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:1]];
}

- (void)configureParticipantLabelConstraintsForIncoming
{
    if ([self.constraints containsObject:_rightConstraint]) {
        [self removeConstraint:_rightConstraint];
    }
    if ([self.constraints containsObject:_leftConstraint]) {
        [self removeConstraint:_leftConstraint];
    }
    _leftConstraint = nil;
    _rightConstraint = nil;
    
    _leftConstraint = [NSLayoutConstraint constraintWithItem:self.participantLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:15.0];
    [self addConstraint: [NSLayoutConstraint constraintWithItem:self.participantLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-8.0]];
    [self addConstraint:_leftConstraint];
    
}

- (void)configureParticipantLabelConstraintsForOutgoing {
    if ([self.constraints containsObject:_rightConstraint]) {
        [self removeConstraint:_rightConstraint];
    }
    if ([self.constraints containsObject:_leftConstraint]) {
        [self removeConstraint:_leftConstraint];
    }
    _leftConstraint = nil;
    _rightConstraint = nil;
    
    _rightConstraint = [NSLayoutConstraint constraintWithItem:self.participantLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:-18.0];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.participantLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-8.0]];
    [self addConstraint:_rightConstraint];
}


@end
