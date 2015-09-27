
#import "ProgressHUD.h"
#import "AppConstant.h"
#import "messages.h"
#import "utilities.h"

#import "CreateChatroomView.h"
#import "CreateChatroomView2.h"
#import "ChatView.h"
#import "NavigationController.h"

//#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface CreateChatroomView () <CreateChatroom2Delegate>
{
    NSMutableArray *users;
    NSMutableArray *usersObjectIds;
    NSMutableDictionary *lettersForWords;
    NSArray *sortedKeys;
    UITextField *labelForContactsIndicator;
    int x;
    NSString *peopleWaiting;
}

@property (strong, nonatomic) IBOutlet UIView *viewHeader;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UITextField *searchTextField;
@property (strong, nonatomic) IBOutlet UIButton *searchCloseButton;

@property NSMutableArray *searchMessages;

@property (strong, nonatomic) NSMutableArray *arrayOfSelectedUsers;
@property (strong, nonatomic) NSMutableArray *arrayofSelectedPhoneNumbers;

@property UITapGestureRecognizer *tap;
@property NSMutableArray *numbers;
@property UITableViewCell *selectedCell;
@property BOOL isSearching;
@property (strong, nonatomic)  NSMutableDictionary *arrayOfNamesAndNumbers;
@property (strong, nonatomic) IBOutlet UIButton *buttonSend;
@property BOOL isNotGoingBack;
@end

@implementation CreateChatroomView

@synthesize delegate, arrayOfNamesAndNumbers, numbers, viewHeader, searchBar, tap;

//You just hit send in the contacts view.
- (void)sendBackArrayOfPhoneNumbers:(NSMutableArray *)array andDidPressSend:(BOOL)send andText:(NSString *)text
{
    _arrayofSelectedPhoneNumbers = array;
    if (send) {
        [self sendWithTextMessage];
    }
}

- (IBAction)didPressSendButton:(UIButton *)sender
{
    self.buttonSend.userInteractionEnabled = false;
    [self sendWithTextMessage];
    self.buttonSend.userInteractionEnabled = true;
}

- (void)actionContacts
{
    CreateChatroomView2 *contacts = [[CreateChatroomView2 alloc] init];
    contacts.delegate = self;
    _isNotGoingBack = YES;
    contacts.isTherePicturesToSend = _isTherePicturesToSend;
    contacts.arrayofSelectedPhoneNumbers = _arrayofSelectedPhoneNumbers;
    contacts.arrayOfNamesAndNumbers = arrayOfNamesAndNumbers;
    self.hidesBottomBarWhenPushed = YES;
    NavigationController *nav = [[NavigationController alloc] initWithRootViewController:contacts];
    [self presentViewController:nav animated:1 completion:0];

//    [self.navigationController pushViewController:contacts animated:1];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"%f", [UIScreen mainScreen].bounds.size.height);
    NSLog(@"%f %f", self.view.frame.size.height, self.view.frame.size.width);
    [self togglePhoneNumbersCountIndicator];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self closeSearch:0];

    if (!_isNotGoingBack && !_isTherePicturesToSend)
    {
        [self setNavigationBarColor];
    }
    else
    {
        _isNotGoingBack = NO;
    }

    [self togglePhoneNumbersCountIndicator];
}

