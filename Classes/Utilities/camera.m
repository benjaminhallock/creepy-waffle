
#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "camera.h"
#import "CustomCameraView.h"
#import "NavigationController.h"

void StartCustomCamera (id target) {
    CustomCameraView *customCameraView = [CustomCameraView new];
    customCameraView.delegate = target;
    [target presentViewController:customCameraView animated:YES completion:0];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
BOOL ShouldStartCamera(id target, BOOL canEdit)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO) return NO;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
	
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]
		&& [[UIImagePickerController availableMediaTypesForSourceType:
			 UIImagePickerControllerSourceTypeCamera] containsObject:(NSString *)kUTTypeImage])
	{
		cameraUI.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeImage];
		cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
		
		if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear])
		{
			cameraUI.cameraDevice = UIImagePickerControllerCameraDeviceRear;
		}
		else if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront])
		{
			cameraUI.cameraDevice = UIImagePickerControllerCameraDeviceFront;
		}
	}
	else return NO;
	
	cameraUI.allowsEditing = canEdit;
	cameraUI.showsCameraControls = YES;
	cameraUI.delegate = target;
	
	[target presentViewController:cameraUI animated:YES completion:nil];
	
	return YES;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
BOOL ShouldStartPhotoLibrary(id target, BOOL canEdit)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] == NO
		 && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum] == NO)) return NO;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
	
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]
		&& [[UIImagePickerController availableMediaTypesForSourceType:
			 UIImagePickerControllerSourceTypePhotoLibrary] containsObject:(NSString *)kUTTypeImage])
	{
		cameraUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
		cameraUI.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeImage];
	}
	else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]
			 && [[UIImagePickerController availableMediaTypesForSourceType:
				  UIImagePickerControllerSourceTypeSavedPhotosAlbum] containsObject:(NSString *)kUTTypeImage])
	{
		cameraUI.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
		cameraUI.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeImage];
	}
	else return NO;
	
	cameraUI.allowsEditing = canEdit;
	cameraUI.delegate = target;
	
	[target presentViewController:cameraUI animated:YES completion:nil];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:1];
	
	return YES;
}
