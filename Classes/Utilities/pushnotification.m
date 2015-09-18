

#import <Parse/Parse.h>

#import "AppConstant.h"

#import "pushnotification.h"

void ParsePushUserAssign(void)
{
	PFInstallation *installation = [PFInstallation currentInstallation];
	installation[PF_INSTALLATION_USER] = [PFUser currentUser];
	[installation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
	{
		if (error != nil)
		{
			NSLog(@"ParsePushUserAssign save error.");
		}
	}];
}

void ParsePushUserResign(void)
{
	PFInstallation *installation = [PFInstallation currentInstallation];
    [installation removeObjectForKey:PF_INSTALLATION_USER];
	[installation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
	{
		if (error != nil)
		{
			NSLog(@"ParsePushUserResign save error.");
		}
	}];
}

void SendPushNotification(PFObject *room, NSString *text)
{
	PFQuery *query = [PFQuery queryWithClassName:PF_MESSAGES_CLASS_NAME];
	[query whereKey:PF_MESSAGES_ROOM equalTo:room];
	[query whereKey:PF_MESSAGES_USER notEqualTo:[PFUser currentUser]];
	[query includeKey:PF_MESSAGES_USER_DONOTDISTURB];
	[query setLimit:1000];
	PFQuery *queryInstallation = [PFInstallation query];
	[queryInstallation whereKey:PF_INSTALLATION_USER matchesKey:PF_MESSAGES_USER_DONOTDISTURB inQuery:query];

	PFPush *push = [[PFPush alloc] init];
	[push setQuery:queryInstallation];
    NSString *name = [[PFUser currentUser] valueForKey:PF_USER_FULLNAME];
    text = [NSString stringWithFormat:@"%@: %@", name, text];

    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                          text, @"alert",
                          @"Increment", @"badge",
                          @"default", @"sound",
                        room.objectId, @"r",
                          nil];

    [push setData:data];
    [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
	{
		if (error)
		{
			NSLog(@"SendPushNotification send error.");
        } else {
            NSLog(@"PUSH SENT");
        }
	}];
}
