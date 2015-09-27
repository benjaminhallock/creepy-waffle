

#import "MasterScrollView.h"
#import "ChatView.h"
#import "pushnotification.h"
#import "utilities.h"
#import "messages.h"
@implementation MasterScrollView
{
    CGFloat lastContentOffset;
}

- (id) init
{
    self = [super init];

    if (self)
    {
        self.delegate = self;

        self.bounces = NO;
        self.scrollEnabled = 1;
        self.pagingEnabled = 1;
        self.directionalLockEnabled = YES;
        self.showsHorizontalScrollIndicator = 0;
    }

    return self;
}

- (void)openView:(UIViewController *)view2
{
    if ([self.navInbox.viewControllers.lastObject isKindOfClass:[ChatView class]])
    {
        //Your in a different chat.
        [self.navInbox popViewControllerAnimated:0];
    }
    else
    {
        //New Conversation Perhaps.
        [self.navInbox popToRootViewControllerAnimated:0];
    }

    /// IF CUSTOM CHAT ROOM IS SAME AS ROOM BEFORE, POP THE STACK ONCE.
    MessagesView *messagesView = _navInbox.viewControllers.firstObject;
    messagesView.hidesBottomBarWhenPushed = YES;
    [_navInbox pushViewController:view2 animated:0];
    messagesView.hidesBottomBarWhenPushed = NO;

    [self setContentOffset:CGPointMake([UIScreen mainScreen].bounds.size.width, 0) animated:0];
}


- (BOOL) checkIfCurrentChatIsEqualToRoom:(NSString *)roomId didComeFromBackground:(BOOL)isBack
{
    //If there is a popup camera.
    if (self.navInbox.presentedViewController)
    {
        return NO;
    }
    
    if ([self.navInbox.viewControllers.lastObject isKindOfClass:[ChatView class]])
    {
        ChatView *chatView = self.navInbox.viewControllers.lastObject;
        if ([chatView.room.objectId isEqualToString: roomId])
        {
            [chatView refresh];
            return YES;
        }
        else
        {
            //POP CURRENT ROOM IF NOT PUSH ROOM.//ACTUALLY NO, ONLY IF COMING FROM BACKGROUND.
            if (isBack) {
                [self.navInbox popToRootViewControllerAnimated:0];
            }
        }
    }

    return NO;
}

/*
 - (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
 {
 [self gestureRecognizer:self.gestureRecognizers.firstObject shouldRecognizeSimultaneouslyWithGestureRecognizer:self.gestureRecognizers.lastObject];

 lastContentOffset = scrollView.contentOffset.x;
 }

 - (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {

 if (lastContentOffset < (int)scrollView.contentOffset.x) {
 // moved right
 }
 else if (lastContentOffset > (int)scrollView.contentOffset.x) {
 // moved left
 }
 }
 */

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    //IF DRAGGING IS UP, LOCK IT BACK DOWN TO NO.

    if (gestureRecognizer.state != 0 && otherGestureRecognizer.state != 1)
    {
        return YES;
    } else {
        return NO;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    return;
    lastContentOffset = scrollView.contentOffset.x;
    if (lastContentOffset < self.bounds.size.width - 1) {
        [[UIApplication sharedApplication] setStatusBarHidden:1 withAnimation:UIStatusBarAnimationSlide];
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:0 withAnimation:UIStatusBarAnimationSlide];
    }
}


@end
