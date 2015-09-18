
#import "SelectChatroomView.h"

#import <Parse/Parse.h>

#import "MessagesCellDot.h"

#import "AppConstant.h"

#import "ProgressHUD.h"

#import "UIColor.h"

#import "AppDelegate.h"

#import "utilities.h"

#import "messages.h"

#import "JSQMessagesKeyboardController.h"

#import "pushnotification.h"

#import "ChatView.h"

#import "CreateChatroomView.h"

#import "CustomCameraView.h"

@interface SelectChatroomView ()
< CustomCameraDelegate, UITextViewDelegate, CreateChatroomDelegate, UITableViewDataSource, UITableViewDelegate >

@property UITapGestureRecognizer *tap;
@property int numberOfSets;
@property IBOutlet UITableView *tableView;
@property IBOutlet UIButton *composeButton;
@property NSMutableArray *messages;
@property PFObject *selectedRoom;
@property PFObject *selectedSet;
@property PFObject *selectedMessage;
@property NSString *selectedText;//For next view title;
@property NSMutableArray *arrayOfReusableCells;
@property BOOL didViewJustLoad;
@property NSMutableArray *savedPhotoObjects;
@property IBOutlet UIBarButtonItem *sendButton;
@property int randomNumber;
@property (strong, nonatomic) JSQMessagesKeyboardController *keyboardController;
@property BOOL justCreatedChatroom;
@property BOOL didSendPictures;
@property int countDownToPhotoRefresh;
@property IBOutlet UIButton *buttonSend;
@property IBOutlet UIButton *buttonSendArrow;
@property NSMutableArray *savedImageFiles;
@property (atomic) BOOL didTheyHitSendYet;
@property BOOL isNewNewConversation;
@end

@implementation SelectChatroomView

@synthesize tap;


//Don't have a use for this anymore.
- (id)initWithMessages:(NSArray *)messages
{
    self = [super init];
    if (self) {
        self.messages = [NSMutableArray arrayWithArray:messages];
    }
    return self;
}

//DELEGATE
- (void)sendObjectsWithSelectedChatroom:(PFObject *)object andText:(NSString *)text andComment:(NSString *)comment
{
    if ([comment isEqualToString:@"1"]) _isNewNewConversation = YES;
    _justCreatedChatroom = YES;
    self.selectedRoom = object;
    self.selectedText = text;
    [self actionSend:0];
}

//SECOND PART OF SEND
- (void)savePicturesWithRoom:(PFObject *)room
{
    _countDownToPhotoRefresh = (int)self.savedPhotoObjects.count;

    //SAVING set first to test internet, the going ahead and saving the room.
#warning ALTERNATIVE METHOD FOR COMMENT BAR - if you fetch the number of sets in chatroom quickly, then save this set quickly, that may be more accurate than waiting for a push notification to be received between two phones.
    [self.selectedSet saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
     {
         if (succeeded)
         {
    //Check to see if they all saved first in sendbackpictures.
    for (PFObject *picture in self.savedPhotoObjects)
    {
        //VIDEO OR PICTURE
        PFFile *imageOrVideo = [self.savedImageFiles objectAtIndex:[self.savedPhotoObjects indexOfObject:picture]];
        //Add int counter for finish.
        [picture setValue:self.selectedRoom forKey:PF_PICTURES_CHATROOM];
        [picture saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
         {
             if (succeeded)
             {

                 [picture setValue:imageOrVideo forKey:PF_PICTURES_PICTURE];
                 [picture saveInBackground];

                 _countDownToPhotoRefresh--;

                 if (_countDownToPhotoRefresh == 0)
                 {
                     [ProgressHUD dismiss];

                     PFObject *lastPicture = self.savedPhotoObjects.lastObject;

                     SendPushNotification(self.selectedRoom, @"New Picture!");
                     UpdateMessageCounter(self.selectedRoom, @"New Picture!", lastPicture);

                     ChatView *chatView = [[ChatView alloc] initWith:self.selectedRoom
                                                                name:self.selectedText];
                     chatView.isNewChatroomWithPhotos = YES;
                     chatView.selectedSetForPictures = self.selectedSet;
                     chatView.isNewNewConversation = _isNewNewConversation;
                     
                     PostNotification(NOTIFICATION_REFRESH_INBOX);
                     PostNotification(NOTIFICATION_CLEAR_CAMERA_STUFF);

                     [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_OPEN_CHAT_VIEW object:chatView userInfo:@{@"view": chatView}];

                     self.buttonSend.userInteractionEnabled = YES;

                     _didSendPictures = YES;
                 }
             }
             else
             {
                 if (self.navigationController.visibleViewController == self && picture == self.savedPhotoObjects.lastObject && _countDownToPhotoRefresh == 0)
                 {
                     [ProgressHUD showError:NETWORK_ERROR];
                 }
             }
         }];
    }
        } else {
             [ProgressHUD showError:NETWORK_ERROR];
         }
     }];
}

