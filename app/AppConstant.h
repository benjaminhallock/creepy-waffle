#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import "UIColor.h"

@interface AppConstant : NSObject
+ (NSArray *)arrayOfColors;
+ (NSString *)formatPhoneNumberForCountry:(NSString *)phoneNumber;
@end

#define     NETWORK_ERROR                       @"Network Error"

#define		PF_INSTALLATION_CLASS_NAME			@"_Installation"		//	Class name
#define		PF_INSTALLATION_OBJECTID			@"objectId"				//	String
#define		PF_INSTALLATION_USER				@"user"					//	Pointer to User Class
#define     PF_KEY_SHOULDVIBRATE                @"shouldVibrate"        //USER DEFFUALTS

#define		PF_USER_CLASS_NAME					@"_User"				//	Class name
#define		PF_USER_OBJECTID					@"objectId"				//	String
#define		PF_USER_USERNAME					@"username"				//	String
#define		PF_USER_PASSWORD					@"password"				//	String
#define		PF_USER_EMAIL						@"email"				//	String
#define		PF_USER_FULLNAME					@"fullname"				//	String
#define		PF_USER_ISVERIFIED                  @"isVerified"
#define		PF_USER_PASSWORD_BOOL               @"didChangePassword"
#define		PF_USER_PASSWORD_TEMP               @"tempPassword"
#define		PF_USER_PHONEVERIFICATIONCODE       @"phoneVerificationCode"
#define		PF_USER_FULLNAME_LOWER				@"fullname_lower"		//	String
#define		PF_USER_FACEBOOKID					@"facebookId"			//	String
#define		PF_USER_PICTURE						@"picture"				//	File
#define		PF_USER_THUMBNAIL					@"thumbnail"			//	File
#define		PF_USER_CHATROOMS					@"chatrooms"			//	Relation

#define		PF_CHAT_CLASS_NAME					@"Chat"					//	Class name
#define		PF_CHAT_USER						@"user"					//	Pointer to User
#define		PF_CHAT_ROOM						@"room"				    //	String
#define		PF_CHAT_TEXT						@"text"					//	String
#define		PF_CHAT_SETID						@"setId"				//	String
#define		PF_CHAT_PICTUREPOINTER				@"tagPicture"			//	String
#define		PF_CHAT_PICTURE						@"picture"				//	File
#define		PF_CHAT_CREATEDAT					@"createdAt"			//	Date
#define     PF_CHAT_ISUPLOADED                  @"isUploaded"           //Check if uploaded
#define     PF_CHAT_ISVIDEO                     @"isVideo"           //Check if uploaded

#define		PF_CHATROOMS_CLASS_NAME				@"ChatRooms"			//	Class name
#define		PF_CHATROOMS_NAME					@"name"					//	String
#define		PF_CHATROOMS_USERS                  @"users"                //	Class name
#define		PF_CHATROOMS_USEROBJECTS            @"userObjects"          //	Class name
#define		PF_CHATROOMS_ROOMNUMBER             @"roomNumber"             //	String
#define		PF_CHATROOMS_FLAGCOUNT              @"flagCount"             //	String

#define		PF_ALBUMS_CLASS_NAME				@"Albums"                //	Class name
#define		PF_ALBUMS_NICKNAME                  @"nickname"				//	String
#define		PF_ALBUMS_USER                      @"user"                 //	Class name
#define		PF_ALBUMS_SET                       @"set"                  //	Class name

#define     PF_FAVORITES_CLASS_NAME             @"Favorites"
#define     PF_FAVORITES_SET                    @"set"
#define     PF_FAVORITES_USER                    @"user"
#define     PF_FAVORITES_ALBUM                  @"album"

#define		PF_SET_CLASS_NAME                   @"Sets"                     //	Class name
#define		PF_SET_ROOM                         @"room"                     //	String
#define		PF_SET_LASTPICTURE                  @"lastPicture"              //	String
#define		PF_SET_ROOMNUMBER                   @"roomNumber"               //	String
#define		PF_SET_USER                         @"user"                     //	Class name
#define		PF_SET_UPDATED                     @"updatedAction"             //	Class name

#warning CHANGING PICTURES TO CHAT
#define		PF_PICTURES_CLASS_NAME				@"Chat"			      //Class name
#define		PF_PICTURES_USER                    @"user"                   //String
#define		PF_PICTURES_CHATROOM				@"room"                   //Pointer
#define		PF_PICTURES_PICTURE                 @"picture"                //PFFile
#define		PF_PICTURES_SETID                   @"setId"                //Random # String
#define     PF_PICTURES_THUMBNAIL               @"thumbnail"             // PFFILE
#define     PF_PICTURES_IS_VIDEO               @"isVideo"             // PFFILE
#define		PF_PICTURES_UPDATEDACTION			@"updatedAction"		//	Date


