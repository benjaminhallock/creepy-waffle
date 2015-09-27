#import "ProgressHUD.h"
#import "NSDate+TimeAgo.h"
#import "AppConstant.h"

#import "ChatView.h"
#import "utilities.h"
#import "messages.h"
#import "pushnotification.h"
#import "CustomCameraView.h"
#import "ActionSheet.h"

#import <MediaPlayer/MediaPlayer.h>

@interface ChatView () < CustomCameraDelegate, KLCPopupDelegate >

@property ActionSheet *actionSheetHolder;
@property MPMoviePlayerController *moviePlayer;
@property JSQMessagesBubbleImageFactory *bubbleFactory;
@property UITapGestureRecognizer *tap;
@property PFImageView *longPressImageView;

@property BOOL isLoading;
@property int x;
@property int intForOrderedPictures;
@property UIImage *randomImage;
@property CGPoint startLocation;
@property UICollectionViewFlowLayout *flowLayoutPictures;
@property UIColor *selectedColor;

@property CGFloat rowHeight;
@property CGRect collectionViewFrame;
@property NSMutableArray *arrayOfTitleUsers;
@property NSMutableArray *arrayOfNames;

@property BOOL didSendPhotos;
@property BOOL isSelectingItem;
@property  BOOL isLoadingPopup;
@property BOOL isCommentingOnPictures;

@property NSMutableArray *messages;
@property NSMutableArray *messageObjects;
@property NSMutableArray *messageObjectIds;
@property JSQMessagesBubbleImage *outgoingBubbleImageData;
@property JSQMessagesBubbleImage *incomingBubbleImageData;

@property int countDownForPictureRefresh;
@property BOOL didViewJustLoad;
@property NSString *name;
@property KLCPopup *pop;
@property int isLoadingEarlierCount;
@property UIRefreshControl *refreshControl;
@property UIRefreshControl *refreshControl2;
@property BOOL didOpenChatView;
@end

@implementation ChatView

@synthesize moviePlayer;

- (void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date
{
    if (self.isCommentingOnPictures)
    {
        [self sendMessage:text];
        [self actionDismiss];
    }
    else
    {
        [self sendMessage:text];
        [self finishSendingMessageAnimated:YES];
    }
}

- (void)didPressAccessoryButton:(UIButton *)sender
{
    if (self.inputToolbar.contentView.textView.isFirstResponder)
    {
        [self.inputToolbar.contentView.textView resignFirstResponder];
    }

    CustomCameraView *cam = [[CustomCameraView alloc] initWithPopUp:1];
    cam.delegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:cam];
    [self presentViewController:nav animated:1 completion:0];
}

- (id)initWith:(PFObject *)room name:(NSString *)name
{
    self = [super init];
    if (self)
    {
        self.room = room;
        self.name = name;
    }
    return self;
}

- (void) refresh
{
    [self loadChat];
    [self scrollToBottomAnimated:1];
}

//NOt used
-(void) refresh2 {
    _isLoadingEarlierCount++;
    [self loadChat];
}

#pragma mark - DELGATES

