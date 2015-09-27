

#import "AppConstant.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
void	CreateMessageItem			(PFObject *room, NSArray *arrayOfUsers);
void		HideMessageItem			(PFObject *message);

//-------------------------------------------------------------------------------------------------------------------------------------------------
void		UpdateMessageCounter		(PFObject *room, NSString *lastMessage, PFObject *pictureAttached);
void		ClearMessageCounter			(PFObject *room);
