
#import <Parse/Parse.h>
#import "ProgressHUD.h"
#import "AppConstant.h"
#import "messages.h"
#import "pushnotification.h"
#import "utilities.h"
#import "IQKeyboardManager.h"
#import "camera.h"
#import "SettingsViewController.h"
#import "utilities.h"
#import "MasterLoginRegisterView.h"
#import "MasterScrollView.h"
#import "MessagesView.h"
#import "MessagesCell.h"
#import "ChatView.h"
#import "CustomCameraView.h"
#import "UIColor.h"
#import "CustomCollectionViewCell.h"
#import "LoginView.h"
#import "CreateChatroomView.h"
#import "NSDate+TimeAgo.h"
#import <sys/utsname.h> // Device name.
#import "AppDelegate.h"

@interface MessagesView ()

@property UITapGestureRecognizer *tap;
@property UILongPressGestureRecognizer *longPress;
@property NSMutableArray *savedPhotoObjects; /// NOT USED
@property NSMutableDictionary *colorsForRoom;
@property NSMutableArray *savedDates;
@property NSMutableDictionary *savedMessagesForDate;

@property NSMutableArray *customChatPictures;
@property NSMutableArray *customChatMessages;
@property NSMutableArray *arrayOfAvailableColors;

@property UIColor *customColor;
@property NSString *customSetId;
@property NSString *customChatTitle;

@property PFObject *commentObject; //comment send by delegate
@property PFObject *albumToDelete;
@property PFObject *messageToRenameDelete;

@property BOOL didViewJustLoad;
@property NSIndexPath *indexForDelete;
@property BOOL isRefreshingUp;
@property BOOL isRefreshingDown;

@property IBOutlet UILabel *labelNoMessages;

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIImageView *imageView2;

@property IBOutlet UIView *viewHeader;

@property IBOutlet UISearchBar *searchBar;
@property IBOutlet UITextField *searchTextField;
@property IBOutlet UIButton *searchCloseButton;
@property NSMutableArray *searchMessages;
@property BOOL isSearching;

@property (strong, nonatomic) IBOutlet UIButton *composeButton;
@property (strong, nonatomic) IBOutlet UIButton *albumButton;

@property BOOL isRefreshIconsOverlap;
@property BOOL isLoadingChatView;
@property BOOL isRefreshAnimating;

@property UIView *refreshLoadingView;
@property UIImageView *compassSpinner;
@property UIView *refreshColorView;
@property UIImageView *compassBackground;
@property  UIRefreshControl *refreshControl;

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *viewEmpty;

@property int x;
@property BOOL isLoadingMessages;

@end

@implementation MessagesView

- (IBAction)didSelectCompose:(id)sender
{
    CreateChatroomView *chat = [CreateChatroomView new];
    chat.isTherePicturesToSend = NO;
    self.hidesBottomBarWhenPushed = true;
    [self.navigationController pushViewController:chat animated:1];
    self.hidesBottomBarWhenPushed = false;
}

#pragma mark - NOTIFICATION

- (void)enableScrollview:(NSNotification *)notification
{
    self.scrollView.scrollEnabled = YES;
}

- (void)disableScrollView:(NSNotification *)notification
{
    self.scrollView.scrollEnabled = NO;
}

//Pushes notifcation with room ID so I can pop it open.
- (void)openChatNotification:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
#warning FRAGILE
    ChatView *chat = [dict valueForKey:@"view"];
    [self openView:chat];
}

- (void)openView:(UIViewController *)view2
{
    [self.scrollView setContentOffset:CGPointMake([UIScreen mainScreen].bounds.size.width, 0) animated:0];

    if ([self.navigationController.viewControllers.lastObject isKindOfClass:[ChatView class]])
    {
        [self.navigationController popViewControllerAnimated:0];
    }
    /// IF CUSTOM CHAT ROOM IS SAME AS ROOM BEFORE, POP THE STACK ONCE.
    self.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:view2 animated:0];
    self.hidesBottomBarWhenPushed = NO;
}

- (void)longPress:(UILongPressGestureRecognizer *)press
{
    CGPoint point = [press locationInView:self.tableView];

    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[self.tableView indexPathForRowAtPoint:point]];

    if (cell)
    {
        [self.tableView setEditing:1 animated:1];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(didPressEdit)];
        self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
        self.tap.delegate = self;
        [self.tableView addGestureRecognizer:self.tap];
    }
}

- (void)didTap:(UITapGestureRecognizer *)tapppppp
{
    CGPoint point = [tapppppp locationInView:self.tableView];

    if (point.x > 50 && self.tap) {
        [self.tableView setEditing:0 animated:1];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(didPressEdit)];
        [self.tableView removeGestureRecognizer:self.tap];
        self.tap = nil;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    //This is called ALWAYS because of longPress???
    CGPoint point = [touch locationInView:self.view];

    if (self.tableView.editing) {
        if (point.x < 50)
        {
            //Let the button work
            return NO;
        } else {
            return YES;
        }
    } else {
        return NO;
    }
}