- (void)sendBackPictures:(NSArray *)array withBool:(bool)didTakePicture andComment:(NSString *)comment
{
    self.didSendPhotos = YES;

    __block bool isSendingVideo = false;

    PostNotification(NOTIFICATION_CLEAR_CAMERA_STUFF);

    NSArray *arrayCopy = [NSArray arrayWithArray:array];
    self.x = (int)arrayCopy.count;
    PFObject *set = [PFObject objectWithClassName:PF_SET_CLASS_NAME];
    [set setValue:self.room forKey:PF_SET_ROOM];
    [set setValue:[PFUser currentUser] forKey:PF_SET_USER];
    _countDownForPictureRefresh = (int)arrayCopy.count;

    NSMutableArray *arrayOfPicturesObjectsTemp = [NSMutableArray new];

    for (id imageOrFile in arrayCopy)
    {
        PFFile *imageOrVideoFile;
        PFObject *picture;
        __block NSData *data;

        if ([imageOrFile isKindOfClass:[UIImage class]])
        {
            UIImage *image = imageOrFile;
            data = UIImageJPEGRepresentation(image, .5);
            imageOrVideoFile = [PFFile fileWithName:@"image.png"
                                               data:data];

            picture = [PFObject objectWithClassName:PF_PICTURES_CLASS_NAME];
            UIImage *thumbnail = ResizeImage(image, image.size.width, image.size.height);
            PFFile *file = [PFFile fileWithName:@"thumbnail.png" data:UIImageJPEGRepresentation(thumbnail, .3)];
            [picture setValue:file forKey:PF_PICTURES_THUMBNAIL];
            [picture setValue:[PFUser currentUser] forKey:PF_PICTURES_USER];
            [picture setValue:self.room forKey:PF_PICTURES_CHATROOM];
            [picture setValue:@YES forKey:PF_CHAT_ISUPLOADED];
            [picture setValue:[NSDate dateWithTimeIntervalSinceNow:.1f * (float)[arrayCopy indexOfObject:imageOrFile]] forKey:PF_PICTURES_UPDATEDACTION];
            [picture setValue:set forKey:PF_PICTURES_SETID];
            [arrayOfPicturesObjectsTemp addObject:picture];
        }
//      ELSE VIDEO
        else if ([imageOrFile isKindOfClass:[NSDictionary class]])
        {
            isSendingVideo = true;
            NSDictionary *dic = imageOrFile;
            __block NSString *path = dic.allKeys.firstObject;
            UIImage *thumbnail = dic.allValues.firstObject;

            data = [NSData dataWithContentsOfFile:path];

            imageOrVideoFile = [PFFile fileWithName:@"video.mov" contentsAtPath:path];

            PFFile *fileThumb = [PFFile fileWithName:@"thumbnail.png" data:UIImageJPEGRepresentation(thumbnail, .2)];

            picture = [PFObject objectWithClassName:PF_PICTURES_CLASS_NAME];
            [picture setValue:[PFUser currentUser] forKey:PF_PICTURES_USER];
            [picture setValue:@YES forKey:PF_CHAT_ISUPLOADED];
            [picture setValue:[NSDate dateWithTimeIntervalSinceNow:.1 * [arrayCopy indexOfObject:imageOrFile]] forKey:PF_PICTURES_UPDATEDACTION];
            [picture setObject:fileThumb forKey:PF_PICTURES_THUMBNAIL];
            [picture setValue:set forKey:PF_PICTURES_SETID];
            [picture setValue:self.room forKey:PF_PICTURES_CHATROOM];
            [picture setValue:@YES forKey:PF_PICTURES_IS_VIDEO];

            [arrayOfPicturesObjectsTemp addObject:picture];
        }

        [picture setValue:imageOrVideoFile forKey:PF_PICTURES_PICTURE];

        //      STILL IN LOOP, SAVING EACH INVIDUALLY
        __block BOOL didSaveLastPicture = false;
        [picture saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
         {
             if (succeeded)
             {
#warning CACHE CAN TAKE UP ALOT OF SPACE

                 NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), [NSString stringWithFormat:@"cache%@.mov", picture.objectId]];
                 NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
                 NSFileManager *fileManager = [NSFileManager defaultManager];
                 if (![fileManager fileExistsAtPath:outputPath])
                 {
                     [data writeToFile:outputPath atomically:1];
                 }

                 self.x--;
                 _countDownForPictureRefresh--;

                 if (isSendingVideo)
                 {
                     SendPushNotification(self.room, @"New Video!");
                     UpdateMessageCounter(self.room, @"New Video!", arrayOfPicturesObjectsTemp.lastObject);
                 }
                 else
                 {
                 SendPushNotification(self.room, @"New Picture!");
                 UpdateMessageCounter(self.room, @"New Picture!", arrayOfPicturesObjectsTemp.lastObject);
                }

                 [self loadChat];
                 [self finishSendingMessageAnimated:1];
                 self.didSendPhotos = NO;
             }
             else
             {
                 [ProgressHUD showError:@"Picture Saving Error"];
                 NSLog(@"%@", error.userInfo);
             }
         }];
    }
}