- (void)viewDidLoad
{
#warning FETCHING CONTACTS
    [self getAllContacts];

    NSLog(@"%f", [UIScreen mainScreen].bounds.size.height);
    NSLog(@"%f %f", self.view.frame.size.height, self.view.frame.size.width);

    int size = 25;
    CGRect one = CGRectMake(self.view.frame.size.width - size, self.view.frame.size.height + size, size * 4, size * 4);
    CGRect two = CGRectMake(-70, self.view.frame.size.height - 10, self.view.frame.size.width, 70);
//    self.buttonSend = [[UIButton alloc] initWithFrame:one];
    self.buttonSend.layer.cornerRadius = size * 4/2;
    self.buttonSend.layer.borderColor = [UIColor benFamousGreen].CGColor;
    self.buttonSend.layer.borderWidth = 2;
    [self.buttonSend setImage:[UIImage imageNamed:ASSETS_NEW_PEOPLE] forState:UIControlStateNormal];
    [self.buttonSend addTarget:self action:@selector(actionContacts) forControlEvents:UIControlEventTouchUpInside];
    self.buttonSend.imageView.tintColor = [UIColor benFamousGreen];
    self.buttonSend.titleLabel.text = @"SEND";
    self.buttonSend.titleLabel.textColor = [UIColor whiteColor];
    self.buttonSend.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.buttonSend.backgroundColor  = [UIColor benFamousGreen];
    self.buttonSend.hidden = false;
    [self.view addSubview:self.buttonSend];

    self.tableView.sectionIndexColor = [UIColor lightGrayColor];

    [self.navigationController.navigationBar setTintColor:[UIColor benFamousGreen]];
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithWhite:.98 alpha:1]];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:1];

    self.navigationController.navigationBar.titleTextAttributes =  @{
                                                                     NSForegroundColorAttributeName: [UIColor benFamousGreen],
                                                                     NSFontAttributeName: [UIFont fontWithName:@"Helvetica Neue" size:20.0f],
                                                                     NSShadowAttributeName:[NSShadow new]
                                                                     };

    [super viewDidLoad];
    [self.tableView setRowHeight:55];
    _searchCloseButton.hidden = YES;

    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleDone target:self action:@selector(didPressSendButton:)];
    self.navigationItem.rightBarButtonItem = item;

    UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    [_searchTextField setLeftViewMode:UITextFieldViewModeAlways];
    [_searchTextField setLeftView:spacerView];

    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView.backgroundColor = [UIColor whiteColor];

    self.title = @"New Conversation";
    self.tableView.tableHeaderView = viewHeader;

    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                   initWithTitle: @"Back"
                                   style: UIBarButtonItemStyleBordered
                                   target: nil action: nil];
    [self.navigationItem setBackBarButtonItem: backButton];

    self.searchBar.placeholder = @"Search...";

    users = [[NSMutableArray alloc] init];
    usersObjectIds = [NSMutableArray new];
    _searchMessages = [NSMutableArray new];
    self.arrayOfSelectedUsers = [NSMutableArray new];
    _arrayofSelectedPhoneNumbers = [NSMutableArray new];
    [_arrayOfSelectedUsers addObject:[PFUser currentUser]];

    tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(didTap:)];
    tap.delegate = self;
}


- (void) didTap:(UITapGestureRecognizer *)tap
{

}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    if ([textView.text containsString:@"\n"]) {
        [textView resignFirstResponder];
        [textView deleteBackward];
        [textView scrollsToTop];
        [self.view removeGestureRecognizer:tap];
    } else {
        [self searchUsers:textView.text];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [[UIApplication sharedApplication] setStatusBarHidden:0 withAnimation:UIStatusBarAnimationSlide];
    [self.view removeGestureRecognizer:tap];
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    [self.view addGestureRecognizer:tap];
    return YES;
}

- (void) preSendCheck
{
    if (_arrayofSelectedPhoneNumbers.count > 0)
    {
        x = (int)_arrayofSelectedPhoneNumbers.count;

        //Looking for users in chatroom that already exist, so we don't make any new users.
        PFQuery *query = [PFUser query];
        [query whereKey:@"isVerified" equalTo:@NO];
        [query whereKey:PF_USER_USERNAME containedIn:_arrayofSelectedPhoneNumbers];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {

                NSMutableArray *arrayOfNumbersCopy = [NSMutableArray arrayWithArray:_arrayofSelectedPhoneNumbers];

                // If users were found, add them to selectedUsers;
                for (PFUser *user in objects)
                {
                    NSString *phoneNumber = [user valueForKey:PF_USER_USERNAME];
                    [arrayOfNumbersCopy removeObject:phoneNumber];
                    [_arrayOfSelectedUsers addObject:user];
                    x--;
                    //If all the users were found with phonenumbers, we can send. Otherwise create more phone numbers;
                    if (x == 0) {
                        [self actionSend];
                        return;
                    }
                }

                //For the rest of the phone numbers, create an account.
                for (NSString *phoneNumber in arrayOfNumbersCopy) {
                    [self saveNewUserWithPhoneNumber:phoneNumber];
                }
            } else {
                NSLog(@"findUserswith# %@", error.userInfo);
            }
        }];

    } else {// No phone numbers

        [self actionSend];
    }
}

