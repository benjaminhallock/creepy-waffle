#import "ProgressHUD.h"
#import "utilities.h"
#import "ActionSheet.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface ActionSheet() <UITextFieldDelegate, UIActionSheetDelegate>
@property PFObject *room;
@property PFObject *message;
@property NSMutableDictionary *arrayOfNamesAndNumbers;
@property NSMutableArray *arrayOfNames;
@property UITextField *textField;
@end

@implementation ActionSheet

@synthesize textField, arrayOfNamesAndNumbers;

- (id)initWithRoom:(PFObject *)room AndMessage:(PFObject *)message
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self)
    {
        self.room = room;
        self.message = message;
    }
    return self;
}

- (void)didTap:(UITapGestureRecognizer *)tap
{
    [self saveNickname];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex)
    {
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Hide"])
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Hide this conversation?" message:@"Temporarily hide the conversation from your inbox until a new message appears?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Hide" , nil];
            alertView.tag = 32;
            [alertView show];
    }
        else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Flag"])
    {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Flag this conversation?" message:@"Do you want to flag this conversation and all it's users for objectionable content?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Flag" , nil];
                alertView.tag = 222;
                [alertView show];
    }
   else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Leave"])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Leaving the conversation will erase all your content in the conversation, and you will not see the conversation again." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Leave", nil];
        alert.tag = 23;
        [alert show];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Silence"] || [[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Un-Silence"])
    {
            [self actionSilencePush];
    }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{

    if (buttonIndex != alertView.cancelButtonIndex && alertView.tag == 23)
    {
        [self leaveChatroom];
    }

    if ([alertView.title isEqualToString:@"Contacts not enabled."] && buttonIndex != alertView.cancelButtonIndex)
    {
        //code for opening settings app in iOS 8
        [[UIApplication sharedApplication] openURL:[NSURL  URLWithString:UIApplicationOpenSettingsURLString]];
    }

    if (buttonIndex != alertView.cancelButtonIndex && alertView.tag == 222)
    {
    PFObject *chatroom = [self.message valueForKey:PF_MESSAGES_ROOM];
    [chatroom fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error)
        {
            if (!error)
            {
                [object incrementKey:PF_CHATROOMS_FLAGCOUNT];
                [object saveInBackground];
            }
        }];
        [ProgressHUD showSuccess:@"Flagged"];
    }

    if (buttonIndex != alertView.cancelButtonIndex && alertView.tag == 32)
    {
        //Hide
        [self.message setValue:@YES forKey:PF_MESSAGES_HIDE_UNTIL_NEXT];
        [self.message saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error)
            {
                [ProgressHUD showSuccess:@"Hidden"];
            }
            else NSLog(@"DeleteMessageItem delete error.");
        }];
    }

    if (buttonIndex != alertView.cancelButtonIndex && alertView.tag == 69)
    {
        PFObject *message = self.message;
        if ([alertView.title isEqualToString:@"Silence Push Notifications?"]) {
            [message removeObjectForKey:PF_MESSAGES_USER_DONOTDISTURB];
        } else {
            [message setValue:[PFUser currentUser] forKey:PF_MESSAGES_USER_DONOTDISTURB];
        }
        [message saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                [ProgressHUD showSuccess:@"Saved"];
            }
        }];
    }
}

-(void)hideChatroomAction
{

    UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
                                               otherButtonTitles:@"Hide", nil];
    action.tag = 1;
    [action showInView:self.view];
}

- (void)showActionSheetWithDelegate:(UIViewController *)view
{
    [self.message fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error) {
            if (!object[PF_MESSAGES_USER_DONOTDISTURB])
            {
                UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
                                                           otherButtonTitles:@"Un-Silence", @"Hide", @"Leave", @"Flag", nil];
                action.tag = 12;
                [action showInView:self.view];
            }
            else
            {
                UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
                                                           otherButtonTitles:@"Silence", @"Hide", @"Leave", @"Flag", nil];
                action.tag = 12;
                [action showInView:self.view];

            }
        } else [ProgressHUD showError:NETWORK_ERROR];
    }];
}

