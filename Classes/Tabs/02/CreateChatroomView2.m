#import <Parse/Parse.h>

#import "ProgressHUD.h"

#import "AppConstant.h"

#import "messages.h"

#import "utilities.h"

#import "AppDelegate.h"

#import "CreateChatroomView2.h"

#import "ChatView.h"

#import <AddressBook/AddressBook.h>

#import <AddressBookUI/AddressBookUI.h>

@interface CreateChatroomView2 ()
{
    NSMutableArray *usersObjectIds;
    NSArray *sortedKeys;
    NSMutableDictionary *lettersForWords;
    int x;
}

@property (strong, nonatomic) NSMutableArray *usersNot;

@property (strong, nonatomic) IBOutlet JSQMessagesInputToolbar *toolbar;

@property (strong, nonatomic) IBOutlet UIView *viewHeader;

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;

@property (strong, nonatomic) IBOutlet UITextField *searchTextField;

@property (strong, nonatomic) IBOutlet UIButton *searchCloseButton;

@property NSMutableArray *searchMessagesNot;

@property (strong, nonatomic) NSMutableArray *arrayOfSelectedUsers;

@property UITapGestureRecognizer *tap;

@property NSMutableArray *numbers;

@property UITableViewCell *selectedCell;

@property BOOL isSearching;

@property BOOL didPressSend;

@end

@implementation CreateChatroomView2

@synthesize delegate, arrayOfNamesAndNumbers, numbers, usersNot;

@synthesize viewHeader, searchBar, toolbar, tap;

-(void)messagesInputToolbar:(JSQMessagesInputToolbar *)toolbar didPressLeftBarButton:(UIButton *)sender
{
}

- (void)messagesInputToolbar:(JSQMessagesInputToolbar *)toolbar didPressRightBarButton:(UIButton *)sender
{
    [self.view endEditing:1];
    _didPressSend = YES;
    self.toolbar.contentView.rightBarButtonItem.enabled = 0;
    [delegate sendBackArrayOfPhoneNumbers:_arrayofSelectedPhoneNumbers andDidPressSend:YES andText:self.toolbar.contentView.textView.text];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self closeSearch:0];
    if (_didPressSend == NO)
    {
    [delegate sendBackArrayOfPhoneNumbers:_arrayofSelectedPhoneNumbers andDidPressSend:0 andText:self.toolbar.contentView.textView.text];
    }
}

- (void)viewDidLoad
{
    self.tableView.sectionIndexColor = [UIColor lightGrayColor];

    [super viewDidLoad];
    [self.tableView setRowHeight:55];

    NSLog(@"%@ BACON", _arrayofSelectedPhoneNumbers);

    _searchCloseButton.hidden = YES;
    
    self.toolbar.contentView.rightBarButtonItem.enabled = 0;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.view.backgroundColor = [UIColor whiteColor];

    self.toolbar.contentView.textView.scrollEnabled = 0;

    UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    [_searchTextField setLeftViewMode:UITextFieldViewModeAlways];
    [_searchTextField setLeftView:spacerView];

    self.toolbar.contentView.textView.delegate = self;
    self.toolbar.contentView.textView.text = self.textForComment;


    self.toolbar.contentView.textView.placeHolder = @"Comment...";
    self.toolbar.contentView.textView.inputAccessoryView = [UIView new];
    self.searchBar.placeholder = @"Search...";


    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    self.toolbar.contentView.leftBarButtonItem = button;
    
    tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(didTap:)];
    tap.delegate = self;

    self.title = @"Invite Contacts";
    self.tableView.tableHeaderView = viewHeader;

    usersNot = [NSMutableArray new];
    usersObjectIds = [NSMutableArray new];
    _searchMessagesNot = [NSMutableArray new];
    self.arrayOfSelectedUsers = [NSMutableArray new];
    [_arrayOfSelectedUsers addObject:[PFUser currentUser]];

    [self loadUsers];
}