- (void)viewDidLoad
{
    [IQKeyboardManager sharedManager].enableAutoToolbar = NO;

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(didPressEdit)];

    [super viewDidLoad];

    self.viewEmpty.hidden = YES;
    self.didViewJustLoad = YES;
    self.navigationItem.title = @"SnapBen";

    self.longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self.view addGestureRecognizer:self.longPress];

    /*
    _composeButton.titleLabel.text = @"NEW CONVERSATION";
    _composeButton.titleLabel.textColor = [UIColor benFamousGreen];
    [_composeButton setImage:[[UIImage imageNamed:@"Compose"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    _composeButton.tintColor = [UIColor benFamousGreen];
    _composeButton.imageView.tintColor = [UIColor benFamousGreen];
    [self.view addSubview:self.composeButton];
     */

    _searchCloseButton.hidden = YES;
    [self clearAll];
    [self setupRefreshControl];
    [self setUpNavBar];

    UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    [_searchTextField setLeftViewMode:UITextFieldViewModeAlways];
    [_searchTextField setLeftView:spacerView];

    [self.tableView registerNib:[UINib nibWithNibName:@"MessagesCell" bundle:0] forCellReuseIdentifier:@"MessagesCell"];

    self.tableView.backgroundColor = [UIColor whiteColor];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMessages) name:NOTIFICATION_USER_LOGGED_OUT object:0];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMessages) name:NOTIFICATION_USER_LOGGED_IN object:0];


    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMessages) name:NOTIFICATION_REFRESH_INBOX object:0];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadDataTableView) name:NOTIFICATION_RELOAD_INBOX object:0];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openChatNotification:) name:NOTIFICATION_OPEN_CHAT_VIEW object:0];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableScrollview:) name:NOTIFICATION_ENABLESCROLLVIEW object:0];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disableScrollView:) name:NOTIFICATION_DISABLESCROLLVIEW object:0];

    [self refreshMessages];
}

-(void)reloadDataTableView
{
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    //Needed to scroll tableview to hide searchbar.
    self.edgesForExtendedLayout = UIRectEdgeNone;

    //Deleted && !_isArchive
    if (self.navigationController.visibleViewController == self)
    {
        self.scrollView.scrollEnabled = YES;
    }
    else
    {
        self.scrollView.scrollEnabled = NO;
    }

    if (self.didViewJustLoad) [self.searchBar resignFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [[UIApplication sharedApplication] setStatusBarHidden:NO
                                            withAnimation:UIStatusBarAnimationFade];
    [self.tableView reloadData];
    [self updateEmptyView];

    self.didViewJustLoad = NO;
}

- (void) clearAll
{
    self.messages = [[NSMutableArray alloc] init];
    self.savedDates = [NSMutableArray new];
    self.savedMessagesForDate = [NSMutableDictionary new];
    self.messagesObjectIds = [NSMutableArray new];
    self.colorsForRoom = [NSMutableDictionary new];
    self.arrayOfAvailableColors = [NSMutableArray arrayWithArray: [AppConstant arrayOfColors]];
}

-(void)viewWillDisappear:(BOOL)animated
{
    self.scrollView.scrollEnabled = NO;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 2, self.view.frame.size.width, 22)];
    label.textColor = [UIColor lightGrayColor];

    label.textAlignment = NSTextAlignmentLeft;

    label.layer.shadowOffset = CGSizeMake(0, 0);
    label.layer.shadowColor = [UIColor lightGrayColor].CGColor;
    label.layer.shadowRadius = 1.0;
    label.layer.shadowOpacity = 0.4;

    label.font = [UIFont fontWithName:@"Helvetica Bold" size:15];
    //    label.backgroundColor = [UIColor colorWithRed:239/255.0f green:239/255.0f blue:244/255.0f alpha:1];
    label.backgroundColor = [UIColor whiteColor];

    if (self.savedDates.count)
    {
        NSDate *date = [self.savedDates objectAtIndex:section];
        NSDateFormatter *dateFormate = [[NSDateFormatter alloc] init];
        [dateFormate setDateFormat:@"MMMM dd"];
        NSString *dateString = [dateFormate stringFromDate:date];
        dateString = [@"  " stringByAppendingString:dateString];
        if ([date isEqualToDate:[self dateAtBeginningOfDayForDate:[NSDate date]]]) {
            label.text = @"   Today";
        } else {
            label.text = [@"  " stringByAppendingString:dateString];
        }
    }
    return label;
}

#pragma mark - Backend methods