- (void) saveNewUserWithPhoneNumber:(NSString *)phoneNumber
{
    //    NSURL *url = [NSURL URLWithString: [NSString stringWithFormat:@"http://%@:%@@https://api.parse.com/1/users", @"", @""]];
    NSURL *url = [NSURL URLWithString:@"https://api.parse.com/1/users"];
#warning WHAT DOES THIS STRING LOOK LIKE.
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"8pudwEbafadgRNuy7DOBKBb2ObVH1dUzDZ8SuRtQ" forHTTPHeaderField:@"X-Parse-REST-API-Key"];
    [request setValue:@"elq3rKjkGscvsbeeb21QP0GkuMfuEe3Zb8f3bvcq" forHTTPHeaderField:@"X-Parse-Application-Id"];

    NSDictionary *dict = @{@"username":phoneNumber,@"password":phoneNumber, PF_USER_ISVERIFIED: @NO};
    NSError *error;
    NSData *postBody = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];

    NSLog(@"error: %@",error);
    [request setHTTPBody:postBody];

    // Send request to Parse and parse returned data
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (!connectionError) {
                                   NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];


                                   NSString *objectId = [responseDictionary valueForKey:@"objectId"];

                                   [_arrayOfSelectedUsers addObject:[PFUser objectWithoutDataWithObjectId:objectId]];
                                   x--;
                                   //If we finished all the phone numbers, create the chatroom;
                                   if (x == 0){
                                       [self actionSend];
                                   }

                               } else {
                                   NSLog(@"NewUserSave %@", connectionError.userInfo);
                               }
                           }];
}

-(void) setNavigationBarColor
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

- (void)sendWithTextMessage
{
    //Includes current user already.
    if (_arrayOfSelectedUsers.count < 2)
    {
        [ProgressHUD showError:@"One Registered User Required"];
        self.buttonSend.userInteractionEnabled = NO;
        return;
    }
    else if (_arrayofSelectedPhoneNumbers.count == 0)
    {
        //No phone numbers
        [self actionSend];
        return;
    }

    //Sending Text if phone numbers selected
    peopleWaiting = @"";

    for (PFUser *user in _arrayOfSelectedUsers)
    {
        if (user != [PFUser currentUser])
        {
            NSString *userName = [user valueForKey:PF_USER_FULLNAME];
            if (userName.length && userName)
            {
                peopleWaiting = [peopleWaiting stringByAppendingString:userName];
                peopleWaiting = [peopleWaiting stringByAppendingString:@", "];
            }
        }
    }

    if (peopleWaiting.length > 2)
    {
        peopleWaiting = [peopleWaiting substringToIndex:peopleWaiting.length - 2];
        peopleWaiting = [NSString stringWithFormat:@"%@ and I are waiting for you On Snap Ben!!!!!", peopleWaiting];
    }


    if (_isTherePicturesToSend)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_APP_MAIL_SEND object:self userInfo:@{@"string": peopleWaiting, @"people": _arrayofSelectedPhoneNumbers}];
    }

    [self preSendCheck];
}

