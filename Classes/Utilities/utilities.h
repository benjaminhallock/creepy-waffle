

#import "MessagesView.h"
#import "AppConstant.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
void			ShowProfileSettings		    (MessagesView *target);
void			ShowNewMessage       	    (id target);

UIImage*		ResizeImage					(UIImage *image, CGFloat width, CGFloat height);

void			PostNotification			(NSString *notification);

//-------------------------------------------------------------------------------------------------------------------------------------------------
NSString*		TimeElapsed					(NSTimeInterval seconds);
