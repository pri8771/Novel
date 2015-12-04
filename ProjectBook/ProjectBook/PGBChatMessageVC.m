//
//  PGBChatMessageVC.m
//  ProjectBook
//
//  Created by Lauren Reed on 12/3/15.
//  Copyright © 2015 FIS. All rights reserved.
//

#import "PGBChatMessageVC.h"
#import "JSQMessage.h"
#import "JSQMessagesBubbleImageFactory.h"
#import "JSQMessagesTimestampFormatter.h"
#import "JSQPhotoMediaItem.h"
#import "JSQMessagesTypingIndicatorFooterView.h"
#import "UIImage+JSQMessages.h"
#import "JSQSystemSoundPlayer+JSQMessages.h"

@interface PGBChatMessageVC ()

@property(strong, nonatomic) NSMutableArray *messagesInConversation;
@property (strong, nonatomic) NSDictionary *messageContent;

@end

@implementation PGBChatMessageVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    PFUser *currentPerson = [PFUser currentUser];
    
    self.messagesInConversation = [NSMutableArray new];
    
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    
    
    NSString *senderParseId = currentPerson.objectId;
    NSString *senderUserName = currentPerson.username;
    self.senderId = senderParseId;
    self.senderDisplayName = senderUserName;
    SEL selector = @selector(receiveNotification:);

    


    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"NewMessage" object:nil];
    
}

- (void) receiveNotification:(NSNotification *) notification {
    
    if ([[notification name] isEqualToString:@"NewMessage"]) {
        
        PFQuery *messagesQuery = [PFQuery queryWithClassName:@"bookChat"];
        
        // this needs to do the chat's unique id that is created when a new chat is created
        [messagesQuery whereKey:@"objectId" equalTo:@"R4F0MHrv6R"];
        self.showTypingIndicator = !self.showTypingIndicator;
        [self scrollToBottomAnimated:YES];
        
        
        [messagesQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            // this is where youd stop the loading indicator
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                NSDictionary *lastMessage = objects.lastObject;
                JSQMessage *latestMessage = [[JSQMessage alloc] initWithSenderId:lastMessage[@"senderID"]
                                                               senderDisplayName:lastMessage[@"senderDisplayName"]
                                                                            date:lastMessage[@"date"]
                                                                            text:lastMessage[@"text"]];
                
                [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
                [self.messagesInConversation addObject:latestMessage];
                [self finishReceivingMessageAnimated:YES];
            }];
        }];
    }
}

- (void)configureWithEllipsisColor:(UIColor *)ellipsisColor messageBubbleColor:(UIColor *)messageBubbleColor shouldDisplayOnLeft:(BOOL)shouldDisplayOnLeft forCollectionView:(UICollectionView *)collectionView {
    
}

-(void)viewDidAppear:(BOOL)animated {
    
    

}

-(void)didPressSendButton:(UIButton *)button
          withMessageText:(NSString *)text
                 senderId:(NSString *)senderId
        senderDisplayName:(NSString *)senderDisplayName
                     date:(NSDate *)date {
    
    JSQMessage *message = [[JSQMessage alloc] initWithSenderId:senderId
                                             senderDisplayName:senderDisplayName
                                                          date:date
                                                          text:text];
    
    [self.messagesInConversation addObject:message];
    [self finishSendingMessageAnimated:YES];
    
    //create Parse Object or something, and push it up to Parse. TO make sure it's associated with the right user, MAKE SURE The senderID is equal to some unique ID in parse.  Pushing up to parse should be done in a block SO YOU KNOW THE MESSAGE WAS SENT (with completon block)
    
//    PFObject *bookChat = [PFObject objectWithClassName:@"bookChat"];
    [self turnJSQMessageObjectIntoDictionary:message];
//    [bookChat addObject:self.messageContent forKey:@"messagesInConversation" ];
//    
//    
//    [bookChat saveInBackgroundWithTarget:@"R4F0MHrv6R" selector:nil];
    
    
    PFQuery *newQuery = [PFQuery queryWithClassName:@"bookChat"];
    
    [newQuery getObjectInBackgroundWithId:@"R4F0MHrv6R" block:^(PFObject * _Nullable object, NSError * _Nullable error) {
        
        NSLog(@"What is messageContent: %@", self.messageContent);
        
        [object addObject:self.messageContent forKey:@"messagesInConversation"];
        [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            
            if (succeeded) {
                
                NSLog(@"SUCCESSION!!!!!!");
            }
            
        }];
    }];
    
}