- (void)actionSend
{
    if (_arrayOfSelectedUsers.count > 0)
    {
        //Create chatroom object
        if (_isTherePicturesToSend)
        {
        [ProgressHUD show:@"Sending..." Interaction:0];
        }

        //New Chatroom
        PFObject *chatroom = [PFObject objectWithClassName:PF_CHATROOMS_CLASS_NAME];
        PFRelation *usersInRelation = [chatroom relationForKey:PF_CHATROOMS_USERS];
        NSMutableArray *arrayOfUserIds = [NSMutableArray new];

        //Create list of names in chatroom.
       __block NSString *stringOfNames = @"";
       __block NSString *stringWithoutUser = @"";
        __block int count = (int)_arrayOfSelectedUsers.count;

        for (PFUser *user  in _arrayOfSelectedUsers)
        {
#warning MAY BE TOO SLOW WITHOUT BLOCK
        [user fetchInBackgroundWithBlock:^(PFObject *object, NSError *error)
            {
            if (!error)
            {
                if (object == [PFUser currentUser])
                {
                    [usersInRelation addObject:[PFUser currentUser]];
                    [arrayOfUserIds addObject:[PFUser currentUser].objectId];
                }
                else
                {
                    [usersInRelation addObject:object];
                    [arrayOfUserIds addObject:object.objectId];
                }

            NSString *fullName = [user objectForKey:PF_USER_FULLNAME];
            NSString *phoneNumber = [user valueForKey:PF_USER_USERNAME];

            if (fullName.length && fullName)
            {
                stringOfNames = [stringOfNames stringByAppendingString:[NSString stringWithFormat:@"%@, ", fullName]];

                if (object != [PFUser currentUser])
                {
                    stringWithoutUser = [stringWithoutUser stringByAppendingString:[NSString stringWithFormat:@"%@, ", fullName]];
                }
            }
            else
            {
                stringOfNames = [stringOfNames stringByAppendingString:[NSString stringWithFormat:@"%@, ", phoneNumber]];

                if (object != [PFUser currentUser])
                {
                    stringWithoutUser = [@"*" stringByAppendingString:stringWithoutUser];
                }
            }
                count--;
                if (count == 0)
                {
                    if (stringOfNames.length > 2 && stringWithoutUser.length > 2)
                    {
                        stringOfNames = [stringOfNames substringToIndex:stringOfNames.length - 2];
                        stringWithoutUser = [stringWithoutUser substringToIndex:stringWithoutUser.length - 2];
                    }

                    [chatroom setValue:stringOfNames forKey:PF_CHATROOMS_NAME];

                    [chatroom setValue:arrayOfUserIds forKey:PF_CHATROOMS_USEROBJECTS];

                    [chatroom setValue:@(0) forKey:PF_CHATROOMS_ROOMNUMBER];

                    //NEXT
                    [self findChatroomAndSend:chatroom andUserIds:arrayOfUserIds andString:stringWithoutUser];
                    NSLog(@"COUNT DOWN DONE");
                }
        }
        else
        {
            NSLog(@"Error fetching users: %@", error.userInfo);
        }
        }];

        }//end for loop

}}