//Grab all messages with MY NAME ON IT.
- (void)loadInbox
{
    if ([PFUser currentUser] && _isLoadingMessages == NO)
    {
        NSLog(@"LOADING INBOX");

        _isLoadingMessages = YES;

        PFQuery *query = [PFQuery queryWithClassName:PF_MESSAGES_CLASS_NAME];

        [query whereKey:PF_MESSAGES_USER equalTo:[PFUser currentUser]];
        //      [query includeKey:PF_MESSAGES_LASTUSER];
        [query includeKey:PF_MESSAGES_ROOM];
        [query includeKey:PF_MESSAGES_USER];
        [query includeKey:PF_MESSAGES_LASTPICTURE];
        [query includeKey:PF_MESSAGES_LASTPICTUREUSER];
        [query whereKey:PF_MESSAGES_HIDE_UNTIL_NEXT equalTo:@NO];

        //      PFObject *message = messages.lastObject;
        //    if (message) [query whereKey:PF_MESSAGES_UPDATEDACTION greaterThan:message.updatedAt];

        //Clear the cache if there is a delete.
        //        [query clearCachedResult];

        [query orderByDescending:PF_MESSAGES_UPDATEDACTION];

        [query setCachePolicy:kPFCachePolicyCacheThenNetwork];

        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
         {
             if (!error)
             {
                 [self clearAll];

                 for (PFObject *message in objects)
                 {
                     if (![self.messagesObjectIds containsObject:message.objectId])
                     {
                         [self.messages addObject:message];
                         NSDate *date = [message valueForKey:PF_MESSAGES_UPDATEDACTION];
                         date = [self dateAtBeginningOfDayForDate:date];

                         if (![self.savedDates containsObject:date])
                         {
                             [self.savedDates addObject:date];
                             NSMutableArray *array = [NSMutableArray arrayWithObject:message];
                             NSDictionary *dict = [NSDictionary dictionaryWithObject:array forKey:date];
                             [self.savedMessagesForDate addEntriesFromDictionary:dict];
                         }
                         else
                         {
                             [(NSMutableArray *)[self.savedMessagesForDate objectForKey:date] addObject:message];
                         }
                     }
                 }

                 [self.tableView reloadData];
                 _isLoadingMessages = NO;
                 //Scroll search bar up a notch.
                 [self updateEmptyView];
             }
             else
             {
                 if ([query hasCachedResult]) {
                     if (self.navigationController.visibleViewController == self) {
                         NSLog(@"%@", error.userInfo);
                         [self.refreshControl endRefreshing];
                         [ProgressHUD showError:NETWORK_ERROR];
                     }
                 }
             }
             [_refreshControl endRefreshing];
         }];
    }
}

- (NSDate *)dateAtBeginningOfDayForDate:(NSDate *)inputDate
{
    //Convert to my time zone
    NSTimeZone *tz = [NSTimeZone defaultTimeZone];
    NSInteger seconds = [tz secondsFromGMTForDate:inputDate];
    NSDate *date = [NSDate dateWithTimeInterval: seconds sinceDate:inputDate];
    // Use the user's current calendar and time zone
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
    [calendar setTimeZone:timeZone];

    // Selectively convert the date components (year, month, day) of the input date
    NSDateComponents *dateComps = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:date];

    // Set the time components manually
    [dateComps setHour:0];
    [dateComps setMinute:0];
    [dateComps setSecond:0];
    // Convert back
    NSDate *beginningOfDay = [calendar dateFromComponents:dateComps];
    return beginningOfDay;
}

-(void)actionSettings
{
    NavigationController *nav = [[NavigationController alloc] initWithRootViewController: [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped]];

    [self showDetailViewController:nav sender:self];
}

-(void)setUpNavBar
{
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView.backgroundColor = [UIColor clearColor];

    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(didSelectCompose:)];
    self.navigationItem.rightBarButtonItem = item;

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStyleDone target:self action:0];
}


-(void)actionFavorties:(UIBarButtonItem *)button
{
    [self.scrollView setContentOffset:CGPointMake(self.view.frame.size.width * 2, 0) animated:1];
}