//Clear comment bar of stuff.
- (void)actionDismiss
{
    self.isCommentingOnPictures = NO;
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [button setImage:[[UIImage imageNamed:ASSETS_NEW_CAMERASQUARE ] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    button.tintColor = [UIColor benFamousGreen];
    button.imageView.tintColor = [UIColor benFamousGreen];
    self.inputToolbar.contentView.rightBarButtonItem.tintColor = [UIColor blueTintColor];

    self.inputToolbar.contentView.textView.placeHolderTextColor = [UIColor lightGrayColor];
    self.inputToolbar.contentView.leftBarButtonItem = button;
    self.inputToolbar.contentView.textView.textColor = [UIColor darkTextColor];
    self.inputToolbar.contentView.textView.text = @"";

    self.inputToolbar.contentView.textView.backgroundColor = [UIColor whiteColor];
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@"Attach a Comment..."])
    {
        textView.text = @"";
    }

    if (self.isCommentingOnPictures)
    {
        textView.text = @"";
    }

    [self.view addGestureRecognizer:self.tap];

    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [super textViewDidEndEditing:textView];

    if (textView != self.inputToolbar.contentView.textView)
    {
        return;
    }

    [textView resignFirstResponder];
    [self.collectionView setContentOffset:CGPointZero animated:1];
    [self scrollToBottomAnimated:1];
    [self.view removeGestureRecognizer:self.tap];
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];

    JSQMessage *msg = self.messages[indexPath.item];

    if (!msg.isMediaMessage)
    {
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.isSelectingItem) {
        self.isSelectingItem = YES;
    }
}

-(void)checkMovieStatus:(NSNotification *)notificaiton
{
    if (self.moviePlayer.readyForDisplay) {
        [self.moviePlayer play];
        [UIView animateWithDuration:.5f animations:^{
            self.moviePlayer.view.alpha = 0;
            self.moviePlayer.view.alpha = 1;
        }];
    }
}

- (void) didTap:(UITapGestureRecognizer *)tap
{
    if (self.inputToolbar.contentView.textView.isFirstResponder)
    {
        [self.inputToolbar.contentView.textView resignFirstResponder];
    }
}

-(void)leaveChatroom:(NSNotification *) notification
{
    self.isLoading = YES;
    [self.navigationController popViewControllerAnimated:1];
    PostNotification(NOTIFICATION_REFRESH_INBOX);
    PostNotification(NOTIFICATION_ENABLESCROLLVIEW);
}

-(void)dismiss
{
    //    [self performSelector:@selector(dismiss2) withObject:self afterDelay:1.0];
}

-(void)dismiss2
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:0 completion:0];
    });
}

- (void) setNavigationBarColor
{
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setBarTintColor:[UIColor benFamousGreen]];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:1];
    self.navigationController.navigationBar.titleTextAttributes =  @{
                                                                     NSForegroundColorAttributeName: [UIColor whiteColor],
                                                                     NSFontAttributeName: [UIFont fontWithName:@"Helvetica Neue" size:20.0f],
                                                                     NSShadowAttributeName:[NSShadow new]
                                                                     };
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setNavigationBarColor];

    //    Set avatar to zero.
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    self.automaticallyScrollsToMostRecentMessage = YES;

    //      OPT-IN: allow cells to be deleted
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(delete:)];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(leaveChatroom:) name:NOTIFICATION_LEAVE_CHATROOM object:0];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadChat) name:NOTIFICATION_REFRESH_CHATROOM object:0];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismiss) name:NOTIFICATION_CAMERA_POPUP object:0];

    self.title = self.name;
    //Disable automatic keyboard helper

    _isLoadingEarlierCount = 1;

    self.automaticallyScrollsToMostRecentMessage = 1;
    self.showLoadEarlierMessagesHeader = 0;

    self.collectionView.loadEarlierMessagesHeaderTextColor = [UIColor lightGrayColor];

    if (!self.message && self.room)
    {
        PFQuery *query = [PFQuery queryWithClassName:PF_MESSAGES_CLASS_NAME];
        [query whereKey:PF_MESSAGES_USER equalTo:[PFUser currentUser]];
        [query whereKey:PF_MESSAGES_ROOM  equalTo:self.room];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error & objects.count) {
                self.message = objects.firstObject;
            }
        }];
    }

    self.didViewJustLoad = YES;

    //    [self.collectionView registerClass:[CustomCollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    
    //BAR BUTTONS
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                   initWithTitle: @""
                                   style: UIBarButtonItemStyleBordered
                                   target: nil action: nil];
    [self.navigationItem setBackBarButtonItem: backButton];

    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [button setImage:[[UIImage imageNamed:ASSETS_NEW_CAMERASQUARE] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];

    button.tintColor = [UIColor benFamousGreen];
    self.inputToolbar.contentView.leftBarButtonItem = button;

    //Change send button to blue
    [self.inputToolbar.contentView.leftBarButtonItem setTitleColor:[UIColor blueTintColor] forState:UIControlStateNormal];
    [self.inputToolbar.contentView.leftBarButtonItem setTitleColor:[[UIColor blueTintColor] jsq_colorByDarkeningColorWithValue:0.1f] forState:UIControlStateHighlighted];

    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:ASSETS_TYPING] style:UIBarButtonItemStyleDone target:self action:@selector(popUpNames)];
    self.navigationItem.rightBarButtonItem = barButton;

    self.tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(didTap:)];
    self.tap.delegate = self;

    //INIT
    self.messages = [[NSMutableArray alloc] init];
    self.messageObjects = [[NSMutableArray alloc] init];
    self.messageObjectIds = [NSMutableArray new];

    //CURRENT USER
    PFUser *user = [PFUser currentUser];
    self.senderId = user.objectId;
    self.senderDisplayName = user[PF_USER_FULLNAME];

    //BUBBLES
    self.bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];

    //CLEAR!!
    [self.message fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error) {
            if ([object valueForKey:PF_MESSAGES_COUNTER])
            {
                NSNumber *number = [object objectForKey:PF_MESSAGES_COUNTER];
                // Fetch the inbox message first? Object may not have been updated from push in background??
                if ([number intValue] > 0)
                {
                    ClearMessageCounter(self.message);
                }
            }
        }
    }];
    
    //LOAD!!
    [self loadChat];
}