-(void)viewWillAppear:(BOOL)animated
{
    if (_didSendPictures)
    {
        [self.navigationController popViewControllerAnimated:0];
    }

    [self loadMessages];
}

- (void)sendBackPictures:(NSArray *)images withBool:(bool)didTakePicture andComment:(NSString *)comment
{
    _didTheyHitSendYet = NO;
    self.savedPhotoObjects = [NSMutableArray new];
    self.savedImageFiles = [NSMutableArray new];

    //Send back set and pictures to camera view? Then delete if they remove all pictures?

    _selectedSet = [PFObject objectWithClassName:PF_SET_CLASS_NAME];

    __block int count = (int)images.count;

    for (id imageOrFile in images)
    {
        if ([imageOrFile isKindOfClass:[UIImage class]])
        {
            UIImage *image = imageOrFile;
            NSData *dataPicture = UIImageJPEGRepresentation(image, .5);
            PFFile *imageFile = [PFFile fileWithName:@"image.png"
                                                data:dataPicture];

            PFObject *picture = [PFObject objectWithClassName:PF_PICTURES_CLASS_NAME];
            [picture setValue:[PFUser currentUser] forKey:PF_PICTURES_USER];
            [picture setValue:@YES forKey:PF_CHAT_ISUPLOADED];
            [picture setValue:[NSDate dateWithTimeIntervalSinceNow:.1 * [images indexOfObject:image]]forKey:PF_PICTURES_UPDATEDACTION];
            UIImage *thumbnail = ResizeImage(image, image.size.width, image.size.height);
            PFFile *file = [PFFile fileWithName:@"thumbnail.png" data:UIImageJPEGRepresentation(thumbnail, .2)];
            [picture setObject:file forKey:PF_PICTURES_THUMBNAIL];
            [picture setValue:_selectedSet forKey:PF_PICTURES_SETID];

            [self.savedPhotoObjects addObject:picture];
            [self.savedImageFiles addObject:imageFile];

            [picture saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error)
                {
                    NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), [NSString stringWithFormat:@"cache%@.mov", picture.objectId]];
                    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    if (![fileManager fileExistsAtPath:outputPath])
                    {
                        PFFile *file = [picture objectForKey:PF_PICTURES_PICTURE];
                        [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                            if (!error) {
                                [dataPicture writeToFile:outputPath atomically:1];
                            }
                        }];
                    }

                    count--;
                    if (count == 0)
                    {
                        if (_didTheyHitSendYet == YES) [self incrementChatroom];
                        else _didTheyHitSendYet = YES;
                    }
                    if (picture == self.savedPhotoObjects.firstObject)
                    {
                        [_selectedSet setValue:picture forKey:PF_SET_LASTPICTURE];
                    }
                }
            }];

        }
        else if ([imageOrFile isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *dic = imageOrFile;
            NSString *path = dic.allKeys.firstObject;
            UIImage *image = dic.allValues.firstObject;

            PFFile *video = [PFFile fileWithName:@"video.mov" contentsAtPath:path];

            PFObject *picture = [PFObject objectWithClassName:PF_PICTURES_CLASS_NAME];
            [picture setValue:[PFUser currentUser] forKey:PF_PICTURES_USER];
            [picture setValue:@YES forKey:PF_CHAT_ISUPLOADED];

            [picture setValue:[NSDate dateWithTimeIntervalSinceNow:.1 * [images indexOfObject:imageOrFile]]forKey:PF_PICTURES_UPDATEDACTION];

            UIImage *thumbnail = image;
            PFFile *fileThumb = [PFFile fileWithName:@"thumbnail.png" data:UIImageJPEGRepresentation(thumbnail, .2)];

            [picture setObject:fileThumb forKey:PF_PICTURES_THUMBNAIL];
            [picture setValue:_selectedSet forKey:PF_PICTURES_SETID];

            [picture setValue:@YES forKey:PF_PICTURES_IS_VIDEO];
            //      [picture setObject:imageFile forKey:PF_PICTURES_PICTURE];

            [self.savedPhotoObjects addObject:picture];
            [self.savedImageFiles addObject:video];

            NSLog(@"VIDEO");

            [picture saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error)
                {
                    NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), [NSString stringWithFormat:@"cache%@.mov", picture.objectId]];
                    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    if (![fileManager fileExistsAtPath:outputPath])
                    {
                        [[NSData dataWithContentsOfFile:path] writeToFile:outputPath atomically:1];
                    }

                    count--;
                    if (count == 0)
                    {
                        if (_didTheyHitSendYet == YES) [self incrementChatroom];
                        else _didTheyHitSendYet = YES;
                    }

                    if (picture == self.savedPhotoObjects.firstObject)
                    {
                        [_selectedSet setValue:picture forKey:PF_SET_LASTPICTURE];
                    }
                }
            }];

            //SET ISVIDEO TO TRUE.
            //GRAB A SCREENSHOT FROM SOMEWHERE
            //SAVE THAT ALL UP.

        }

    }
}