- (IBAction)actionBack:(UIBarButtonItem *)button
{
    [self.scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
}

- (IBAction)actionSettings:(UIButton *)button
{
    [UIView animateWithDuration:.3 animations:^{
        button.transform = CGAffineTransformMakeScale(0.3,0.3);
        button.transform = CGAffineTransformMakeScale(1,1);
    }];
}

- (void) changeBackgroundColor
{
    UIColor *randomColor = [[UIColor arrayOfColorsCore] objectAtIndex:arc4random_uniform((int)[UIColor arrayOfColorsCore].count)];
    [UIView animateWithDuration:.3 animations:^{
        self.view.backgroundColor = randomColor;
    }];
}

//REFRESH CONTROL
- (void)refreshMessages
{
    if ([[[PFUser currentUser] valueForKey:PF_USER_ISVERIFIED] isEqualToNumber:@YES])
    {
        [self loadInbox];
    }
    else
    {
        MasterLoginRegisterView *login = [MasterLoginRegisterView new];
        [self.navigationController showDetailViewController:login sender:self];
        [self.scrollView setContentOffset:CGPointMake(self.view.frame.size.width, 0) animated:1];
        [self actionCleanup];
    }
}

#pragma mark - Helper methods

//IF NO MESSAGES, SHOW VIEW.
- (void)updateEmptyView
{
    self.viewEmpty.hidden = (self.messages.count > 0) ? YES: NO;

    if (!self.viewEmpty.isHidden)
    {
        self.tableView.separatorColor = [UIColor clearColor];
    }
    else
    {
        if (self.messages.count > 5)
        {
            self.tableView.tableHeaderView = self.viewHeader;
        }

        self.tableView.separatorColor = [UIColor colorWithRed:.8f green:.8f blue:.8f alpha:.9f];
    }
}

#pragma mark - User actions

//PART OF CAMERA BUTTON.
- (IBAction)buttonRelease:(UIButton*)button {
    // Do something else
    [UIView animateWithDuration:.3f animations:^{
        button.transform = CGAffineTransformMakeScale(3,3);
    }];
}

//WHEN YOU LOGOUT AND STUFF.
- (void)actionCleanup
{
    [self.messages removeAllObjects];
    [self.messagesObjectIds removeAllObjects];
    [self.savedDates removeAllObjects];
    [self.savedMessagesForDate removeAllObjects];

    //Clear the cache of videos.
    NSArray* tmpDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:NULL];
    for (NSString *file in tmpDirectory) {
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file] error:NULL];
    }

    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_isSearching) {
        return 1;
    }
        return self.savedDates.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_isSearching)
    {
        return _searchMessages.count;
    }
    else
    {
        NSDate *dateRepresentingThisDay = [self.savedDates objectAtIndex:section];
        NSArray *eventsOnThisDay = [self.savedMessagesForDate objectForKey:dateRepresentingThisDay];
        return [eventsOnThisDay count];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 90;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MessagesCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MessagesCell" forIndexPath:indexPath];

    if (!cell) cell = [[MessagesCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MessagesCell"];

    [cell format];

    cell.labelInitials.hidden = YES;

    if (self.savedDates.count)
    {
        PFObject *message;

        if (_isSearching && _searchMessages.count)
        {
            message = [_searchMessages objectAtIndex:indexPath.row];
        }
        else
        {
            NSDate *dateRepresentingThisDay = [self.savedDates objectAtIndex:indexPath.section];
            NSArray *eventsOnThisDay = [self.savedMessagesForDate objectForKey:dateRepresentingThisDay];
            message = [eventsOnThisDay objectAtIndex:indexPath.row];
        }

        PFObject *pictureObject = [message valueForKey:PF_MESSAGES_LASTPICTURE];
        if (pictureObject)
        {
            PFUser *user = [message valueForKey:PF_MESSAGES_LASTPICTUREUSER];
            NSString *name = [user valueForKey:PF_USER_FULLNAME];

            if (name && name.length)
            {
                NSMutableArray *array = [NSMutableArray arrayWithArray:[name componentsSeparatedByString:@" "]];
                [array removeObject:@" "];
                NSString *first = array.firstObject;
                NSString *last = array.lastObject;
                if (first.length && last.length) {
                    first = [first stringByPaddingToLength:1 withString:name startingAtIndex:0];
                    last = [last stringByPaddingToLength:1 withString:name startingAtIndex:0];
                    name = [first stringByAppendingString:last];
                    cell.labelInitials.text = name;
                    cell.labelInitials.hidden = NO;
                }
            }

            PFFile *file = [pictureObject valueForKey:PF_PICTURES_THUMBNAIL];
            cell.imageUser.file = file;
            [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                if (!error) {
                    cell.imageUser.image = [UIImage imageWithData:data];
                }
            }];
        }
        else
        {
            cell.imageUser.image = [UIImage imageNamed:@"Blank V"];
        }

        UIColor *selectedColor = [UIColor benFamousGreen];
        cell.imageUser.layer.borderColor = selectedColor.CGColor;
        cell.tableBackgroundColor = selectedColor;

        [cell bindData:message];
    }
    return cell;
}

- (UIColor *)convertColorStringToColorWorkAround:(NSString *)string
{
    NSArray * colorParts = [string componentsSeparatedByString: @" "];
    CGFloat red = [[colorParts objectAtIndex:0] floatValue];
    CGFloat green = [[colorParts objectAtIndex:1] floatValue];
    CGFloat blue = [[colorParts objectAtIndex:2] floatValue];
    CGFloat alpha = [[colorParts objectAtIndex:3] floatValue];

    UIColor * newColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];

    return newColor;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
    //Required for edit actions
}