//AFTER ACTIONSEND
- (void)findChatroomAndSend:(PFObject *)chatroom andUserIds:(NSArray *)arrayOfUserIds andString:(NSString *)stringWithoutUser
{
    PFQuery *query2 = [PFQuery queryWithClassName:PF_CHATROOMS_CLASS_NAME];


    [query2 whereKey:PF_CHATROOMS_USEROBJECTS containsAllObjectsInArray:arrayOfUserIds];
    
#warning IF YOU LEAVE A CHATROOM, YOUR NAME IS NO LONGER ON THAT LIST, SO A NEW CHATROOM WITH THE SAME PEOPLE WILL BE FRESH.

    [query2 findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (!error)
         {
             if (objects.count > 0)
             {
                 //Because all the people could be contained in the array, but there could be more, we must check if the array is identical, i don't believe order matters in this case.
                 // FOUND CHATROOM
                 for (PFObject *chatroommm in objects)
                 {
                     NSArray *arrayOfIds = [chatroommm objectForKey:PF_CHATROOMS_USEROBJECTS];

#warning CURRENT USER IS NOT CONTAINED IN ARRAYOFUSERIDS, BUT AFTERWARDS IT SAVES FINE

                     //Since arrays are ordered, we use this helper method to check the un-ordered comparison of the array.
                     if ([self isSameValues:arrayOfIds and:arrayOfUserIds])
                     {
                         //FOUND A IDENTICAL CHATROOM
                         [chatroom deleteInBackground];//NEEDED?

#warning UNHIDE ALL MESSAGES RELATED TO THIS CHATROOM
                         if (_isTherePicturesToSend)
                         {
#warning DELETE THIS EVENTUALLY
                             [delegate sendObjectsWithSelectedChatroom:chatroommm andText:stringWithoutUser andComment:0];
                         }
                         else
                         {
                             [self actionSaveAndOpen:chatroommm andText:stringWithoutUser andComment:0];
                             //Find message and open it.
                         }
                         return;
                         break;
                     }
                 }

                 //Chat didn't exist, even with the extra people checker above.
                 [chatroom saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                  {
                     if (succeeded && !error)
                     {
                         //Create message so each user gets an alert.
                         if (_isTherePicturesToSend)
                         {
                             CreateMessageItem(chatroom, _arrayOfSelectedUsers);
                             [delegate sendObjectsWithSelectedChatroom:chatroom andText:stringWithoutUser andComment:@"1"];
                         }
                         else
                         {
                             CreateMessageItem(chatroom, _arrayOfSelectedUsers);
                             [self actionSaveAndOpen:chatroom andText:stringWithoutUser andComment:0];
                             //                                Open new chatroom.
                         }
                     }
                 }];

             }
             else if (objects.count == 0)
             {

                 //No chatroom contained all those Users listed, creating such chatroom.
                 [chatroom saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                     if (succeeded && !error) {
                         //Create message so each user gets an alert.
                         if (_isTherePicturesToSend)
                         {
                             CreateMessageItem(chatroom, _arrayOfSelectedUsers);
                             [delegate sendObjectsWithSelectedChatroom:chatroom andText:stringWithoutUser andComment:@"1"];
                         }
                         else
                         {
                             CreateMessageItem(chatroom, _arrayOfSelectedUsers);
                             [self actionSaveAndOpen:chatroom andText:stringWithoutUser andComment:0];
                         }
                     }}];
             }
         } else {
             NSLog(@"%@", error.userInfo);
             [ProgressHUD showError:NETWORK_ERROR];
         }
     }];
}

- (BOOL)isSameValues:(NSArray*)array1 and:(NSArray*)array2
{
    NSCountedSet *set1 = [NSCountedSet setWithArray:array1];
    NSCountedSet *set2 = [NSCountedSet setWithArray:array2];
    return [set1 isEqualToSet:set2];
}

- (IBAction)actionSaveAndOpen:(PFObject *)chatroom  andText:(NSString *)text andComment:(NSString *)comment
{
    //Save the photos, dismiss the view, open the chatview, slideRight in background, refresh when all is saved and done.x
    if (chatroom)
    {
        [self openChatroomWithRoom:chatroom title:text comment:0];
        PostNotification(NOTIFICATION_REFRESH_INBOX);
    }
    else
    {
        self.buttonSend.userInteractionEnabled = YES;
        [ProgressHUD showError:@"No Chatroom Selected"];
    }
}

- (void) openChatroomWithRoom:(PFObject *)chatroom title:(NSString *)title comment:(NSString *)comment
{
    [ProgressHUD dismiss];
    ChatView *chatView = [[ChatView alloc] initWith:chatroom name:title];
    if (_arrayofSelectedPhoneNumbers.count) chatView.isSendingTextMessage = YES;
    chatView.message = nil;
    PostNotification(NOTIFICATION_REFRESH_INBOX);
    [self setNavigationBarColor];

    [self.navigationController popViewControllerAnimated:0];

    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_OPEN_CHAT_VIEW object:chatView userInfo:@{@"view": chatView}];

    self.buttonSend.userInteractionEnabled = YES;

    if (!_isTherePicturesToSend && self.arrayofSelectedPhoneNumbers.count)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_APP_MAIL_SEND object:self userInfo:@{@"string": peopleWaiting, @"people": _arrayofSelectedPhoneNumbers}];
    }
}