- (void)actionDimiss
{
    [self dismissViewControllerAnimated:1 completion:0];
   // [self.navigationController popToRootViewControllerAnimated:1];
}

- (void)viewDidDisappear:(BOOL)animated
{
    PostNotification(NOTIFICATION_DISABLESCROLLVIEW);
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(actionDimiss) name:NOTIFICATION_CLICKED_PUSH object:0];

    self.tableView.userInteractionEnabled = NO;
    self.arrayOfNames = [NSMutableArray new];

//    [self loadUsers];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    [self.view addGestureRecognizer:tap];

    UIBarButtonItem *close =  [[UIBarButtonItem alloc] initWithTitle:@"Close " style:UIBarButtonItemStyleBordered target:self action:@selector(actionDimiss)];

    close.image = [UIImage imageNamed:ASSETS_CLOSE];
    self.navigationItem.rightBarButtonItem = close;

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"More" style:UIBarButtonItemStyleDone target:self action:@selector(showActionSheet)];

    [self.tableView setRowHeight:66];
    self.tableView.separatorInset = UIEdgeInsetsZero;

    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 70)];
    view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 10, self.tableView.frame.size.width, 50)];
    UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];

    [textField setLeftViewMode:UITextFieldViewModeAlways];
    [textField setLeftView:spacerView];
    textField.placeholder = @"Personal Nickname";
    textField.delegate = self;
    textField.returnKeyType = UIReturnKeyDone;
    textField.inputAccessoryView = [UIView new];
    textField.backgroundColor = [UIColor whiteColor];

    if (self.message[PF_MESSAGES_NICKNAME])
    {
        textField.text = self.message[PF_MESSAGES_NICKNAME];
    }
    [view addSubview:textField];
    [self.tableView setTableHeaderView:view];
}

- (void) loadUsers
{
    PFRelation *userss = [self.room relationForKey:PF_CHATROOMS_USERS];
    PFQuery *query = [userss query];
    [query whereKey:@"objectId" notEqualTo:[PFUser currentUser].objectId];
    //Load cache here???
//  [query setCachePolicy:kPFCachePolicyCacheThenNetwork];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSMutableArray *array = [NSMutableArray arrayWithArray:objects];
            for (PFUser *user in array) {
                if (user.objectId != [PFUser currentUser].objectId) {
                    NSString *string = [user valueForKey:PF_USER_FULLNAME];
                    if (string.length && string && [[user valueForKey:PF_USER_ISVERIFIED] isEqualToNumber:@YES]) {
                        [self.arrayOfNames addObject:string];
                    } else {
                        [self.arrayOfNames addObject:[NSString stringWithFormat:@"%@* - pending",[user valueForKey:PF_USER_USERNAME]]];
                    }
                }
            }
            [self.tableView reloadData];
            [self getAllContacts];
            self.tableView.userInteractionEnabled = YES;
        }}];
}

- (void)loadUsers2
{
    NSArray *copyOfNames = [NSArray arrayWithArray:self.arrayOfNames];
    for (NSString *phoneNumber in copyOfNames) {
        if ([phoneNumber containsString:@"pending"]) {
            NSString *phoneNumber2 = [phoneNumber stringByReplacingOccurrencesOfString:@"* - pending" withString:@""];
            //Array of arrays
            for (NSArray *numbers in arrayOfNamesAndNumbers.allValues)
            {
                if ([numbers containsObject:phoneNumber2])
                {
                    NSArray *savedArray = numbers;
                    NSArray *names = [NSArray arrayWithArray:[arrayOfNamesAndNumbers allKeysForObject:savedArray]];
                    phoneNumber2 = [names.firstObject stringByAppendingString:@" - pending*"];

                    if (phoneNumber2.length)
                    {
                        [self.arrayOfNames removeObject:phoneNumber];
                        [self.arrayOfNames addObject:phoneNumber2];
                    }
                }
            }
        }
    }
    [self.tableView reloadData];
}