-(void)didPressEdit
{
    if (self.tableView.isEditing)
    {
        [self.tableView setEditing:0 animated:1];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(didPressEdit)];
    }
    else
    {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(didPressEdit)];
        [self.tableView setEditing:1 animated:1];
//        tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
//        tap.delegate = self;
//        [self.tableView addGestureRecognizer:tap];
    }
}

-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewRowAction *button = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Delete" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {

        [self.tableView setEditing:0 animated:1];

        NSDate *dateRepresentingThisDay = [self.savedDates objectAtIndex:indexPath.section];

        NSMutableArray *eventsOnThisDay = [self.savedMessagesForDate objectForKey:dateRepresentingThisDay];

        PFObject  *message = [eventsOnThisDay objectAtIndex:indexPath.row];

        [message setValue:@YES forKey:PF_MESSAGES_HIDE_UNTIL_NEXT];

        [message saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                //Remove all traces of messages
                [[self.savedMessagesForDate objectForKey:dateRepresentingThisDay] removeObject:message];
                [self.messagesObjectIds removeObject:message.objectId];
                [self.messages removeObject:message];

                //Animation
                [self.tableView beginUpdates];
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView endUpdates];

                //
                [self updateEmptyView];
            }
            else NSLog(@"DeleteMessageItem delete error.");
        }];
    }];

    button.backgroundColor = [UIColor redColor]; //arbitrary color

    UITableViewRowAction *button2 = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Rename" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {

        [self.tableView setEditing:0 animated:1];

        NSDate *dateRepresentingThisDay = [self.savedDates objectAtIndex:indexPath.section];
        NSArray *eventsOnThisDay = [self.savedMessagesForDate objectForKey:dateRepresentingThisDay];
        self.messageToRenameDelete = [eventsOnThisDay objectAtIndex:indexPath.row];

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Rename..." message:0 delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Rename", nil];

        alert.alertViewStyle = UIAlertViewStylePlainTextInput;

        if (self.messageToRenameDelete[PF_MESSAGES_NICKNAME])
        {
            [alert textFieldAtIndex:0].text = [self.messageToRenameDelete valueForKey:PF_ALBUMS_NICKNAME];
        }

        [alert show];
    }];

    button2.backgroundColor = [UIColor colorWithRed:.75f green:.75f blue:.75f alpha:1]; //arbitrary color

    return @[button, button2]; //array with all the buttons you want. 1,2,3, etc...
}

#pragma mark - ALERTVIEW

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{

    if (buttonIndex != alertView.cancelButtonIndex && [alertView.title isEqualToString:@"New Album"] && [alertView textFieldAtIndex:0].hasText)
    {
        PFObject *album = [PFObject objectWithClassName:PF_ALBUMS_CLASS_NAME];
        [album setValue:[[alertView textFieldAtIndex:0].text capitalizedString] forKey:PF_ALBUMS_NICKNAME];
        [album setValue:[PFUser currentUser] forKey:PF_ALBUMS_USER];

        [album saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
         {
             if (succeeded)
             {
                 [self.messages insertObject:album atIndex:0];
                 [self.messagesObjectIds insertObject:album atIndex:0];

                 NSIndexPath *indexpath = [NSIndexPath indexPathForRow:0 inSection:0];
                 [self.tableView insertRowsAtIndexPaths:@[indexpath] withRowAnimation:UITableViewRowAnimationAutomatic];

                 //Clear the favorites cache.
                 PFQuery *query = [PFQuery queryWithClassName:PF_ALBUMS_CLASS_NAME];
                 [query clearCachedResult];

                 [self updateEmptyView];
                 [self.tableView setEditing:0 animated:1];
             }
             else
             {
                 NSLog(@"Save Album Error %@", error.userInfo);
             }
         }];
    }

    if ([alertView.title isEqualToString:@"Delete Album"] && buttonIndex != alertView.cancelButtonIndex)
    {
        __block NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.messages indexOfObject:self.albumToDelete] inSection:0];

        [self.messages removeObject:self.albumToDelete];

        //        This will ensure it does not come back from the dead.
        //        [messagesObjectIds removeObject:albumToDelete.objectId];

        [self.albumToDelete deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded)
            {
                [self.tableView setEditing:0 animated:1];

                //Delete all the favorites in the album
                PFQuery *query = [PFQuery queryWithClassName:PF_FAVORITES_CLASS_NAME];
                [query whereKey:PF_FAVORITES_ALBUM equalTo:self.albumToDelete];
                [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    if (!error) {
                        [PFObject deleteAllInBackground:objects];
                    }
                }];

                PFQuery *query2 = [PFQuery queryWithClassName:PF_ALBUMS_CLASS_NAME];
                [query2 clearCachedResult];

                [self.tableView beginUpdates];
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
                [self.tableView endUpdates];

                [self updateEmptyView];
            } else {
                NSLog(@"Delete album Error %@", error.userInfo);
            }
        }];

    }
    else if ([alertView.title isEqualToString:@"Rename..."] && buttonIndex != alertView.cancelButtonIndex)
    {

        if ([alertView textFieldAtIndex:0].hasText) {

            NSString *string = [alertView textFieldAtIndex:0].text;

            if (string.length) {
                [self.messageToRenameDelete setValue:[alertView textFieldAtIndex:0].text forKey:PF_MESSAGES_NICKNAME];
            } else {
                [self.messageToRenameDelete setValue:@"" forKey:PF_MESSAGES_NICKNAME];
            }

            [self.messageToRenameDelete saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded)
                {
                    [self.tableView setEditing:0 animated:1];
                    [self.tableView reloadData];
                } else {
                    NSLog(@"Rename Error %@", error.userInfo);
                }
            }];

        } else {

            [ProgressHUD showError:@"Cancelled"];
            NSLog(@"canceled rename");
            [alertView dismissWithClickedButtonIndex:0 animated:1];
        }
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:1];

    MessagesCell *cell = [tableView cellForRowAtIndexPath:indexPath];

    PFObject *message;
    if (_isSearching && _searchMessages.count)
    {
        message = [_searchMessages objectAtIndex:indexPath.row];
    }
    else
    {
        if (self.savedDates.count)
        {
            NSDate *dateRepresentingThisDay = [self.savedDates objectAtIndex:indexPath.section];
            NSArray *eventsOnThisDay = [self.savedMessagesForDate objectForKey:dateRepresentingThisDay];
            message = [eventsOnThisDay objectAtIndex:indexPath.row];
        }
    }

    if (message)
    {
        PFObject *room = [message objectForKey:PF_MESSAGES_ROOM];
        ChatView *chatView = [[ChatView alloc] initWith:room
                                                   name:cell.labelDescription.text];
        chatView.message = message;

        chatView.title = cell.labelDescription.text;

        /*
         CATransition* transition = [CATransition animation];
         transition.duration = 0.3;
         transition.type = kCATransitionPush;
         transition.subtype = kCATransitionFromRight;
         transition.timingFunction = UIViewAnimationCurveEaseInOut;
         transition.fillMode = kCAFillModeForwards;
         [self.navigationController.view.layer addAnimation:transition forKey:kCATransition];
         */

        self.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:chatView animated:YES];
        self.hidesBottomBarWhenPushed = NO;
    }
}