- (void) popUpNames
{
    if (self.isLoadingPopup == NO)
    {
        self.isLoadingPopup = YES;
        self.actionSheetHolder = [[ActionSheet alloc] initWithRoom:self.room AndMessage:self.message];
        [self.actionSheetHolder showActionSheetWithDelegate:self];
        self.isLoadingPopup = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:1];
    self.navigationController.navigationBarHidden = NO;
    if (self.message)
    {
        if (self.message[PF_MESSAGES_NICKNAME])
        {
            NSString *nickname = self.message[PF_MESSAGES_NICKNAME];
            self.title = nickname;
        } else {
            NSString *description = self.message[PF_MESSAGES_DESCRIPTION];
            self.title = description;
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self actionDismiss];

    self.isSelectingItem = NO;

    [ProgressHUD dismiss];

    [self.message fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error)
        {
            if ([object valueForKey:PF_MESSAGES_COUNTER])
            {
                NSNumber *number = [object objectForKey:PF_MESSAGES_COUNTER];
                // Fetch the inbox message first? Object may not have been updated from push in background??
                if ([number intValue] > 0)
                {
                    ClearMessageCounter(self.message);
                }
            }
        }
    }];

}

#pragma mark - Backend methods

- (void)loadChat
{
    if (self.isLoading == NO)
    {
        self.showTypingIndicator = 1;
        NSLog(@"LOADING CHAT");
        self.isLoading = YES;
        self.collectionView.hidden = YES;

        PFQuery *query = [PFQuery queryWithClassName:PF_CHAT_CLASS_NAME];
        [query whereKey:PF_CHAT_ROOM equalTo:self.room];

        JSQMessage *message_last = [self.messages lastObject];
        if (message_last)
        {
            [query whereKey:PF_CHAT_CREATEDAT greaterThan:message_last.date];
        }

        [query includeKey:PF_CHAT_USER];
        [query includeKey:PF_CHAT_SETID];
        [query orderByDescending:PF_PICTURES_UPDATEDACTION];
        [query setLimit:200 * _isLoadingEarlierCount];

//      Warning: Will go through query twice. Using self.editing to prevent confusion.
        [query setCachePolicy:kPFCachePolicyCacheThenNetwork];
        
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
         {
             if (error == nil)
             {
                 int count = (int)self.messages.count;

                 //Loading into array
                 for (PFObject *object in [objects reverseObjectEnumerator])
                 {
                     if ([object objectForKey:PF_PICTURES_THUMBNAIL])
                     {
                         // IS A PICTURE, ADD TO PICTURES
                         if ([object valueForKey:PF_CHAT_ISUPLOADED])
                         {
                            if (![self.messageObjectIds containsObject:object.objectId])
                             {

                                 PFUser *user = [object valueForKey:PF_CHAT_USER];
                                 NSString *senderId = user.objectId;
                                 NSString *senderName = user[PF_USER_FULLNAME];

                               bool isCurrentUser = [self.senderId isEqualToString:senderId] ? YES: NO;

//                                 Using photo for video since it's just loading here, might having problems with outgoing vs incoming mask, have to check senderId to fix.
                                 JSQPhotoMediaItem *item = [[JSQPhotoMediaItem alloc]initWithMaskAsOutgoing:isCurrentUser];
                                 item.image = nil;
                                 JSQMessage *message2 = [JSQMessage messageWithSenderId:senderId displayName:senderName media:item];
                                 [self.messages addObject:message2];
                                 [self.messageObjects addObject:object];
                                 [self.messageObjectIds addObject:object.objectId];

//                                 Fetching the thumbnail from cache or internet, then updating with new JSQMessage.
                                 PFFile *file = [object valueForKey:PF_PICTURES_THUMBNAIL];
                                 [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error)
                                  {
                                      if (!error)
                                      {
//                                          PFUser *user = [object valueForKey:PF_CHAT_USER];
//                                          NSString *senderId = user.objectId;
//                                          NSString *senderName = user[PF_USER_FULLNAME];

                                          if ([object valueForKey:PF_CHAT_ISVIDEO])
                                          {
                                               NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@",NSTemporaryDirectory(), [NSString stringWithFormat:@"cache%@.mov", object.objectId]];
                                              NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
                                              NSFileManager *fileManager = [NSFileManager defaultManager];

                                              if ([fileManager fileExistsAtPath:outputPath])
                                              {
                                                  JSQVideoMediaItem *video = [[JSQVideoMediaItem alloc] initWithFileURL:outputURL isReadyToPlay:1];

                                            video.appliesMediaViewMaskAsOutgoing = isCurrentUser;

                                                  JSQMessage *message = [[JSQMessage alloc] initWithSenderId:senderId senderDisplayName:senderName date:[object valueForKey:PF_CHAT_CREATEDAT] media:video];

                                                  [self.messages replaceObjectAtIndex:[self.messages indexOfObject:message2] withObject:message];
                                              }
                                              else
                                              {
                                                  PFFile *video = [object valueForKey:PF_PICTURES_PICTURE];
                                                  
                                                  [video getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error)
                                                  {
                                                      if (!error)
                                                      {
                                                    [data writeToFile:outputPath atomically:1];

                                                JSQVideoMediaItem *video = [[JSQVideoMediaItem alloc] initWithFileURL:outputURL isReadyToPlay:1];

                                                video.appliesMediaViewMaskAsOutgoing = isCurrentUser;

                                                    JSQMessage *message = [[JSQMessage alloc] initWithSenderId:senderId senderDisplayName:senderName date:[object valueForKey:PF_CHAT_CREATEDAT] media:video];

                                                        [self.messages replaceObjectAtIndex:[self.messages indexOfObject:message2] withObject:message];

                                                        [self.collectionView reloadData];
                                                      }
                                                  }];
                                              }
                                          }
                                          else
                                          {
                                          JSQPhotoMediaItem *photoItemCopy = [[JSQPhotoMediaItem alloc] initWithImage:[UIImage imageWithData:data]];

                                          if ([self.senderId isEqualToString:senderId])
                                          {
                                              photoItemCopy.appliesMediaViewMaskAsOutgoing = YES;
                                          }
                                          else
                                          {
                                              photoItemCopy.appliesMediaViewMaskAsOutgoing = NO;
                                          }

                                          JSQMessage *message = [[JSQMessage alloc] initWithSenderId:senderId senderDisplayName:senderName date:[object valueForKey:PF_CHAT_CREATEDAT] media:photoItemCopy];

                                          [self.messages replaceObjectAtIndex:[self.messages indexOfObject:message2] withObject:message];

                                          [self finishReceivingMessageAnimated:1];
                                    }
                                      }
                                      else
                                      {
                                          NSLog(@"Error fetching thumbnail");
                                      }
                                  }];
                             }
                         }
                     }
                     else
                     {
                         // IS A COMMENT, ADD TO COMMENTS;
                         if (![self.messageObjectIds containsObject:object.objectId])
                         {
                             [self addMessage:object];
                             [self.messageObjects addObject:object];
                             [self.messageObjectIds addObject:object.objectId];
                         }
                     }
                 }

//               START WEIRD REFRESHING RULES TO MAKE SURE THIS WORKS.

                 [self finishReceivingMessageAnimated:1];

                 if (_didOpenChatView == NO)
                 {
                     [self finishReceivingMessageAnimated:0];
                     self.collectionView.hidden = NO;
                 }

                 //Sorting out what to do with the data
                 int newCount = (int)self.messages.count;

                 if (objects.count && _isLoadingEarlierCount == 1)
                 {
                     //Should help the cache show up after network times out.
                 }
                 else if (_isLoadingEarlierCount > 1)
                 {
                     //Checking load earlier, did new messages show up?
                     //Make sure this doesn't scroll to bottom.
                     if (newCount - count == 0)
                     {
                         [ProgressHUD showSuccess:@"Last Message" Interaction:1];
                     }

                     [self.collectionView reloadData];
                     [_refreshControl endRefreshing];
                     [_refreshControl2 endRefreshing];
                     self.isLoading = NO;
                     return;
                 }
                 else if (!newCount)
                 {
                     [self performSelector:@selector(openTextView) withObject:self afterDelay:.5f];
                 }
                 else if (newCount > 200)
                 {
                     self.showLoadEarlierMessagesHeader = 1;
                 }
                 self.isLoading = NO;
                 self.showTypingIndicator = NO;

                 if (self.editing)
                 { // WONT LOAD OFFLINE CACHE
                     self.editing = !self.editing;

                     if (_didOpenChatView == NO)
                     {
                         _didOpenChatView = YES;
                         [self scrollToBottomAnimated:1];
                     }

                     [self.collectionView reloadData];
                     self.collectionView.hidden = NO;

                     if (newCount > count)
                     {
                         [self scrollToBottomAnimated:1];
                         NSUserDefaults *userDefualts = [NSUserDefaults standardUserDefaults];
                         if ([userDefualts boolForKey:PF_KEY_SHOULDVIBRATE])
                         {
                             [JSQSystemSoundPlayer jsq_playMessageReceivedAlert];
                         }
                         else
                         {
                             [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
                         }
                     }
                 }
                 else
                 {
                     self.editing = !self.editing;
                 }
             }
             else
             {
                 self.collectionView.hidden = NO;
                 if ([query hasCachedResult] && (self.navigationController.visibleViewController == self))
                 {
#warning IF NO INTERNET, SHOW THE CACHE
                     NSLog(@"%@", error.userInfo);
                     [ProgressHUD showError:NETWORK_ERROR];
                 }
             }
         }];
    }
}