-(void)viewDidDisappear:(BOOL)animated {
    [ProgressHUD dismiss];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:1];

    [[UIApplication sharedApplication] setStatusBarHidden:0 withAnimation:UIStatusBarAnimationSlide];
    self.navigationController.navigationBarHidden = 0;

    if (self.didViewJustLoad) self.didViewJustLoad = NO;
}

- (IBAction)didSelectCompose:(id)sender
{
    [self actionPrivateView];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MessagesCellDot *cell = [tableView dequeueReusableCellWithIdentifier:@"MessagesCell"];
    if (!cell) cell = [[MessagesCellDot alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MessagesCell"];

    [self.arrayOfReusableCells addObject:cell];
    cell.labelInitials.hidden = YES;
    [cell format];

    PFObject *message = [self.messages objectAtIndex:indexPath.row];

    NSString *comment = [message valueForKey:PF_MESSAGES_LASTMESSAGE];
    if ([comment isEqualToString:@""]) {
        comment = @"No comments available";
    }
    cell.labelLastMessage.text = comment;

    UIColor *green = [UIColor benFamousGreen];
    cell.labelDescription.textColor = green;
    cell.imageUser.layer.borderColor = green.CGColor;

    if (message == self.selectedMessage)
    {
        cell.imageUser.layer.borderColor = [UIColor whiteColor].CGColor;
        cell.labelInitials.backgroundColor = [UIColor benFamousGreen];
        cell.backgroundColor = [UIColor benFamousOrange];
        cell.labelDescription.textColor = [UIColor whiteColor];
        cell.labelLastMessage.textColor = [UIColor whiteColor];
    }
    else
    {
        cell.backgroundColor = [UIColor whiteColor];
        cell.labelDescription.textColor = [UIColor benFamousGreen];
        cell.labelLastMessage.textColor = [UIColor lightGrayColor];
        cell.imageUser.layer.borderColor = [UIColor benFamousGreen].CGColor;
    }

    if (message[PF_MESSAGES_NICKNAME])
    {
        cell.labelDescription.text = message[PF_MESSAGES_NICKNAME];
    }
    else
    {
        NSString *description = message[PF_MESSAGES_DESCRIPTION];

        if (description.length)
        {
            cell.labelDescription.text = description;
        }
    }

    PFObject *picture = [message valueForKey:PF_MESSAGES_LASTPICTURE];

    if (picture)
    {
        PFFile *file = [picture valueForKey:PF_PICTURES_THUMBNAIL];

        [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (!error)
            {
                cell.imageUser.image = [UIImage imageWithData:data];
            }
        }];

        PFUser *user = [message valueForKey:PF_MESSAGES_LASTPICTUREUSER];
        NSString *name = [user valueForKey:PF_USER_FULLNAME];
        NSMutableArray *array = [NSMutableArray arrayWithArray:[name componentsSeparatedByString:@" "]];
        [array removeObject:@" "];

        if (array.count == 2)
        {
            NSString *first = array.firstObject;
            NSString *last = array.lastObject;
            first = [first stringByPaddingToLength:1 withString:name startingAtIndex:0];
            last = [last stringByPaddingToLength:1 withString:name startingAtIndex:0];
            name = [first stringByAppendingString:last];
            cell.labelInitials.text = name;
            cell.labelInitials.hidden = NO;
        }
    }

    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width,75)];
    view.backgroundColor = [UIColor colorWithRed:239/255.0f green:239/255.0f blue:244/255.0f alpha:1];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, tableView.frame.size.width, 25)];
    label.text = @"   MY CONVERSATIONS";
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"Arial Rounded MT Bold" size:14];
    label.textColor = [UIColor lightGrayColor];
    [view addSubview:label];
    UIView *view2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 50)];
    //  [self.composeButton setFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 40)];
    [view2 addSubview:self.composeButton];
    [view addSubview:view2];
    return view;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messages.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MessagesCellDot *cell = [tableView cellForRowAtIndexPath:indexPath];
    PFObject *message = [self.messages objectAtIndex:indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:0];

    for (MessagesCellDot *cell in self.arrayOfReusableCells)
    {
        cell.backgroundColor = [UIColor whiteColor];
        cell.labelDescription.textColor = [UIColor benFamousGreen];
        cell.labelLastMessage.textColor = [UIColor lightGrayColor];
        cell.imageUser.layer.borderColor = [UIColor benFamousGreen].CGColor;
    }

    self.selectedMessage = message;

    if (cell && self.selectedMessage)
    {

        if (self.buttonSend.isHidden) {
            self.buttonSend.hidden = NO;
            self.buttonSendArrow.hidden = NO;
            self.buttonSend.alpha = 0;
            [UIView animateWithDuration:.3f animations:^{
                self.buttonSend.alpha = 1;
            }];
        }

        self.selectedRoom = [message objectForKey:PF_MESSAGES_ROOM];
        self.selectedText = cell.labelDescription.text;
        cell.imageUser.layer.borderColor = [UIColor whiteColor].CGColor;
        cell.labelInitials.backgroundColor = [UIColor benFamousGreen];
        cell.backgroundColor = [UIColor benFamousOrange];
        cell.labelDescription.textColor = [UIColor whiteColor];
        cell.labelLastMessage.textColor = [UIColor whiteColor];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.composeButton.titleLabel.textColor = [UIColor benFamousGreen];

    self.buttonSendArrow.frame = CGRectMake(self.view.frame.size.width/2 - 12, self.view.frame.size.height - 30, 25, 25);

    [self.tableView registerNib:[UINib nibWithNibName:@"MessagesCellDot" bundle:0] forCellReuseIdentifier:@"MessagesCell"];

    [self.navigationController.navigationBar setTintColor:[UIColor benFamousGreen]];
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithWhite:.98 alpha:1]];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:1];

    self.navigationController.navigationBar.titleTextAttributes =  @{
                                                                     NSForegroundColorAttributeName: [UIColor benFamousGreen],
                                                                     NSFontAttributeName: [UIFont fontWithName:@"Helvetica Neue" size:20.0f],
                                                                     NSShadowAttributeName:[NSShadow new]
                                                                     };

    //Return to dismiss textview
    _composeButton.backgroundColor = [UIColor whiteColor];
    _composeButton.titleLabel.textColor = [UIColor benFamousGreen];
    _composeButton.tintColor = [UIColor benFamousGreen];

    self.navigationController.navigationBarHidden = 0;
    self.view.backgroundColor = [UIColor whiteColor];

    self.messages = [NSMutableArray new];
    self.arrayOfReusableCells = [NSMutableArray new];

    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                   initWithTitle: @"Back"
                                   style: UIBarButtonItemStyleBordered
                                   target: nil action: nil];
    [self.navigationItem setBackBarButtonItem: backButton];

    self.title = @"Send to...";

    self.didViewJustLoad = YES;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    [self.view addGestureRecognizer:tap];
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [[UIApplication sharedApplication] setStatusBarHidden:0 withAnimation:UIStatusBarAnimationSlide];
    [self.view removeGestureRecognizer:tap];
}