- (void)setupRefreshControl
{
    // Programmatically inserting a UIRefreshControl
    self.refreshControl = [[UIRefreshControl alloc] init];

    // Setup the loading view, which will hold the moving graphics
    self.refreshLoadingView = [[UIView alloc] initWithFrame:self.refreshControl.bounds];
    self.refreshLoadingView.backgroundColor = [UIColor clearColor];

    // Setup the color view, which will display the rainbowed background
    self.refreshColorView = [[UIView alloc] initWithFrame:self.refreshControl.bounds];
    self.refreshColorView.backgroundColor = [UIColor clearColor];
    self.refreshColorView.alpha = .8;

    // Create the graphic image views
    self.compassBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:ASSETS_NEW_SETTINGS]];
    self.compassSpinner = [[UIImageView alloc] initWithImage:[UIImage imageNamed:ASSETS_NEW_SETTINGS]];

    // Add the graphics to the loading view
    [self.refreshLoadingView addSubview:self.compassBackground];
    [self.refreshLoadingView addSubview:self.compassSpinner];

    // Clip so the graphics don't stick out
    self.refreshLoadingView.clipsToBounds = YES;

    // Hide the original spinner icon
//    self.refreshControl.tintColor = [UIColor clearColor];

    // Add the loading and colors views to our refresh control
//    [self.refreshControl addSubview:self.refreshColorView];
//    [self.refreshControl addSubview:self.refreshLoadingView];

    // Initalize flags
    self.isRefreshIconsOverlap = NO;
    self.isRefreshAnimating = NO;

    // When activated, invoke our refresh function
    [self.refreshControl addTarget:self action:@selector(refreshMessages) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:_refreshControl];
}

-(void)viewDidDisappear:(BOOL)animated {
    [self.tableView setEditing:0 animated:1];
    [self.searchBar setText:0];
}

- (void)animateRefreshView
{
    NSArray *colorArray = [UIColor arrayOfColorsCore];
    static int colorIndex = 0;

    // Flag that we are animating
    self.isRefreshAnimating = YES;

    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         // Rotate the spinner by M_PI_2 = PI/2 = 90 degrees
                         [self.compassSpinner setTransform:CGAffineTransformRotate(self.compassSpinner.transform, M_PI * 2)];

                         // Change the background color
                         self.refreshColorView.backgroundColor = [colorArray objectAtIndex:colorIndex];
                         colorIndex = (colorIndex + 1) % colorArray.count;
                     }
                     completion:^(BOOL finished) {
                         // If still refreshing, keep spinning, else reset
                         if (self.refreshControl.isRefreshing) {
                             [self animateRefreshView];
                         }else{
                             [self resetAnimation];
                         }
                     }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