- (void)openTextView
{
    if (!_isSendingTextMessage)
    {
        [self.inputToolbar.contentView.textView becomeFirstResponder];
    }
    else
    {
        _isSendingTextMessage = NO;
    }
}

- (void)addMessage:(PFObject *)object
{
    PFUser *user = object[PF_CHAT_USER];
    NSDate *date = [object valueForKey:PF_CHAT_CREATEDAT];
    if (date == nil) date = [NSDate date];
    JSQMessage *message = [[JSQMessage alloc] initWithSenderId:user.objectId senderDisplayName:user[PF_USER_FULLNAME] date:date text:object[PF_CHAT_TEXT]];
    [self.messages addObject:message];
}

- (void)sendMessage:(NSString *)text
{
    PFObject *object = [PFObject objectWithClassName:PF_CHAT_CLASS_NAME];
    object[PF_CHAT_USER] = [PFUser currentUser];
    object[PF_CHAT_ROOM] = self.room;
    object[PF_CHAT_TEXT] = text;
    [object setValue:[NSDate date] forKey:PF_PICTURES_UPDATEDACTION];
    [self addMessage:object];
    [self finishSendingMessage];

    [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
     {
         if (!error && succeeded)
         {
             [self.messageObjectIds addObject:object.objectId];
             [self finishSendingMessage];
             if ([[NSUserDefaults standardUserDefaults] boolForKey:PF_KEY_SHOULDVIBRATE])
             {
                 [JSQSystemSoundPlayer jsq_playMessageSentAlert];
             }
             else
             {
             [JSQSystemSoundPlayer jsq_playMessageSentSound];
             }
             SendPushNotification(self.room, text);
             UpdateMessageCounter(self.room, text, nil);
         }
         else
         {
             [ProgressHUD showError:NETWORK_ERROR];
             [object deleteInBackground];
         }
     }];
}

