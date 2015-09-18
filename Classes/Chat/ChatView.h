
#import "JSQMessages.h"

#import "KLCPopup.h"

#import <Parse/Parse.h>

#import <UIKit/UIKit.h>

#import "MasterScrollView.h"

@interface ChatView : JSQMessagesViewController

<JSQMessagesCollectionViewDelegateFlowLayout,

JSQMessagesCollectionViewDataSource,

UITextViewDelegate >

- (id)initWith:(PFObject *) room name:(NSString *)name;

-(void) refresh;

@property PFObject *room;

@property PFObject *message;

@property BOOL isNewChatroomWithPhotos;

@property (strong, nonatomic) PFObject *selectedSetForPictures;

@property int numberOfSetsBeforeSendings;

@property BOOL isSendingTextMessage;

@property BOOL isNewNewConversation;

@end