#warning DISABLE
    return;
    // Get the current size of the refresh controller
    CGRect refreshBounds = self.refreshControl.bounds;

    // Distance the table has been pulled >= 0
    CGFloat pullDistance = MAX(0.0, -self.refreshControl.frame.origin.y);

    // Half the width of the table
    CGFloat midX = self.tableView.frame.size.width / 2.0;

    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       if (pullDistance > 60.0f && !_isRefreshingUp)
                       {
                           _isRefreshingUp = YES;

                           [UIView animateWithDuration:.3f animations:^{
                               self.tableView.backgroundColor = [UIColor benFamousOrange];
                           }];
                       }
                       else if (pullDistance < 60.0f && !_isRefreshingDown)
                       {
                           _isRefreshingDown = YES;
                           [UIView animateWithDuration:.2f animations:^{
                               self.tableView.backgroundColor = [UIColor whiteColor];
                           }];
                       }
                   });

    if (pullDistance  < 5 && _isRefreshingUp == YES && _isRefreshingDown == YES)
    {
        _isRefreshingDown = NO;
        _isRefreshingUp = NO;
    }

    // Calculate the width and height of our graphics
    CGFloat compassHeight = self.compassBackground.bounds.size.height;
    CGFloat compassHeightHalf = compassHeight / 2.0;

    CGFloat compassWidth = self.compassBackground.bounds.size.width;
    CGFloat compassWidthHalf = compassWidth / 2.0;

    CGFloat spinnerHeight = self.compassSpinner.bounds.size.height;
    CGFloat spinnerHeightHalf = spinnerHeight / 2.0;

    CGFloat spinnerWidth = self.compassSpinner.bounds.size.width;
    CGFloat spinnerWidthHalf = spinnerWidth / 2.0;

    // Calculate the pull ratio, between 0.0-1.0
    CGFloat pullRatio = MIN( MAX(pullDistance, 0.0), 100.0) / 100.0;

    // Set the Y coord of the graphics, based on pull distance
    CGFloat compassY = pullDistance / 2.0 - compassHeightHalf;
    CGFloat spinnerY = pullDistance / 2.0 - spinnerHeightHalf;

    // Calculate the X coord of the graphics, adjust based on pull ratio
    CGFloat compassX = (midX + compassWidthHalf) - (compassWidth * pullRatio);
    CGFloat spinnerX = (midX - spinnerWidth - spinnerWidthHalf) + (spinnerWidth * pullRatio);

    // When the compass and spinner overlap, keep them together
    if (fabsf(compassX - spinnerX) < 1.0) {
        self.isRefreshIconsOverlap = YES;
    }

    // If the graphics have overlapped or we are refreshing, keep them together
    //Changed to && from ||
    if (self.isRefreshIconsOverlap || self.refreshControl.isRefreshing) {
        compassX = midX - compassWidthHalf;
        spinnerX = midX - spinnerWidthHalf;
    }

    // Set the graphic's frames
    CGRect compassFrame = self.compassBackground.frame;
    compassFrame.origin.x = compassX;
    compassFrame.origin.y = compassY;

    CGRect spinnerFrame = self.compassSpinner.frame;
    spinnerFrame.origin.x = spinnerX;
    spinnerFrame.origin.y = spinnerY;

    self.compassBackground.frame = compassFrame;
    self.compassSpinner.frame = spinnerFrame;

    // Set the encompassing view's frames
    refreshBounds.size.height = pullDistance;

    self.refreshColorView.frame = refreshBounds;
    self.refreshLoadingView.frame = refreshBounds;

    // If we're refreshing and the animation is not playing, then play the animation
    if (self.refreshControl.isRefreshing && !self.isRefreshAnimating) {
        [self animateRefreshView];
        self.isRefreshIconsOverlap = NO;
    }

    //    NSLog(@"pullDistance: %.1f, pullRatio: %.1f, midX: %.1f, isRefreshing: %i", pullDistance, pullRatio, midX, self.refreshControl.isRefreshing);
}

- (void)resetAnimation
{
    // Reset our flags and background color
    self.isRefreshAnimating = NO;
    self.isRefreshIconsOverlap = NO;
    self.refreshColorView.backgroundColor = [UIColor clearColor];
}