#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.messages[indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView
             messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = self.messages[indexPath.item];

    self.outgoingBubbleImageData = [self.bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleBlueColor]];
    self.incomingBubbleImageData = [self.bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];

    if ([message.senderId isEqualToString:self.senderId])
    {
        return self.outgoingBubbleImageData;
    }
    return self.incomingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
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

     JSQMessage *message = [self.demoData.messages objectAtIndex:indexPath.item];

     if ([message.senderId isEqualToString:self.senderId]) {
     if (![NSUserDefaults outgoingAvatarSetting]) {
     return nil;
     }
     }
     else
     {
     if (![NSUserDefaults incomingAvatarSetting]) {
     return nil;
     }
     }

     return [self.demoData.avatars objectForKey:message.senderId];
     */
    return nil;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.messages count];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
     *  The other label text delegate methods should follow a similar pattern.
     *
     *  Show a timestamp for every 3rd message
     */

    JSQMessage *message = [self.messages objectAtIndex:indexPath.item];

    NSTimeZone *tz = [NSTimeZone defaultTimeZone];
    NSInteger seconds = [tz secondsFromGMTForDate:message.date];
    NSDate *date = [NSDate dateWithTimeInterval: seconds sinceDate:message.date];

    NSAttributedString *string = [[NSAttributedString alloc] initWithString:[date dateTimeUntilNow]];

    if (indexPath.item - 1 > -1)
    {
        JSQMessage *previousMessage = [self.messages objectAtIndex:indexPath.item - 1];

        if (abs([message.date timeIntervalSinceDate:previousMessage.date]) > 60 * 60) {
            return [[JSQMessagesTimestampFormatter new] attributedTimestampForDate:message.date];
        }
    } else {
        return [[JSQMessagesTimestampFormatter new] attributedTimestampForDate:message.date];
    }
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [self.messages objectAtIndex:indexPath.item];

    /**
     *  iOS7-style sender name labels
     */
    if ([message.senderId isEqualToString:self.senderId])
    {
        return nil;
    }

    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
            return nil;
        }
    }

    /**
     *  Don't specify attributes to use the defaults.
     */
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - UICollectionView DataSource
#pragma mark - JSQMessages collection view flow layout delegate
#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
     */

    /**
     *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
     *  The other label height delegate methods should follow similarly
     *
     *  Show a timestamp for every 3rd message
     */

    if (indexPath.item - 1 > -1)
    {
        JSQMessage *message = [self.messages objectAtIndex:indexPath.item];
        JSQMessage *previousMessage = [self.messages objectAtIndex:indexPath.item - 1];

        if (abs([message.date timeIntervalSinceDate:previousMessage.date]) > 60 * 60)
        {
            return kJSQMessagesCollectionViewCellLabelHeightDefault;
        }
    }
    else
    {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }

    return 0.1f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  iOS7-style sender name labels
     */
    JSQMessage *currentMessage = [self.messages objectAtIndex:indexPath.item];
    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
        return 0.0f;
    }

    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
            return 0.0f;
        }
    }

    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0f;
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{
    NSLog(@"didTapLoadEarlierMessagesButton");
    _isLoadingEarlierCount++;
    [self loadChat];
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView
           atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didTapAvatarImageView");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didDeleteMessageAtIndexPath:(NSIndexPath *)indexPath
{
    [self.messages removeObjectAtIndex:indexPath.item];
    [ProgressHUD showSuccess:@"Didn't Delete"];
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didTapMessageBubbleAtIndexPath");

    JSQMessage *message = [self.messages objectAtIndex:indexPath.item];

    if(message.isMediaMessage)
    {
        id<JSQMessageMediaData> copyMediaData = message.media;

        if ([copyMediaData isKindOfClass:[JSQPhotoMediaItem class]])
        {
            PFObject *pic = [self.messageObjects objectAtIndex:indexPath.item];
            PFFile *file = [pic valueForKey:PF_PICTURES_PICTURE];

            if(file.isDataAvailable == false)
            {
                [ProgressHUD show:@"" Interaction:false];
            }

            [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error)
             {
                 if (!error)
                 {
                     UIImage *image = [UIImage imageWithData:data];

                     UIImageView *imageVIew = [[UIImageView alloc] initWithImage:image];

                     imageVIew.layer.borderColor = [UIColor whiteColor].CGColor;
                     imageVIew.layer.borderWidth = 1;
                     imageVIew.layer.masksToBounds = true;
                     imageVIew.layer.cornerRadius = 10;
                     imageVIew.layer.shouldRasterize = YES;

                     int newHeight = image.size.height * (self.view.frame.size.width - 30) / image.size.width;

                     imageVIew.frame = CGRectMake(30, 30, self.view.frame.size.width - 30, newHeight);

                     KLCPopup *popup = [KLCPopup popupWithContentView:imageVIew showType:KLCPopupShowTypeBounceIn dismissType:KLCPopupDismissTypeBounceOut maskType:KLCPopupMaskTypeDimmed dismissOnBackgroundTouch:1 dismissOnContentTouch:1];
                     popup.layer.borderColor = (__bridge CGColorRef)([UIColor whiteColor]);
                     popup.layer.borderWidth = 5;
                     popup.layer.masksToBounds = true;
                     [popup show];
                     [ProgressHUD dismiss];
                 }
                 else
                 {
                     [ProgressHUD showError:@"Network Error"];
                 }
             }];
        }
        else if ([copyMediaData isKindOfClass:[JSQVideoMediaItem class]])
        {
            NSLog(@"Video");
            JSQVideoMediaItem *videoItemCopy = [((JSQVideoMediaItem *)copyMediaData) copy];

            NSError *attributesError = nil;
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:videoItemCopy.fileURL.path error:&attributesError];
            int fileSize = (int)[fileAttributes fileSize];
            NSLog(@"%i SIZE %@", fileSize, videoItemCopy.fileURL);

            [self loadMovie:videoItemCopy.fileURL];
        }
        
        if (self.inputToolbar.contentView.textView.isFirstResponder)
        {
            [self.inputToolbar.contentView.textView resignFirstResponder];
        }
    }
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
    if (self.inputToolbar.contentView.textView.isFirstResponder) {
        [self.inputToolbar.contentView.textView resignFirstResponder];
    }
    NSLog(@"didTapCellAtIndexPath %@", NSStringFromCGPoint(touchLocation));
}