#define		PF_MESSAGES_CLASS_NAME				@"Messages"				//	Class name
#define		PF_MESSAGES_HIDE_UNTIL_NEXT			@"shouldHideUntilNext"	//	Class name
#define		PF_MESSAGES_USER					@"user"					//	Pointer to User
#define		PF_MESSAGES_USER_DONOTDISTURB		@"userPush"					//	Pointer to 
#define		PF_MESSAGES_ROOM					@"room"				   //	Pointer to Room
#define		PF_MESSAGES_DESCRIPTION				@"description"			//	String
#define		PF_MESSAGES_LASTUSER				@"lastUser"				//	Pointer lastuser
#define		PF_MESSAGES_LASTMESSAGE				@"lastMessage"			//	String
#define		PF_MESSAGES_LASTPICTURE				@"lastPicture"			//	Chat pointer
#define		PF_MESSAGES_LASTPICTUREUSER			@"lastPictureUser"	//	PFuser
#define		PF_MESSAGES_COUNTER					@"counter"				//	Number
#define		PF_MESSAGES_UPDATEDACTION			@"updatedAction"		//	Date
#define		PF_MESSAGES_NICKNAME                @"nickname"             //	Date

//-------------------------------------------------------------------------------------------------------------------------------------------------
#define		NOTIFICATION_APP_STARTED			@"NCAppStarted"
#define		NOTIFICATION_DELETE_CAMERA_PIC		@"deleteCameraPic"
#define		NOTIFICATION_TAP_CAMERA_PIC         @"tapCameraPic"
#define		NOTIFICATION_APP_MAIL_SEND			@"SENDTEXT"
#define		NOTIFICATION_REFRESH_CHATROOM       @"refreshChatroomIfOpen"
#define		NOTIFICATION_LEAVE_CHATROOM			@"Leave Chatroom"
#define		NOTIFICATION_CLEAR_CAMERA_STUFF		@"ClearCameraStuff"
#define		NOTIFICATION_CAMERA_POPUP           @"PopUpCamera"
#define     NOTIFICATION_CLICKED_PUSH           @"didRecievePushAndClicked"
#define		NOTIFICATION_OPEN_CHAT_VIEW         @"OpenChatView"
#define		NOTIFICATION_DISABLE_SCROLL_WELCOME @"DisableScrollWelcome"
#define		NOTIFICATION_ENABLE_SCROLL_WELCOME  @"EnableScrollWelcome"
#define		NOTIFICATION_SLIDE_MIDDLE_WELCOME   @"SlideMiddleWelcome"
#define		NOTIFICATION_REFRESH_INBOX          @"RefreshInboxView"
#define		NOTIFICATION_RELOAD_INBOX          @"ReloadTableView"
#define		NOTIFICATION_USER_LOGGED_IN			@"NCUserLoggedIn"
#define		NOTIFICATION_ENABLESCROLLVIEW		@"enableScrollView"
#define		NOTIFICATION_DISABLESCROLLVIEW		@"disableScrollView"
#define		NOTIFICATION_REFRESH_ALBUMS         @"refreshAlbumsView"
#define		NOTIFICATION_REFRESH_FAVORITES      @"refreshFavoritesView"
#define		NOTIFICATION_USER_LOGGED_OUT		@"NCUserLoggedOut"

#define		ASSETS_NEW_PEOPLE                   @"addContacts"
#define		ASSETS_TYPING                       @"typing"
#define		ASSETS_NEW_SETTINGS                 @"settings"
#define		ASSETS_INBOX                        @"Inbox"
#define		ASSETS_INBOX_FLIP                    @"Inbox Flip"
#define     ASSETS_NEW_FAVORITE                 @"FavoritesStar"
#define		ASSETS_NEW_CAMERA                   @"Camera Icon"
#define     ASSETS_STAR_OFF_PLUS                @"star-off"
#define		ASSETS_NEW_CAMERASQUARE             @"Camera Icon Square"
#define		ASSETS_NEW_COMPOSE                  @"Compose Button"
#define		ASSETS_NEW_BLANKV                   @"Blank V"
#define		ASSETS_NEW_CAMERACUTOUT             @"camera cutout"
#define		ASSETS_BACK_BUTTON                  @"Back Button FAV"
#define		ASSETS_BACK_BUTTON_RIGHT            @"Back Button INBOX"
#define		ASSETS_BACK_BUTTON_DOWN             @"Back Button DOWN"
#define		ASSETS_CLOSE                        @"close3"
#define     ASSETS_UNREAD                       @"1unreadMesseageIcon"
#define     ASSETS_READ                         @"1readMesseageIcon"
#define     ASSETS_STAR_ON                      @"star-on2"