- (NSDictionary *)turnJSQMessageObjectIntoDictionary:(JSQMessage *)message {
    
    self.messageContent = [NSDictionary new];
    self.messageContent = @{ @"senderID" : message.senderId,
                             @"senderDisplayName" : message.senderDisplayName,
                             @"date" : message.date,
                             @"text" : message.text };
    return self.messageContent;
}



#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.messagesInConversation objectAtIndex:indexPath.item];
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didDeleteMessageAtIndexPath:(NSIndexPath *)indexPath {
    [self.messagesInConversation removeObjectAtIndex:indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {

    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    
    JSQMessagesBubbleImage *outgoingBubbleImage = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor lightGrayColor]];
    
    
    JSQMessagesBubbleImage *incomingBubbleImage = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor blueColor]];


    
    JSQMessage *message = [self.messagesInConversation objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return outgoingBubbleImage;
    }
    
    return incomingBubbleImage;
}


// TODO: set avatars off of users profile picture...
- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    /**
     *  Return `nil` here if you do not want avatars.
     *  If you do return `nil`, be sure to do the following in `viewDidLoad`:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
     *
     *  It is possible to have only outgoing avatars or only incoming avatars, too.
     */
    
    /**
     *  Return your previously created avatar image data objects.
     *
     *  Note: these the avatars will be sized according to these values:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize
     *
     *  Override the defaults in `viewDidLoad`
     */
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item % 4 == 0) {
        JSQMessage *message = [self.messagesInConversation objectAtIndex:indexPath.item];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    JSQMessage *message = [self.messagesInConversation objectAtIndex:indexPath.item];
    
    /**
     *  iOS7-style sender name labels
     */
    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.messagesInConversation objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
            return nil;
        }
    }
    
    /**
     *  Don't specify attributes to use the defaults.
     */
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.messagesInConversation count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    /**
     *  Override point for customizing cells
     */
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    /**
     *  Configure almost *anything* on the cell
     *
     *  Text colors, label text, label colors, etc.
     *
     *
     *  DO NOT set `cell.textView.font` !
     *  Instead, you need to set `self.collectionView.collectionViewLayout.messageBubbleFont` to the font you want in `viewDidLoad`
     *
     *
     *  DO NOT manipulate cell layout information!
     *  Instead, override the properties you want on `self.collectionView.collectionViewLayout` from `viewDidLoad`
     */
    
    JSQMessage *msg = [self.messagesInConversation objectAtIndex:indexPath.item];
    
    if (!msg.isMediaMessage) {
        
        if ([msg.senderId isEqualToString:self.senderId]) {
            cell.textView.textColor = [UIColor blackColor];
        }
        else {
            cell.textView.textColor = [UIColor whiteColor];
        }
        
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    
    return cell;
}



#pragma mark - UICollectionView Delegate

#pragma mark - Custom menu items

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    if (action == @selector(customAction:)) {
        return YES;
    }
    
    return [super collectionView:collectionView canPerformAction:action forItemAtIndexPath:indexPath withSender:sender];
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    if (action == @selector(customAction:)) {
        [self customAction:sender];
        return;
    }
    
    [super collectionView:collectionView performAction:action forItemAtIndexPath:indexPath withSender:sender];
}

- (void)customAction:(id)sender {
    NSLog(@"Custom action received! Sender: %@", sender);
    
    [[[UIAlertView alloc] initWithTitle:@"Custom Action"
                                message:nil
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil]
     show];
}



#pragma mark - JSQMessages collection view flow layout delegate

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    /**
     *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
     */
    
    /**
     *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
     *  The other label height delegate methods should follow similarly
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    /**
     *  iOS7-style sender name labels
     */
    JSQMessage *currentMessage = [self.messagesInConversation objectAtIndex:indexPath.item];
    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
        return 0.0f;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.messagesInConversation objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
            return 0.0f;
        }
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath {
    return 0.0f;
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender {
    NSLog(@"Load earlier messages!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Tapped avatar!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Tapped message bubble!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation {
    NSLog(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
}

//- (BOOL)composerTextView:(JSQMessagesComposerTextView *)textView shouldPasteWithSender:(id)sender {
//    if ([UIPasteboard generalPasteboard].image) {
//        JSQPhotoMediaItem *item = [[JSQPhotoMediaItem alloc] initWithImage:[UIPasteboard generalPasteboard].image];
//        JSQMessage *message = [[JSQMessage alloc] initWithSenderId:self.senderId
//                                                 senderDisplayName:self.senderDisplayName
//                                                              date:[NSDate date]
//                                                             media:item];
//        [self.messagesInConversation addObject:message];
//        [self finishSendingMessage];
//        return NO;
//    }
//    return YES;
//}
//

@end