- (void) didTap:(UITapGestureRecognizer *)tap
{
    NSLog(@"Tap");
    if (self.toolbar.contentView.textView.isFirstResponder){
        [self.toolbar.contentView.textView resignFirstResponder];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    if ([textView.text containsString:@"\n"]) {
        [textView deleteBackward];
        [textView resignFirstResponder];
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

-(BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    [self.view addGestureRecognizer:tap];
    return YES;
}

#pragma mark - Backend methods

- (void)loadUsers
{
    usersNot = [NSMutableArray arrayWithArray:[arrayOfNamesAndNumbers.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];

    [self wordsFromLetters:0];
}

- (void)searchUsers:(NSString *)search_lower
{
    for (NSString *name in usersNot) {
        if ([[name lowercaseString] containsString:[search_lower lowercaseString]]) {
            [_searchMessagesNot addObject:name];
        }
    }
    [_tableView reloadData];
}

#pragma mark - Table view data source

- (void) wordsFromLetters:(NSArray *)words
{
    NSString *letters = @"abcdefghijklmnopqrstuvwxyz";

    NSMutableArray *arrayOfUsedLetters = [NSMutableArray new];
    lettersForWords = [NSMutableDictionary new];

    int i = 0;
    while (i < (int)usersNot.count)
    {
        NSString *word = [usersNot objectAtIndex:i];
        NSString *letter = [[word substringToIndex:1] uppercaseString];

        if (![letters containsString:[letter lowercaseString]]) {
            letter = @"#";
        }

        if ([arrayOfUsedLetters containsObject:letter])
        {
            [(NSMutableArray *)[lettersForWords objectForKey:letter] addObject:word];
        }
        else
        {
            NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSMutableArray arrayWithObject:word] forKey:letter];
            [lettersForWords addEntriesFromDictionary:dict];
            [arrayOfUsedLetters addObject:letter];
        }
        i++;
    }
    sortedKeys = [[lettersForWords allKeys] sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];

    [self.tableView reloadData];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (_isSearching) return nil;
//    return sortedKeys;
    //What seciton titles are availabe on the right
            return @[@"#",@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z"];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    //What section do I scroll to when i hit this title.
    if (_isSearching) return 0;
    return [sortedKeys indexOfObject:title];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_isSearching)
    {
        return 1;
    }
    else
    {
        return lettersForWords.allKeys.count;
    }
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
        return _searchMessagesNot.count;
    }
    else
    {
        NSString *key = [sortedKeys objectAtIndex:section];
        NSArray *arrayOfNamesForLetter = [lettersForWords objectForKey:key];
        return arrayOfNamesForLetter.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];

    NSString *nameOfContact;
    if (_isSearching && _searchMessagesNot.count)
    {
        nameOfContact = _searchMessagesNot[indexPath.row];
    }
    else
    {
        NSString *key = [sortedKeys objectAtIndex:indexPath.section];
        NSArray *arrayOfNamesForLetter = [lettersForWords objectForKey:key];
        if (arrayOfNamesForLetter.count) {
            nameOfContact = arrayOfNamesForLetter[indexPath.row];
        }
    }

    NSArray *phoneNumbers = [arrayOfNamesAndNumbers objectForKey:nameOfContact];
    for (NSString *phoneNumber in phoneNumbers)
    {
        if (phoneNumber.length)
        {
            cell.textLabel.text = nameOfContact;
            if ([_arrayofSelectedPhoneNumbers containsObject:phoneNumber])
            {
                UIImage *image = [[UIImage imageNamed:@"email"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
                cell.accessoryView.tintColor = [UIColor benFamousOrange];
                imageView.tintColor = [UIColor benFamousOrange];
                
//                cell.accessoryView = imageView;
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else
            {
                cell.accessoryView = nil;
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
    }

    cell.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:.95f];
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.font = [UIFont systemFontOfSize:18];

    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:oldIndexPath];
    NSString *nameOfContact;


    if (_isSearching && _searchMessagesNot.count)
    {
        nameOfContact = _searchMessagesNot[indexPath.row];
    } else {
        NSString *key = [sortedKeys objectAtIndex:indexPath.section];
        NSArray *arrayOfNamesForLetter = [lettersForWords objectForKey:key];
        nameOfContact = arrayOfNamesForLetter[indexPath.row];
    }

    NSArray *phoneNumbers = [arrayOfNamesAndNumbers objectForKey:nameOfContact];

    //MORE THAN ONE PHONE NUMBER
    if (phoneNumbers.count > 1)
    {
        if (cell.accessoryType == UITableViewCellAccessoryCheckmark)
        {
            for (NSString *phoneNumber in phoneNumbers) {
                [_arrayofSelectedPhoneNumbers removeObject: phoneNumber];
            }
            _selectedCell.accessoryView = nil;
            _selectedCell.accessoryType = UITableViewCellAccessoryNone;
        }
        else
        {
            if (_arrayofSelectedPhoneNumbers.count > 6)
            {
                [ProgressHUD showError:@"Max Contact Invite"];
                return;
            }
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Multiple Unknown Phone Numbers" message:@"Which number is the mobile number?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:0, nil];
            for (NSString *phoneNumber in phoneNumbers)
            {
                [alert addButtonWithTitle:phoneNumber];
            }
            _selectedCell = cell;
            [alert show];
        }

    }//ONLY ONE PHONE NUMBER
    else if (phoneNumbers.count == 1)
    {
        NSString *firstNumber = phoneNumbers.firstObject;
        if (firstNumber.length == 0) return;

        if (cell.accessoryView == nil && cell.accessoryType == UITableViewCellAccessoryNone)
        {
            if (_arrayofSelectedPhoneNumbers.count > 6) {
                [ProgressHUD showError:@"Max Contact Invite"];
                return;
            }
            [_arrayofSelectedPhoneNumbers addObject:firstNumber];
            UIImage *image = [[UIImage imageNamed:@"email"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            cell.accessoryView.tintColor = [UIColor benFamousOrange];
            imageView.tintColor = [UIColor benFamousOrange];
//            cell.accessoryView = imageView;
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else
        {
            [_arrayofSelectedPhoneNumbers removeObject:firstNumber];
            if (_arrayofSelectedPhoneNumbers.count == 0) {
            }
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
}

-(IBAction)textFieldDidChange:(UITextField *)textField
{
    if ([textField.text length] > 0)
    {
        [_searchMessagesNot removeAllObjects];
        _isSearching = YES;
        [self searchUsers:[textField.text lowercaseString]];
    } else {
        _isSearching = NO;
        [_tableView reloadData];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    textField.text =@"";
    _searchMessagesNot = [NSMutableArray new];
    _isSearching = YES;
    _searchCloseButton.hidden = NO;
    //    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    //  [searchBar_ setShowsCancelButton:NO animated:YES];
    _isSearching = NO;
    _searchCloseButton.hidden = YES;
    [textField resignFirstResponder];
    textField.text = @"";
    [_tableView reloadData];
}

-(IBAction)closeSearch:(id)sender
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
            UIImage *image = [[UIImage imageNamed:@"email"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            self.selectedCell.accessoryView.tintColor = [UIColor benFamousOrange];
            imageView.tintColor = [UIColor benFamousOrange];
            _selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
            [_arrayofSelectedPhoneNumbers addObject:phoneNumber];
        }
    }

    if ([alertView.title isEqualToString:@"Contacts not enabled."] && buttonIndex == 1)
    {
        //code for opening settings app in iOS 8
        [self.navigationController popToRootViewControllerAnimated:0];
        [[UIApplication sharedApplication] openURL:[NSURL  URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

@end