#pragma mark - Backend methods

- (void)loadUsers
{
#warning PPL WITH SAME NAME ON ben GET MASHED TOGETHER.
#warning COULD REMOVE MULTIPLE PEOPLE WHO HAVE SAME PHONE NUMBER;
    PFQuery *query = [PFUser query];
    [query whereKey:PF_USER_OBJECTID notEqualTo:[PFUser currentUser].objectId];
    [query orderByAscending:PF_USER_FULLNAME];
    //Including the ben Team by default
    [numbers addObject:@"0000000000"];
    [query whereKey:PF_USER_USERNAME containedIn:numbers];
    [query whereKey:PF_USER_ISVERIFIED equalTo:@YES];
    [query setCachePolicy:kPFCachePolicyCacheThenNetwork];
    [query setMaxCacheAge:1];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (error == nil)
         {
             for (PFUser *user in objects)
             {
                 NSString *phoneNumber = [user objectForKey:PF_USER_USERNAME];
                 if (phoneNumber.length == 0) phoneNumber = nil;
                 if ([numbers containsObject:phoneNumber])
                 {
                     if (![usersObjectIds containsObject:user.objectId])
                     {
                         [users addObject:user];
                         [usersObjectIds addObject:user.objectId];

                         for (NSArray *arrayNumbers in arrayOfNamesAndNumbers.allValues)
                         {
                             if ([arrayNumbers containsObject:phoneNumber])
                             {
                                 [arrayOfNamesAndNumbers removeObjectsForKeys: [arrayOfNamesAndNumbers allKeysForObject:arrayNumbers]];
                             }
                         }
                     }
                 }
             }//END FOR LOOP
             [self wordsFromLetters:users];
         }
         else {
             if ([query hasCachedResult]) [ProgressHUD showError:NETWORK_ERROR];
         }
     }];
}

- (void)updateEmptyView
{
    if (users.count == 0) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 200, self.view.frame.size.width, 70)];
        [label setNumberOfLines:2];
        label.text = @"No Contacts Registered with SnapBen, \n Invite some!";
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor lightGrayColor];
        [self.view addSubview:label];
    } else {
        for (UILabel *label in self.view.subviews) {
            if ([label isKindOfClass:[UILabel class]]) {
                [label removeFromSuperview];
            }
        }
    }
}


#pragma mark - Table view data source

- (void) wordsFromLetters:(NSArray *)words
{
    NSMutableArray *arrayOfUsedLetters = [NSMutableArray new];
    lettersForWords = [NSMutableDictionary new];

    NSMutableDictionary *namesToUsers = [NSMutableDictionary new];

    for (PFUser *user in users)
    {
        NSDictionary *dict = [NSDictionary dictionaryWithObject:user forKey:[user valueForKey:PF_USER_FULLNAME]];
        [namesToUsers addEntriesFromDictionary:dict];
    }

    NSString *letters = @"abcdefghijklmnopqrstuvwxyz";

    int i = 0;
    while (i < (int)namesToUsers.count)
    {
        NSString *word = [namesToUsers.allKeys objectAtIndex:i];
        PFUser *user = [namesToUsers objectForKey:word];
        NSString *letter = [[word substringToIndex:1] uppercaseString];

        if (![letters containsString:[letter lowercaseString]]) {
            letter = @"#";
        }
        if ([arrayOfUsedLetters containsObject:letter])
        {
            [(NSMutableArray *)[lettersForWords objectForKey:letter] addObject:user];
        }
        else
        {
            NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSMutableArray arrayWithObject:user] forKey:letter];
            [lettersForWords addEntriesFromDictionary:dict];
            [arrayOfUsedLetters addObject:letter];
        }
        i++;
    }

    sortedKeys = [[lettersForWords allKeys] sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];

    [self updateEmptyView];
    [self.tableView reloadData];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (_isSearching) return nil;
