#import "AppConstant.h"
#import "JSQMessages.h"
#import "KLCPopup.h"

@interface ChatView : JSQMessagesViewController
<JSQMessagesCollectionViewDelegateFlowLayout,
JSQMessagesCollectionViewDataSource,
UITextViewDelegate >

- (id)initWith:(PFObject *) room name:(NSString *)name;

-(void) refresh;

@property PFObject *room;
@property PFObject *message;

@property int numberOfSetsBeforeSendings;

@property BOOL isSendingTextMessage;
@property BOOL isNewNewConversation;

@end
