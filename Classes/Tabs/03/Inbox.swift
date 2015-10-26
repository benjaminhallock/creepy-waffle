////
////  MessagesView.swift
////  Snap Ben
////
////  Created by benjaminhallock@gmail.com on 9/15/15.
////  Copyright (c) 2015 KZ. All rights reserved.
//
//import Foundation
//import UIKit
//
//class Inbox: UIViewController, UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate
//{
//    var  messages = NSMutableArray()
//    var messagesObjectIds = NSMutableArray()
//    var scrollView = UIScrollView()
//    var isSelectingChatroomForPhotos = false
//    var didViewJustLoad = false
//    var longPress = UILongPressGestureRecognizer()
//
//
//    var savedDates = NSMutableArray()
//    var savedMessagesForDate = NSMutableDictionary()
//
//    var albumToDelete = PFObject()
//    var messageToRenameDelete = PFObject()
//
//    var isLoadingMessages = true
//    var isSearching = false
//    var indexForDelete = NSIndexPath()
//
//    var tap = UITapGestureRecognizer()
//
//    @IBOutlet var labelfalseMessages: UILabel?
//    @IBOutlet var viewHeader : UIView?
//    @IBOutlet var searchTextField : UITextField?
//    @IBOutlet var searchCloseButton : UIButton?
//
//    var searchMessages = NSMutableArray()
//    var refreshControl = UIRefreshControl()
//
//    @IBOutlet var tableView : UITableView?
//
////    @IBOutlet var viewEmpty : UIView?
//
//    var x  = 0
//
////--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//
//    override func viewDidLoad ()
//    {
//        super.viewDidLoad()
//
//        IQKeyboardManager.sharedManager().enableAutoToolbar = false
//
//        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Edit", style: UIBarButtonItemStyle.Bordered, target: self, action: "didPressEdit")
//        
////        self.viewEmpty.hidden = true;
//        self.didViewJustLoad = true;
//        self.navigationItem.title = "SnapBen";
//
//        longPress = UILongPressGestureRecognizer(target: self, action: "longPress")
//
//        self.view.addGestureRecognizer(longPress)
//    }
//
//
//    @IBAction func didSelectCompose()
//    {
//    let chat = CreateChatroomView()
//    chat.isTherePicturesToSend = false;
//    self.hidesBottomBarWhenPushed = true;
//    self.navigationController?.pushViewController(chat, animated: true)
//    self.hidesBottomBarWhenPushed = false;
//    }
//
//    func openChatfalsetification(notification:NSNotification)
//    {
//        let dict : NSDictionary = notification.userInfo!
//        let chat = dict["view"] as! ChatView
//        openView(chat)
//    }
//
//    func openView(view2: UIViewController)
//    {
//        if ((self.navigationController?.viewControllers.last?.isKindOfClass(ChatView)) != nil)
//    {
//        self.navigationController?.popViewControllerAnimated(false)
//    }
//    /// IF CUSTOM CHAT ROOM IS SAME AS ROOM BEFORE, POP THE STACK ONCE.
//    self.hidesBottomBarWhenPushed = true
//    self.navigationController?.pushViewController(view2, animated: true)
//    self.hidesBottomBarWhenPushed = false
//    }
//
//    func longPress(press :UILongPressGestureRecognizer)
//    {
//        let point = press.locationInView(self.tableView)
//
//        let cell = tableView?.cellForRowAtIndexPath((tableView?.indexPathForRowAtPoint(point))!)
//
//    if (cell != nil)
//    {
//        tableView?.setEditing(true, animated: true)
//        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: "didPressEdit")
//
//    tap = UITapGestureRecognizer(target: self, action: "didTap")
//    self.tableView?.addGestureRecognizer(tap)
//    }
//    }
//
//    func didTap(tapped: UITapGestureRecognizer)
//    {
//       let point : CGPoint = tapped.locationInView(tableView)
//
//        if (point.x > 50)
//        {
//            tableView?.setEditing(false, animated: true)
//            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Edit", style: .Bordered, target: self, action: "didPressEdit")
//            self.tableView?.removeGestureRecognizer(tap)
//        }
//    }
//
//    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
//    //This is called ALWAYS because of longPress??
//        let point = touch.locationInView(self.view)
//
//    if (self.tableView!.editing)
//    {
//    if (point.x < 50)
//    {
//    //Let the button work
//    return false;
//    } else {
//    return true;
//    }
//    } else {
//    return false;
//    }
//    }
//
//    func reloadDataTableView()
//    {
//        tableView?.reloadData()
//    }
//
//    func viewDidLoad()
//    {
//    super.viewDidLoad()
//
//    IQKeyboardManager.sharedManager().enableAutoToolbar = false;
//
//        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Edit", style: .Bordered, target: self, action: "didPressEdit")
//
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshMessages", name: NOTIFICATION_USER_LOGGED_OUT, object: nil)
//
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshMessages", name: NOTIFICATION_USER_LOGGED_IN, object: nil)
//
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshMessages", name: NOTIFICATION_REFRESH_INBOX, object: nil)
//
//
//    self.viewEmpty.hidden = true;
//    self.didViewJustLoad = true;
//    self.navigationItem.title = @"Snap Ben";
//
//    tableView?.backgroundColor = UIColor.whiteColor()
//
//    self.longPress = UILongPressGestureRecognizer(target: self, action: "longPress")
//    view.addGestureRecognizer(longPress)
//
//    self.searchCloseButton.hidden = true;
//    clearAll()
//    setupRefreshControl()
//    setUpNavBar()
//
//    let spacerView = UIView(frame:CGRectMake(0, 0, 10, 10)
//    [_searchTextField setLeftViewMode:UITextFieldViewModeAlways];
//    [_searchTextField setLeftView:spacerView];
//
//    [self.tableView registerNib:[UINib nibWithNibName:@"MessagesCell" bundle:0] forCellReuseIdentifier:@"MessagesCell"];
//
//    [[NSfalsetificationCenter defaultCenter] addObserver:self selector:@selector(reloadDataTableView) name:falseTIFICATION_RELOAD_INBOX object:0];
//
//    [[NSfalsetificationCenter defaultCenter] addObserver:self selector:@selector(openChatfalsetification:) name:falseTIFICATION_OPEN_CHAT_VIEW object:0];
//
//        refreshMessages()
//    }
//
//    - (void)viewWillAppear:(BOOL)animated
//    {
//    [super viewWillAppear:animated];
//
//    //Needed to scroll tableview to hide searchbar.
//    self.edgesForExtendedLayout = UIRectEdgefalsene;
//
//    //Deleted && !_isArchive
//    if (self.navigationController.visibleViewController == self)
//    {
//    self.scrollView.scrollEnabled = true;
//    }
//    else
//    {
//    self.scrollView.scrollEnabled = false;
//    }
//
//    if (self.didViewJustLoad) [self.searchTextField resignFirstResponder];
//    }
//
//    - (void)viewDidAppear:(BOOL)animated
//    {
//    [super viewDidAppear:animated];
//    [self.tableView reloadData];
//    [self updateEmptyView];
//    self.didViewJustLoad = false;
//    }
//
//    - (void) clearAll
//    {
//    self.messages = [[NSMutableArray alloc] init];
//    self.savedDates = [NSMutableArray new];
//    self.savedMessagesForDate = [NSMutableDictionary new];
//    self.messagesObjectIds = [NSMutableArray new];
//    }
//
//    -(void)viewWillDisappear:(BOOL)animated
//    {
//    self.scrollView.scrollEnabled = false;
//    }
//
//    - (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
//    {
//    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 2, self.view.frame.size.width, 22)];
//    label.textColor = [UIColor lightGrayColor];
//
//    label.textAlignment = NSTextAlignmentLeft;
//
//    label.layer.shadowOffset = CGSizeMake(0, 0);
//    label.layer.shadowColor = [UIColor lightGrayColor].CGColor;
//    label.layer.shadowRadius = 1.0;
//    label.layer.shadowOpacity = 0.4;
//
//    label.font = [UIFont fontWithName:@"Helvetica Bold" size:15];
//    //    label.backgroundColor = [UIColor colorWithRed:239/255.0f green:239/255.0f blue:244/255.0f alpha:1];
//    label.backgroundColor = [UIColor whiteColor];
//
//    if (self.savedDates.count)
//    {
//    NSDate *date = [self.savedDates objectAtIndex:section];
//    NSDateFormatter *dateFormate = [[NSDateFormatter alloc] init];
//    [dateFormate setDateFormat:@"MMMM dd"];
//    NSString *dateString = [dateFormate stringFromDate:date];
//    dateString = [@"  " stringByAppendingString:dateString];
//    if ([date isEqualToDate:[self dateAtBeginningOfDayForDate:[NSDate date]]]) {
//    label.text = @"   Today";
//    } else {
//    label.text = [@"  " stringByAppendingString:dateString];
//    }
//    }
//    return label;
//    }
//
//    #pragma mark - Backend methods
//
//    //Grab all messages with MY NAME ON IT.
//    - (void)loadInbox
//    {
//    if ([PFUser currentUser] && _isLoadingMessages == false)
//    {
//    NSLog(@"LOADING INBOX");
//
//    _isLoadingMessages = true;
//
//    PFQuery *query = [PFQuery queryWithClassName:PF_MESSAGES_CLASS_NAME];
//
//    [query whereKey:PF_MESSAGES_USER equalTo:[PFUser currentUser]];
//    //      [query includeKey:PF_MESSAGES_LASTUSER];
//    [query includeKey:PF_MESSAGES_ROOM];
//    [query includeKey:PF_MESSAGES_USER];
//    [query includeKey:PF_MESSAGES_LASTPICTURE];
//    [query includeKey:PF_MESSAGES_LASTPICTUREUSER];
//    [query whereKey:PF_MESSAGES_HIDE_UNTIL_NEXT equalTo:@false];
//
//    //      PFObject *message = messages.lastObject;
//    //    if (message) [query whereKey:PF_MESSAGES_UPDATEDACTION greaterThan:message.updatedAt];
//
//    //Clear the cache if there is a delete.
//    //        [query clearCachedResult];
//
//    [query orderByDescending:PF_MESSAGES_UPDATEDACTION];
//
//    [query setCachePolicy:kPFCachePolicyCacheThenNetwork];
//
//    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
//    {
//    if (!error)
//    {
//    [self clearAll];
//
//    for (PFObject *message in objects)
//    {
//    if (![self.messagesObjectIds containsObject:message.objectId])
//    {
//    [self.messages addObject:message];
//    NSDate *date = [message valueForKey:PF_MESSAGES_UPDATEDACTION];
//    date = [self dateAtBeginningOfDayForDate:date];
//
//    if (![self.savedDates containsObject:date])
//    {
//    [self.savedDates addObject:date];
//    NSMutableArray *array = [NSMutableArray arrayWithObject:message];
//    NSDictionary *dict = [NSDictionary dictionaryWithObject:array forKey:date];
//    [self.savedMessagesForDate addEntriesFromDictionary:dict];
//    }
//    else
//    {
//    [(NSMutableArray *)[self.savedMessagesForDate objectForKey:date] addObject:message];
//    }
//    }
//    }
//
//    [self.tableView reloadData];
//    _isLoadingMessages = false;
//    //Scroll search bar up a falsetch.
//    [self updateEmptyView];
//    }
//    else
//    {
//    if ([query hasCachedResult]) {
//    if (self.navigationController.visibleViewController == self) {
//    NSLog(@"%@", error.userInfo);
//    [self.refreshControl endRefreshing];
//    [ProgressHUD showError:NETWORK_ERROR];
//    }
//    }
//    }
//    [_refreshControl endRefreshing];
//    }];
//    }
//    }
//
//    - (NSDate *)dateAtBeginningOfDayForDate:(NSDate *)inputDate
//    {
//    //Convert to my time zone
//    NSTimeZone *tz = [NSTimeZone defaultTimeZone];
//    NSInteger seconds = [tz secondsFromGMTForDate:inputDate];
//    NSDate *date = [NSDate dateWithTimeInterval: seconds sinceDate:inputDate];
//    // Use the user's current calendar and time zone
//    NSCalendar *calendar = [NSCalendar currentCalendar];
//    NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
//    [calendar setTimeZone:timeZone];
//
//    // Selectively convert the date components (year, month, day) of the input date
//    NSDateComponents *dateComps = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:date];
//
//    // Set the time components manually
//    [dateComps setHour:0];
//    [dateComps setMinute:0];
//    [dateComps setSecond:0];
//    // Convert back
//    NSDate *beginningOfDay = [calendar dateFromComponents:dateComps];
//    return beginningOfDay;
//    }
//
//    -(void)actionSettings
//    {
//    NavigationController *nav = [[NavigationController alloc] initWithRootViewController: [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped]];
//
//    [self showDetailViewController:nav sender:self];
//    }
//
//    -(void)setUpNavBar
//    {
//    self.view.backgroundColor = [UIColor whiteColor];
//    self.tableView.backgroundColor = [UIColor clearColor];
//
//    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(didSelectCompose:)];
//    self.navigationItem.rightBarButtonItem = item;
//
//    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStyleDone target:self action:0];
//    }
//
//
//    -(void)actionFavorties:(UIBarButtonItem *)button
//    {
//    [self.scrollView setContentOffset:CGPointMake(self.view.frame.size.width * 2, 0) animated:1];
//    }
//
//    - (IBAction)actionBack:(UIBarButtonItem *)button
//    {
//    [self.scrollView setContentOffset:CGPointMake(0, 0) animated:true];
//    }
//
//    - (IBAction)actionSettings:(UIButton *)button
//    {
//    [UIView animateWithDuration:.3 animations:^{
//    button.transform = CGAffineTransformMakeScale(0.3,0.3);
//    button.transform = CGAffineTransformMakeScale(1,1);
//    }];
//    }
//
//    - (void) changeBackgroundColor
//    {
//    UIColor *randomColor = [[UIColor arrayOfColorsCore] objectAtIndex:arc4random_uniform((int)[UIColor arrayOfColorsCore].count)];
//    [UIView animateWithDuration:.3 animations:^{
//    self.view.backgroundColor = randomColor;
//    }];
//    }
//
//    //REFRESH CONTROL
//    - (void)refreshMessages
//    {
//    if ([[[PFUser currentUser] valueForKey:PF_USER_ISVERIFIED] isEqualToNumber:@true])
//    {
//    [self.tabBarController setSelectedIndex:0];
//    [self loadInbox];
//    }
//    else
//    {
//    MasterLoginRegisterView *login = [MasterLoginRegisterView new];
//    [self.tabBarController showDetailViewController:login sender:self];
//    //        [self.scrollView setContentOffset:CGPointMake(self.view.frame.size.width, 0) animated:1];
//    [self actionCleanup];
//    }
//    }
//
//    #pragma mark - Helper methods
//
//    //IF false MESSAGES, SHOW VIEW.
//    - (void)updateEmptyView
//    {
//    self.viewEmpty.hidden = (self.messages.count > 0) ? true: false;
//
//    if (!self.viewEmpty.isHidden)
//    {
//    self.tableView.separatorColor = [UIColor clearColor];
//    }
//    else
//    {
//    if (self.messages.count > 5)
//    {
//    self.tableView.tableHeaderView = self.viewHeader;
//    }
//
//    self.tableView.separatorColor = [UIColor colorWithRed:.8f green:.8f blue:.8f alpha:.9f];
//}
//}
//
//#pragma mark - User actions
//
////PART OF CAMERA BUTTON.
//- (IBAction)buttonRelease:(UIButton*)button {
//    // Do something else
//    [UIView animateWithDuration:.3f animations:^{
//        button.transform = CGAffineTransformMakeScale(3,3);
//        }];
//    }
//
//    //WHEN YOU LOGOUT AND STUFF.
//    - (void)actionCleanup
//        {
//            [self.messages removeAllObjects];
//            [self.messagesObjectIds removeAllObjects];
//            [self.savedDates removeAllObjects];
//            [self.savedMessagesForDate removeAllObjects];
//            //Clear the cache of videos.
//            [self.tableView reloadData];
//}
//
//#pragma mark - Table view data source
//
//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
//    if (_isSearching) {
//        return 1;
//    }
//    return self.savedDates.count;
//    }
//
//    - (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//    if (_isSearching)
//    {
//        return _searchMessages.count;
//    }
//    else
//    {
//        NSDate *dateRepresentingThisDay = [self.savedDates objectAtIndex:section];
//        NSArray *eventsOnThisDay = [self.savedMessagesForDate objectForKey:dateRepresentingThisDay];
//        return [eventsOnThisDay count];
//    }
//}
//
//-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return 90;
//    }
//
//    - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    MessagesCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MessagesCell" forIndexPath:indexPath];
//
//    if (!cell) cell = [[MessagesCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MessagesCell"];
//
//    [cell format];
//
//    cell.labelInitials.hidden = true;
//
//    if (self.savedDates.count)
//    {
//        PFObject *message;
//
//        if (_isSearching && _searchMessages.count)
//        {
//            message = [_searchMessages objectAtIndex:indexPath.row];
//        }
//        else
//        {
//            NSDate *dateRepresentingThisDay = [self.savedDates objectAtIndex:indexPath.section];
//            NSArray *eventsOnThisDay = [self.savedMessagesForDate objectForKey:dateRepresentingThisDay];
//            message = [eventsOnThisDay objectAtIndex:indexPath.row];
//        }
//
//        PFObject *pictureObject = [message valueForKey:PF_MESSAGES_LASTPICTURE];
//        if (pictureObject)
//        {
//            PFUser *user = [message valueForKey:PF_MESSAGES_LASTPICTUREUSER];
//            NSString *name = [user valueForKey:PF_USER_FULLNAME];
//
//            if (name && name.length)
//            {
//                NSMutableArray *array = [NSMutableArray arrayWithArray:[name componentsSeparatedByString:@" "]];
//                [array removeObject:@" "];
//                NSString *first = array.firstObject;
//                NSString *last = array.lastObject;
//                if (first.length && last.length) {
//                    first = [first stringByPaddingToLength:1 withString:name startingAtIndex:0];
//                    last = [last stringByPaddingToLength:1 withString:name startingAtIndex:0];
//                    name = [first stringByAppendingString:last];
//                    cell.labelInitials.text = name;
//                    cell.labelInitials.hidden = false;
//                }
//            }
//
//            PFFile *file = [pictureObject valueForKey:PF_PICTURES_THUMBNAIL];
//            cell.imageUser.file = file;
//            [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
//                if (!error) {
//                cell.imageUser.image = [UIImage imageWithData:data];
//                }
//                }];
//        }
//        else
//        {
//            cell.imageUser.image = [UIImage imageNamed:@"Blank V"];
//        }
//
//        UIColor *selectedColor = [UIColor benFamousGreen];
//        cell.imageUser.layer.borderColor = selectedColor.CGColor;
//        cell.tableBackgroundColor = selectedColor;
//
//        [cell bindData:message];
//    }
//    return cell;
//    }
//
//    - (UIColor *)convertColorStringToColorWorkAround:(NSString *)string
//{
//    NSArray * colorParts = [string componentsSeparatedByString: @" "];
//    CGFloat red = [[colorParts objectAtIndex:0] floatValue];
//    CGFloat green = [[colorParts objectAtIndex:1] floatValue];
//    CGFloat blue = [[colorParts objectAtIndex:2] floatValue];
//    CGFloat alpha = [[colorParts objectAtIndex:3] floatValue];
//
//    UIColor * newColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
//
//    return newColor;
//    }
//
//    - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return true;
//    //Required for edit actions
//}
//
//-(void)didPressEdit
//    {
//        if (self.tableView.isEditing)
//        {
//            [self.tableView setEditing:0 animated:1];
//            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(didPressEdit)];
//        }
//        else
//        {
//            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(didPressEdit)];
//            [self.tableView setEditing:1 animated:1];
//            //        tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
//            //        tap.delegate = self;
//            //        [self.tableView addGestureRecognizer:tap];
//        }
//}
//
//-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    UITableViewRowAction *button =
//
//        [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Hide" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
//    {
//        [self.tableView setEditing:0 animated:1];
//
//        NSDate *dateRepresentingThisDay = [self.savedDates objectAtIndex:indexPath.section];
//        NSMutableArray *eventsOnThisDay = [self.savedMessagesForDate objectForKey:dateRepresentingThisDay];
//
//        [PFQuery clearAllCachedResults];
//
//        PFObject  *message = [eventsOnThisDay objectAtIndex:indexPath.row];
//        [message setValue:@true forKey:PF_MESSAGES_HIDE_UNTIL_NEXT];
//        [message saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//        if (!error) {
//        //Remove all traces of messages
//        [[self.savedMessagesForDate objectForKey:dateRepresentingThisDay] removeObject:message];
//        [self.messagesObjectIds removeObject:message.objectId];
//        [self.messages removeObject:message];
//
//        //Animation
//        [self.tableView beginUpdates];
//        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
//        [self.tableView endUpdates];
//
//        [self.tableView reloadData];
//        //
//        [self updateEmptyView];
//        }
//        else NSLog(@"DeleteMessageItem delete error.");
//        }];
//    }];
//
//    button.backgroundColor = [UIColor redColor]; //arbitrary color
//
//    UITableViewRowAction *button2 = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Rename" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
//
//    [self.tableView setEditing:0 animated:1];
//
//    NSDate *dateRepresentingThisDay = [self.savedDates objectAtIndex:indexPath.section];
//    NSArray *eventsOnThisDay = [self.savedMessagesForDate objectForKey:dateRepresentingThisDay];
//    self.messageToRenameDelete = [eventsOnThisDay objectAtIndex:indexPath.row];
//
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Rename..." message:0 delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Rename", nil];
//
//    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
//
//    if (self.messageToRenameDelete[PF_MESSAGES_NICKNAME])
//    {
//    [alert textFieldAtIndex:0].text = [self.messageToRenameDelete valueForKey:PF_ALBUMS_NICKNAME];
//    }
//
//    [alert show];
//    }];
//
//    button2.backgroundColor = [UIColor colorWithRed:.75f green:.75f blue:.75f alpha:1]; //arbitrary color
//
//    return @[button, button2]; //array with all the buttons you want. 1,2,3, etc...
//}
//
//#pragma mark - ALERTVIEW
//
//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//
//    if (buttonIndex != alertView.cancelButtonIndex && [alertView.title isEqualToString:@"New Album"] && [alertView textFieldAtIndex:0].hasText)
//    {
//        PFObject *album = [PFObject objectWithClassName:PF_ALBUMS_CLASS_NAME];
//        [album setValue:[[alertView textFieldAtIndex:0].text capitalizedString] forKey:PF_ALBUMS_NICKNAME];
//        [album setValue:[PFUser currentUser] forKey:PF_ALBUMS_USER];
//
//        [album saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
//            {
//            if (succeeded)
//            {
//            [self.messages insertObject:album atIndex:0];
//            [self.messagesObjectIds insertObject:album atIndex:0];
//
//            NSIndexPath *indexpath = [NSIndexPath indexPathForRow:0 inSection:0];
//            [self.tableView insertRowsAtIndexPaths:@[indexpath] withRowAnimation:UITableViewRowAnimationAutomatic];
//
//            //Clear the favorites cache.
//            PFQuery *query = [PFQuery queryWithClassName:PF_ALBUMS_CLASS_NAME];
//            [query clearCachedResult];
//
//            [self updateEmptyView];
//            [self.tableView setEditing:0 animated:1];
//            }
//            else
//            {
//            NSLog(@"Save Album Error %@", error.userInfo);
//            }
//            }];
//    }
//
//    if ([alertView.title isEqualToString:@"Delete Album"] && buttonIndex != alertView.cancelButtonIndex)
//    {
//        __block NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.messages indexOfObject:self.albumToDelete] inSection:0];
//
//        [self.messages removeObject:self.albumToDelete];
//
//        //        This will ensure it does falset come back from the dead.
//        //        [messagesObjectIds removeObject:albumToDelete.objectId];
//
//        [self.albumToDelete deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//            if (succeeded)
//            {
//            [self.tableView setEditing:0 animated:1];
//
//            //Delete all the favorites in the album
//            PFQuery *query = [PFQuery queryWithClassName:PF_FAVORITES_CLASS_NAME];
//            [query whereKey:PF_FAVORITES_ALBUM equalTo:self.albumToDelete];
//            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
//            if (!error) {
//            [PFObject deleteAllInBackground:objects];
//            }
//            }];
//
//            PFQuery *query2 = [PFQuery queryWithClassName:PF_ALBUMS_CLASS_NAME];
//            [query2 clearCachedResult];
//
//            [self.tableView beginUpdates];
//            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
//            [self.tableView endUpdates];
//
//            [self updateEmptyView];
//            } else {
//            NSLog(@"Delete album Error %@", error.userInfo);
//            }
//            }];
//
//    }
//    else if ([alertView.title isEqualToString:@"Rename..."] && buttonIndex != alertView.cancelButtonIndex)
//    {
//
//        if ([alertView textFieldAtIndex:0].hasText) {
//
//            NSString *string = [alertView textFieldAtIndex:0].text;
//
//            if (string.length) {
//                [self.messageToRenameDelete setValue:[alertView textFieldAtIndex:0].text forKey:PF_MESSAGES_NICKNAME];
//            } else {
//                [self.messageToRenameDelete setValue:@"" forKey:PF_MESSAGES_NICKNAME];
//            }
//
//            [self.messageToRenameDelete saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//                if (succeeded)
//                {
//                [self.tableView setEditing:0 animated:1];
//                [self.tableView reloadData];
//                }
//                else
//                {
//                NSLog(@"Rename Error %@", error.userInfo);
//                }
//                }];
//        }
//        else
//        {
//            [ProgressHUD showError:@"Cancelled"];
//            NSLog(@"canceled rename");
//            [alertView dismissWithClickedButtonIndex:0 animated:1];
//        }
//    }
//}
//
//#pragma mark - Table view delegate
//
//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    [tableView deselectRowAtIndexPath:indexPath animated:1];
//
//    MessagesCell *cell = [tableView cellForRowAtIndexPath:indexPath];
//
//    PFObject *message;
//    if (_isSearching && _searchMessages.count)
//    {
//        message = [_searchMessages objectAtIndex:indexPath.row];
//    }
//    else
//    {
//        if (self.savedDates.count)
//        {
//            NSDate *dateRepresentingThisDay = [self.savedDates objectAtIndex:indexPath.section];
//            NSArray *eventsOnThisDay = [self.savedMessagesForDate objectForKey:dateRepresentingThisDay];
//            message = [eventsOnThisDay objectAtIndex:indexPath.row];
//        }
//    }
//
//    if (message)
//    {
//        PFObject *room = [message objectForKey:PF_MESSAGES_ROOM];
//        ChatView *chatView = [[ChatView alloc] initWith:room
//            name:cell.labelDescription.text];
//        chatView.message = message;
//
//        chatView.title = cell.labelDescription.text;
//
//        self.hidesBottomBarWhenPushed = true;
//        [self.navigationController pushViewController:chatView animated:true];
//        self.hidesBottomBarWhenPushed = false;
//    }
//    }
//
//    - (void)setupRefreshControl
//        {
//            // Programmatically inserting a UIRefreshControl
//            self.refreshControl = [[UIRefreshControl alloc] init];
//
//            // Setup the loading view, which will hold the moving graphics
//            self.refreshLoadingView = [[UIView alloc] initWithFrame:self.refreshControl.bounds];
//            self.refreshLoadingView.backgroundColor = [UIColor clearColor];
//
//            // Setup the color view, which will display the rainbowed background
//            self.refreshColorView = [[UIView alloc] initWithFrame:self.refreshControl.bounds];
//            self.refreshColorView.backgroundColor = [UIColor clearColor];
//            self.refreshColorView.alpha = .8;
//
//            // Create the graphic image views
//            self.compassBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:ASSETS_NEW_SETTINGS]];
//            self.compassSpinner = [[UIImageView alloc] initWithImage:[UIImage imageNamed:ASSETS_NEW_SETTINGS]];
//
//            // Add the graphics to the loading view
//            [self.refreshLoadingView addSubview:self.compassBackground];
//            [self.refreshLoadingView addSubview:self.compassSpinner];
//
//            // Clip so the graphics don't stick out
//            self.refreshLoadingView.clipsToBounds = true;
//
//            // Hide the original spinner icon
//            //    self.refreshControl.tintColor = [UIColor clearColor];
//
//            // Add the loading and colors views to our refresh control
//            //    [self.refreshControl addSubview:self.refreshColorView];
//            //    [self.refreshControl addSubview:self.refreshLoadingView];
//
//            // Initalize flags
//            self.isRefreshIconsOverlap = false;
//            self.isRefreshAnimating = false;
//
//            // When activated, invoke our refresh function
//            [self.refreshControl addTarget:self action:@selector(refreshMessages) forControlEvents:UIControlEventValueChanged];
//            [self.tableView addSubview:_refreshControl];
//}
//
//-(void)viewDidDisappear:(BOOL)animated
//{
//    [super viewDidDisappear:animated];
//    [self.tableView setEditing:0 animated:1];
//}
//
//#pragma mark - UISearchBarDelegate
//
//- (void)searchMessages:(NSString *)search_lower
//{
//
//    for (PFObject *message in self.messages)
//    {
//        if ([[[message valueForKey:PF_MESSAGES_DESCRIPTION] lowercaseString] containsString:search_lower]) {
//            [self.searchMessages addObject:message];
//
//        }
//        else if (message[PF_MESSAGES_NICKNAME])
//        {
//            if ([[[message valueForKey:PF_MESSAGES_NICKNAME] lowercaseString]  containsString:search_lower]) [self.searchMessages addObject:message];
//        }
//    }
//
//    [self.tableView reloadData];
//}
//
//-(IBAction)textFieldDidChange:(UITextField *)textField
//{
//    if ([textField.text length] > 0)
//    {
//        [_searchMessages removeAllObjects];
//        _isSearching = true;
//        [self searchMessages:[textField.text lowercaseString]];
//    }
//    else {
//        _isSearching = false;
//        [self.tableView reloadData];
//    }
//    }
//
//    - (void)textFieldDidBeginEditing:(UITextField *)textField
//{
//    textField.text =@"";
//    self.searchMessages = [NSMutableArray new];
//    _isSearching = true;
//    _searchCloseButton.hidden = false;
//    //    [searchBar setShowsCancelButton:true animated:true];
//    }
//
//    - (void)textFieldDidEndEditing:(UITextField *)textField
//{
//    //    [searchBar_ setShowsCancelButton:false animated:true];
//    _isSearching = false;
//    _searchCloseButton.hidden = true;
//    [textField resignFirstResponder];
//    textField.text = @"";
//    [self.tableView reloadData];
//}
//
//-(IBAction)closeSearch:(id)sender {
//    [_searchTextField resignFirstResponder];
//    }
//    
//    - (BOOL)textFieldShouldReturn:(UITextField *)textField
//{
//    [textField resignFirstResponder];
//    return true;
//}
//
//@end
//
//
//
//}