- (NSNumber *)deviceModelName
{
    struct utsname systemInfo;
    uname(&systemInfo);

    NSString *machineName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];

    //MARK: More official list is at
    //http://theiphonewiki.com/wiki/Models
    //MARK: You may just return machineName. Following is for convenience

    NSDictionary *commonNamesDictionary =
    @{
      @"i386":   @14, //@"iPhone Simulator",
      @"x86_64": @14, //@"iPad Simulator",

      @"iPhone1,1": @20,  // @"iPhone",
      @"iPhone1,2": @20,  // @"iPhone 3G",
      @"iPhone2,1": @20,  // @"iPhone 3GS",
      @"iPhone3,1": @16,  // @"iPhone 4",
      @"iPhone3,2": @16,  // @"iPhone 4(Rev A)",
      @"iPhone3,3": @16,  // @"iPhone 4(CDMA)",
      @"iPhone4,1": @15,  // @"iPhone 4S",
      @"iPhone5,1": @14,  // @"iPhone 5(GSM)",
      @"iPhone5,2": @14,  // @"iPhone 5(GSM+CDMA)",
      @"iPhone5,3": @10,  // @"iPhone 5c(GSM)",
      @"iPhone5,4": @10,  // @"iPhone 5c(GSM+CDMA)",
      @"iPhone6,1": @9,  // @"iPhone 5s(GSM)",
      @"iPhone6,2": @9,  // @"iPhone 5s(GSM+CDMA)",
      @"iPhone7,1": @9,  // @"iPhone 6+ (GSM+CDMA)",
      @"iPhone7,2": @9,  // @"iPhone 6 (GSM+CDMA)",

      @"iPad1,1":  @"iPad",
      @"iPad2,1":  @"iPad 2(WiFi)",
      @"iPad2,2":  @"iPad 2(GSM)",
      @"iPad2,3":  @"iPad 2(CDMA)",
      @"iPad2,4":  @"iPad 2(WiFi Rev A)",
      @"iPad2,5":  @"iPad Mini 1G (WiFi)",
      @"iPad2,6":  @"iPad Mini 1G (GSM)",
      @"iPad2,7":  @"iPad Mini 1G (GSM+CDMA)",
      @"iPad3,1":  @"iPad 3(WiFi)",
      @"iPad3,2":  @"iPad 3(GSM+CDMA)",
      @"iPad3,3":  @"iPad 3(GSM)",
      @"iPad3,4":  @"iPad 4(WiFi)",
      @"iPad3,5":  @"iPad 4(GSM)",
      @"iPad3,6":  @"iPad 4(GSM+CDMA)",

      @"iPad4,1":  @"iPad Air(WiFi)",
      @"iPad4,2":  @"iPad Air(GSM)",
      @"iPad4,3":  @"iPad Air(GSM+CDMA)",

      @"iPad4,4":  @"iPad Mini 2G (WiFi)",
      @"iPad4,5":  @"iPad Mini 2G (GSM)",
      @"iPad4,6":  @"iPad Mini 2G (GSM+CDMA)",

      @"iPod1,1":  @"iPod 1st Gen",
      @"iPod2,1":  @"iPod 2nd Gen",
      @"iPod3,1":  @"iPod 3rd Gen",
      @"iPod4,1":  @"iPod 4th Gen",
      @"iPod5,1":  @"iPod 5th Gen",

      };

    NSNumber *deviceName = commonNamesDictionary[machineName];

    if (deviceName == nil) {
        deviceName = @4.0;
    }

    return deviceName;
}


#pragma mark - UISearchBarDelegate

- (void)searchMessages:(NSString *)search_lower
{

    for (PFObject *message in self.messages)
    {
        if ([[[message valueForKey:PF_MESSAGES_DESCRIPTION] lowercaseString] containsString:search_lower]) {
            [self.searchMessages addObject:message];

        }
        else if (message[PF_MESSAGES_NICKNAME])
        {
            if ([[[message valueForKey:PF_MESSAGES_NICKNAME] lowercaseString]  containsString:search_lower]) [self.searchMessages addObject:message];
        }
    }

    [self.tableView reloadData];
}


-(IBAction)textFieldDidChange:(UITextField *)textField
{
    if ([textField.text length] > 0)
    {
        [_searchMessages removeAllObjects];
        _isSearching = YES;
        [self searchMessages:[textField.text lowercaseString]];
    }
    else {
        _isSearching = NO;
        [self.tableView reloadData];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    textField.text =@"";
    self.searchMessages = [NSMutableArray new];
    _isSearching = YES;
    _searchCloseButton.hidden = NO;
    //    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    //    [searchBar_ setShowsCancelButton:NO animated:YES];
    _isSearching = NO;
    _searchCloseButton.hidden = YES;
    [textField resignFirstResponder];
    textField.text = @"";
    [self.tableView reloadData];
}

-(IBAction)closeSearch:(id)sender {
    [_searchTextField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self searchBarCancelled];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar_
{
    [searchBar_ resignFirstResponder];
}

- (void)searchBarCancelled
{
    self.searchBar.text = @"Search...";
    [self.searchBar resignFirstResponder];
    [self.tableView reloadData];
}

@end