- (void)textViewDidChange:(UITextView *)textView
{
    if ([textView.text containsString:@"\n"]) {
        [textView deleteBackward];
        [textView scrollsToTop];
        [textView resignFirstResponder];
    }
}

- (void) actionPrivateView
{
    CreateChatroomView *view2 = [[CreateChatroomView alloc] init];
    view2.delegate = self;
    view2.isTherePicturesToSend = YES;
    [self.navigationController pushViewController:view2 animated:1];
}

- (IBAction)actionSend:(UIButton *)sender
{
    //Save the photos, dismiss the view, open the chatview, slideRight in background, refresh when all is saved and done.

    self.buttonSend.userInteractionEnabled = NO;

    if (self.selectedRoom)
    {
        //Increment number of sets in chatroom and for new set.

        if (_didTheyHitSendYet == NO)
        {
            _didTheyHitSendYet = YES;
        }
        else
        {
            [self incrementChatroom];
        }
    }
    else
    {
        self.buttonSend.userInteractionEnabled = YES;
        [ProgressHUD showError:@"No Conversation Selected"];
    }
}

-(void)incrementChatroom
{
    PFQuery *query = [PFQuery queryWithClassName:PF_SET_CLASS_NAME];
    [query whereKey:PF_SET_ROOM equalTo:self.selectedRoom];
    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (!error)
        {
            [_selectedSet setValue:@(number) forKey:PF_SET_ROOMNUMBER];
             [_selectedSet setValue:_selectedRoom forKey:PF_SET_ROOM];
             [_selectedSet setValue:[PFUser currentUser] forKey:PF_SET_USER];
             [self savePicturesWithRoom:self.selectedRoom];
         }
         else
         {
             [ProgressHUD showError:NETWORK_ERROR];
             NSLog(@"Error sending %@", error.userInfo);
         }
     }];
}

- (void)actionClose
{
    [self dismissViewControllerAnimated:0 completion:0];
}

- (void)loadMessages
{
    if ([PFUser currentUser])
    {
        self.composeButton.enabled = NO;
        NavigationController *nav  = [(AppDelegate *)[[UIApplication sharedApplication] delegate] navInbox];
        // LOAD MESSAGES FROM INBOX INSTEAD.
        MessagesView *view = nav.viewControllers.firstObject;
        _messages = view.messages;

        view.scrollView.scrollEnabled = NO;
        if (_messages.count > 0) {
            [self.tableView reloadData];
            self.composeButton.enabled = YES;
            [self updateEmptyView];
        } else {
            self.composeButton.enabled = YES;
            [self updateEmptyView];
        }
        
    }
}

- (void)updateEmptyView
{
    if (_messages.count == 0) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 180, self.view.frame.size.width, 70)];
        label.text = @"No Inbox Messages";
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor lightGrayColor];
        //        label.font = [UIFont systemFontOfSize:14];
        [self.tableView addSubview:label];
    } else {
        for (UILabel *label in self.tableView.subviews) {
            if ([label isKindOfClass:[UILabel class]]) {
                [label removeFromSuperview];
            }
        }
    }
}
@end