//    return sortedKeys;
        return @[@"#",@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z"];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    if (_isSearching) return 0;
    return [sortedKeys indexOfObject:title];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_isSearching) return 1;
    return sortedKeys.count;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (_isSearching) return @"Searching...";
    return [@"  " stringByAppendingString:[sortedKeys objectAtIndex:section]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section

{
    if (_isSearching)
    {
        return _searchMessages.count;
    } else {
        NSString *key = [sortedKeys objectAtIndex:section];
        NSArray *array = [lettersForWords objectForKey:key];
        return array.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];


    PFUser *selectedUser;

    if (_isSearching && _searchMessages.count)
    {
        selectedUser = _searchMessages[indexPath.row];

    }
    else
    {
        //Get letter
        NSString *key = [sortedKeys objectAtIndex:indexPath.section];
//      Get names for letter
        NSArray *arrayOfNamesForLetter = [lettersForWords objectForKey:key];

        if (arrayOfNamesForLetter.count) {
            selectedUser = arrayOfNamesForLetter[indexPath.row];
        }
    }

    cell.textLabel.text = selectedUser[PF_USER_FULLNAME];

    if ([_arrayOfSelectedUsers containsObject:selectedUser])
    {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        imageView.tintColor = [UIColor benFamousOrange];
        cell.accessoryView = imageView;
        cell.accessoryView.tintColor = [UIColor benFamousOrange];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryView = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    cell.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:.95f];
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.font = [UIFont systemFontOfSize:18];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    PFUser *selectedUser;
    if (_isSearching && _searchMessages.count)
    {
        selectedUser = [_searchMessages objectAtIndex:indexPath.row];
    }
    else
    {
        NSString *key = [sortedKeys objectAtIndex:indexPath.section];
        NSArray *arrayOfNamesForLetter = [lettersForWords objectForKey:key];
        if (arrayOfNamesForLetter.count)
        {
            selectedUser = arrayOfNamesForLetter[indexPath.row];
            NSLog(@"%@", [selectedUser valueForKey:PF_USER_FULLNAME]);
        }
    }

    if (cell.accessoryView == nil && cell.accessoryType == UITableViewCellAccessoryNone)
    {
        if (_arrayOfSelectedUsers.count > 100) [ProgressHUD showError:@"100 People Only"];
        else
        {
            [self.arrayOfSelectedUsers addObject:selectedUser];
            [self togglePhoneNumbersCountIndicator];
            UIImage *image = [[UIImage imageNamed:@"checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            imageView.tintColor = [UIColor benFamousGreen];
            cell.accessoryView.tintColor = [UIColor benFamousGreen];
            cell.accessoryView = imageView;
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    else
    {
        [self.arrayOfSelectedUsers removeObject:selectedUser];
        cell.accessoryView = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

- (void)togglePhoneNumbersCountIndicator
{
    [labelForContactsIndicator removeFromSuperview];

    if (_arrayofSelectedPhoneNumbers.count && !self.buttonSend.isHidden)
    {
        labelForContactsIndicator = [[UITextField alloc] initWithFrame:CGRectMake(0, (self.view.frame.size.height - 106), self.tableView.frame.size.width, 44)];

        NSString *string = [NSString stringWithFormat:@"✚ %lu contacts invited", (unsigned long)_arrayofSelectedPhoneNumbers.count];

        labelForContactsIndicator.userInteractionEnabled = NO;
        labelForContactsIndicator.textColor = [UIColor whiteColor];
        labelForContactsIndicator.font = [UIFont boldSystemFontOfSize:16];
        labelForContactsIndicator.text = string;

        UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        [labelForContactsIndicator setLeftViewMode:UITextFieldViewModeAlways];
        [labelForContactsIndicator setLeftView:spacerView];
        labelForContactsIndicator.backgroundColor = [UIColor benFamousGreen];
        labelForContactsIndicator.textColor = [UIColor whiteColor];
        [self.view addSubview:labelForContactsIndicator];
    }
}

#pragma mark -SEARCH

- (void)searchUsers:(NSString *)search_lower
{
    for (PFUser *user in users)
    {
        if ([[[user valueForKey:PF_USER_FULLNAME] lowercaseString] containsString:search_lower])
        {
            [self.searchMessages addObject:user];
        }
    }
    [self.tableView reloadData];
}

- (IBAction)textFieldDidChange:(UITextField *)textField
{
    if ([textField.text length] > 0)
    {
        [_searchMessages removeAllObjects];
        _isSearching = YES;
        [self searchUsers:[textField.text lowercaseString]];
    } else {
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
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    _isSearching = NO;
    _searchCloseButton.hidden = YES;
    [textField resignFirstResponder];
    textField.text = @"";
    [self.tableView reloadData];
}

- (IBAction)closeSearch:(id)sender
{
    [_searchTextField resignFirstResponder];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:@"Multiple Unknown Phone Numbers"])
    {
        NSString *phoneNumber = [alertView buttonTitleAtIndex:buttonIndex];
        if (phoneNumber.length && _selectedCell.accessoryType == UITableViewCellAccessoryNone)
        {
            _selectedCell.accessoryView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"email"]];
            _selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
            [_arrayofSelectedPhoneNumbers addObject:phoneNumber];
        }
    }

    if (alertView.tag ==  25)
    {
        //code for opening settings app in iOS 8
        [self.navigationController popToRootViewControllerAnimated:1];
        if (buttonIndex != alertView.cancelButtonIndex) {
        [[UIApplication sharedApplication] openURL:[NSURL  URLWithString:UIApplicationOpenSettingsURLString]];
        }
    }
}

- (void)getAllContacts
{
    numbers = [NSMutableArray new];
    arrayOfNamesAndNumbers = [NSMutableDictionary new];

    NSString *currentUserName = [PFUser currentUser].username;

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
                curr1.tag = 25;
                [curr1 show];
            }
            else
            {
                UIAlertView* curr2=[[UIAlertView alloc] initWithTitle:@"Contacts not enabled." message:@"Settings -> Snap Ben -> Contacts" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Settings", nil];
                curr2.tag= 25;
                [curr2 show];
            }
        });
    } else {
        NSLog(@"Fetching contact info ----> ");


        __strong ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, error);
        ABRecordRef source = ABAddressBookCopyDefaultSource(addressBook);
        CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBook, source, kABPersonSortByFirstName);
        CFIndex nPeople = ABAddressBookGetPersonCount(addressBook);
        nPeople = CFArrayGetCount(allPeople);
        //        NSMutableArray* items = [NSMutableArray arrayWithCapacity:nPeople];

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

            for(CFIndex i=0; i<ABMultiValueGetCount(multiPhones); i++)
            {
                CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(multiPhones, i);
                NSString *phoneNumber = (__bridge NSString *) phoneNumberRef;


                phoneNumber = [[phoneNumber componentsSeparatedByCharactersInSet:
                                [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                               componentsJoinedByString:@""];

                if (phoneNumber.length == 10)
                {
                    phoneNumber = [AppConstant formatPhoneNumberForCountry:phoneNumber];
                }

                if (![phoneNumber hasPrefix:@"+"])
                {
                    phoneNumber = [@"+" stringByAppendingString:phoneNumber];
                }

                if (phoneNumber.length > 0)
                {
                    [theirPhoneNumbers addObject:(NSString *)phoneNumber];
                    [numbers addObject:phoneNumber];
                }
            }

            if ([theirPhoneNumbers containsObject:currentUserName])
            {
                //Prevent current user???
            } else {
                if (name.length && theirPhoneNumbers.count)
                {
                    NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSArray arrayWithArray:theirPhoneNumbers] forKey:name];
                    [arrayOfNamesAndNumbers addEntriesFromDictionary:dict];
                }
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadUsers];
        });
    }
}


-(void)messagesInputToolbar:(JSQMessagesInputToolbar *)toolbar didPressLeftBarButton:(UIButton *)sender {}

@end
