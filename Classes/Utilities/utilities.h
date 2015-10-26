

#import "MessagesView.h"
#import "AppConstant.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
NSString*       formatPhoneNumberForCountry(NSString *phoneNumber);

void			ShowProfileSettings		    (MessagesView *target);
void			ShowNewMessage       	    (id target);

UIImage*		ResizeImage					(UIImage *image, CGFloat width, CGFloat height);

void			PostNotification			(NSString *notification);

//-------------------------------------------------------------------------------------------------------------------------------------------------
NSString*		TimeElapsed					(NSTimeInterval seconds);