- (void) leaveChatroom
{
//Just delete my stuff, and get me out of here.
    [ProgressHUD show:@"Leaving..." Interaction:0];

    PFQuery *query = [PFQuery queryWithClassName:PF_CHAT_CLASS_NAME];
    [query whereKey:PF_CHAT_ROOM equalTo:_room];
    [query whereKey:PF_CHAT_USER equalTo:[PFUser currentUser]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
        if (!error)
        {
                for (PFObject *object in objects)
                {
                    [object deleteInBackground];
                }

                PFQuery *query2 = [PFQuery queryWithClassName:PF_MESSAGES_CLASS_NAME];
                [query2 whereKey:PF_CHAT_ROOM equalTo:_room];
                [query2 whereKey:PF_CHAT_USER equalTo:[PFUser currentUser]];

                [query2 findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
                 {
                    if (!error)
                    {
                        if (objects.count != 1) NSLog(@"DUPLICATE MESSAGE FOR SOME REASON");

                        for (PFObject *object in objects)
                        {
                            [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                            {
                                if (succeeded)
                                {
                                    //REMOVE USER FROM PFRELATION
                                    PFRelation *userss = [_room relationForKey:PF_CHATROOMS_USERS];
                                    [userss removeObject:[PFUser currentUser]];
                                    [[_room valueForKey:PF_CHATROOMS_USEROBJECTS] removeObject:[PFUser currentUser].objectId];

                                    [[userss query] countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
                                        if (!error) {
                                            if (number == 0) {

                                            [_room deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                                if (succeeded)
                                                {
                                                    PostNotification(NOTIFICATION_ENABLESCROLLVIEW);
                                                }
                                            }];

                                            }
                                            else
                                            {

                                                [_room saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                                if (succeeded) {
                                                    PostNotification(NOTIFICATION_ENABLESCROLLVIEW);
                                                }

                                                }];
                                            }
                                        }
                                    }];
                                    
                                    PostNotification(NOTIFICATION_LEAVE_CHATROOM);
                                    [ProgressHUD showSuccess:@"Deleted All Content"];
                                    //Refresh inbox, popchatview.
                                    [self actionDimiss];
                                }
                            }];
                        }
                    }}];
        } else {
            [ProgressHUD showError:NETWORK_ERROR];
        }
            }];
}

- (void) dismiss
{
    [self dismissViewControllerAnimated:1 completion:0];
//    [self.navigationController popViewControllerAnimated:1];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

#pragma mark - User actions

- (void)actionSilencePush
{
        [self.message fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!error)
            {
            if (!object[PF_MESSAGES_USER_DONOTDISTURB])
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Show Push Notifications?" message:nil delegate:self
                                                      cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil];
                alert.tag = 69;
                [alert show];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Silence Push Notifications?" message:nil delegate:self
                                                      cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil];
                alert.tag = 69;
                [alert show];

            }
            } else [ProgressHUD showError:NETWORK_ERROR];
        }];
}

#pragma mark - Table view data source
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self saveNickname];
    [tableView deselectRowAtIndexPath:indexPath animated:0];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    cell.textLabel.text = self.arrayOfNames[indexPath.row];
    cell.textLabel.textColor = [UIColor darkTextColor];
    cell.backgroundColor = [UIColor whiteColor];
    return cell;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.arrayOfNames.count;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self saveNickname];
    return YES;
}


- (void) saveNickname
{
    PFObject *message = self.message;
    if (textField.isFirstResponder) {
    if (textField.hasText) {
        [message setValue:textField.text forKey:PF_MESSAGES_NICKNAME];
    }else {
        [message removeObjectForKey:PF_MESSAGES_NICKNAME];
    }
    [message saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            PostNotification(NOTIFICATION_REFRESH_INBOX);
            [ProgressHUD showSuccess:@"Saved Nickname"];
            [textField resignFirstResponder];
        } else [ProgressHUD showError:NETWORK_ERROR];
    }];
    }
}