-(void)loadMovie:(NSURL *)url
{
    CGRect frame = CGRectMake(30, 30, self.view.frame.size.width - 60, self.view.frame.size.height - 60);

    moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:url];
    moviePlayer.view.frame = frame;
    [moviePlayer prepareToPlay];
    moviePlayer.shouldAutoplay = false;
    moviePlayer.view.layer.shouldRasterize = 1;
    moviePlayer.view.layer.rasterizationScale = [UIScreen mainScreen].scale;
    moviePlayer.view.layer.masksToBounds = YES;
    moviePlayer.view.contentMode = UIViewContentModeScaleToFill;
    moviePlayer.view.layer.cornerRadius = moviePlayer.view.frame.size.width/10;
    moviePlayer.view.layer.borderColor = [UIColor whiteColor].CGColor;
    moviePlayer.view.layer.borderWidth = 1;
    moviePlayer.view.layer.cornerRadius = 10;
    moviePlayer.view.userInteractionEnabled = 1;
    moviePlayer.view.clipsToBounds = YES;
    moviePlayer.scalingMode = MPMovieScalingModeAspectFill;
    moviePlayer.movieSourceType = MPMovieSourceTypeFile;
    moviePlayer.controlStyle = MPMovieControlStyleNone;
    moviePlayer.repeatMode = MPMovieRepeatModeOne;
    moviePlayer.backgroundView.alpha = 0;
//    moviePlayer.view.backgroundColor = [UIColor lightGrayColor];
//    moviePlayer.backgroundView.backgroundColor = [UIColor lightGrayColor];

    UIView *view = [[UIView alloc] initWithFrame:self.view.bounds];
    [view addSubview:moviePlayer.view];
    
    KLCPopup *popup = [KLCPopup popupWithContentView:view showType:KLCPopupShowTypeBounceIn dismissType:KLCPopupDismissTypeBounceOut maskType:KLCPopupMaskTypeDimmed dismissOnBackgroundTouch:1 dismissOnContentTouch:1];
    [popup show];
    popup.delegate = self;
    [moviePlayer play];
}

-(void)didDismiss
{
    NSLog(@"Dismissed");
    [self performSelector:@selector(stopMovie) withObject:self afterDelay:.2];
}

-(void)stopMovie
{
    [moviePlayer stop];
    moviePlayer = nil;
}

@end