- (void)getAllContacts
{
    arrayOfNamesAndNumbers = [NSMutableDictionary new];

    NSLog(@"getAllContacts");
    CFErrorRef *error = nil;

    dispatch_queue_t abQueue = dispatch_queue_create("myabqueue", DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(abQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));



    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, error);
    __block BOOL accessGranted = NO;

    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {

        accessGranted = YES;

    } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {

        if (ABAddressBookRequestAccessWithCompletion != NULL) { // we're on iOS 6
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                accessGranted = granted;

                dispatch_semaphore_signal(sema);
            });
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        }
        else { // we're on iOS 5 or older
            accessGranted = YES;
        }
    }

    if (!accessGranted) {
        NSLog(@"Cannot fetch Contacts :( ");

        dispatch_async(dispatch_get_main_queue(), ^{

            if([[[UIDevice currentDevice] systemVersion] floatValue]<8.0)
            {
                UIAlertView* curr1=[[UIAlertView alloc] initWithTitle:@"Contacts not enabled." message:@"Settings -> Snap Ben -> Contacts" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [curr1 show];
            }
            else
            {
                UIAlertView* curr2=[[UIAlertView alloc] initWithTitle:@"Contacts not enabled." message:@"Settings -> Snap Ben -> Contacts" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Settings", nil];
                curr2.tag=121;
                [curr2 show];
            }
        });
    } else {
        NSLog(@"Fetching contact info ----> ");


        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, error);
        ABRecordRef source = ABAddressBookCopyDefaultSource(addressBook);
        CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBook, source, kABPersonSortByFirstName);
        CFIndex nPeople = ABAddressBookGetPersonCount(addressBook);
        nPeople = CFArrayGetCount(allPeople);
     //   NSMutableArray* items = [NSMutableArray arrayWithCapacity:nPeople];

        //START ITERATING THROUGH PEOPLE
        //GRAB PHONE NUMBERS, CHECK FOR USERS, THEN GRAB NAMES FOR NON-USER NUMBER, ONLY ONE NAME PER MULT-PHONENUMBER;

        for (int i = 0; i < nPeople; i++) {
            ABRecordRef person = CFArrayGetValueAtIndex(allPeople, i);
            NSString *firstname = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonFirstNameProperty));
            NSString *lastname = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonLastNameProperty));

            NSString *name = [NSString new];

            if (!firstname) {
                name = lastname;
            } else if (!lastname) {
                name = firstname;
            } else {
                name = [NSString stringWithFormat:@"%@ %@", firstname, lastname];
            }

            //COMBINE NAME KEY WITH PHONE NUMBER OBJECTS IN DICTIONARY.

            ABMultiValueRef multiPhones = ABRecordCopyValue(person, kABPersonPhoneProperty);
            // CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(multiPhones, 0);
            //  phoneNumberRef = ABMultiValueCopyValueAtIndex(multiPhones, ABMultiValueGetIndexForIdentifier(multiPhones, 0));

            NSMutableArray *theirPhoneNumbers = [NSMutableArray new];

            for(CFIndex i=0;i<ABMultiValueGetCount(multiPhones);i++)
            {
                CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(multiPhones, i);

                NSString *phoneNumber = (__bridge NSString *) phoneNumberRef;

                phoneNumber = [[phoneNumber componentsSeparatedByCharactersInSet:
                                [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                               componentsJoinedByString:@""];

                if (phoneNumber.length == 10)
                {
                    phoneNumber = formatPhoneNumberForCountry(phoneNumber);
                }

                if (![phoneNumber hasPrefix:@"+"])
                {
                    phoneNumber = [@"+" stringByAppendingString:phoneNumber];
                }

                if (phoneNumber.length) {
                    [theirPhoneNumbers addObject:(NSString *)phoneNumber];
                }
            }

            if (name.length && theirPhoneNumbers.count) {
                NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSArray arrayWithArray:theirPhoneNumbers] forKey:name];
                [arrayOfNamesAndNumbers addEntriesFromDictionary:dict];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadUsers2];
        });
    }
}


@end
