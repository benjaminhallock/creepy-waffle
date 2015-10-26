

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


#import "UIColor.h"

@implementation UIColor (JSQMessages)

#pragma mark - Message bubble colors

+ (UIColor *)jsq_messageBubbleGreenColor
{
    return [UIColor colorWithHue:130.0f / 360.0f
                      saturation:0.68f
                      brightness:0.84f
                           alpha:1.0f];
}

+ (UIColor *)jsq_messageBubbleBlueColor
{
    return [UIColor colorWithHue:210.0f / 360.0f
                      saturation:0.94f
                      brightness:1.0f
                           alpha:1.0f];
}

+ (UIColor *)jsq_messageBubbleRedColor
{
    return [UIColor colorWithHue:0.0f / 360.0f
                      saturation:0.79f
                      brightness:1.0f
                           alpha:1.0f];
}

+ (UIColor *)jsq_messageBubbleLightGrayColor
{
    return [UIColor colorWithHue:240.0f / 360.0f
                      saturation:0.02f
                      brightness:0.92f
                           alpha:1.0f];
}

+ (UIColor *)benFamousGreen
{
//81 180 165 OLD
    return [UIColor colorWithRed:255/255.0f green:41/255.0f blue:73/255.0f alpha:1.0f];
}

+ (UIColor *)benFamousOrange
{
//232 113 67 OLD
    return [UIColor colorWithRed:254/255.0f green:252/255.0f blue:94/255.0f alpha:1.0f];
}

+ (UIColor *)blueTintColor
{
    //232 113 67 OLD
    return [UIColor colorWithRed:0/255.0f green:122/255.0f blue:255/255.0f alpha:1.0f];
}

+ (UIColor *)benFlatPeach
{
//    236	174	139	srgb
//    239 173 144 native
    return [UIColor colorWithRed:239/255.0f
                           green:173/255.0f
                            blue:144/255.0f
                            alpha:1];
}

+ (UIColor *)benMustardYellow
{
// 235 206 88 native
    //234	207	57  srgb
    return [UIColor colorWithRed:235/255.0f
                           green:206/255.0f
                            blue:88/255.0f
                           alpha:1];
}

+ (UIColor *)benFlatGreen
{
//    167	198	152	srgb
//    165 198 157 native
    return [UIColor colorWithRed:165/255.0f
                           green:198/255.0f
                            blue:157/255.0f
                           alpha:1];
}



+(UIColor *)ben1A {
    return [UIColor colorFromHexString:@"#f3b291"];
}

+(UIColor *)ben1B {
    return [UIColor colorFromHexString:@"#a9ca9e"];
}

+(UIColor *)ben1C {
    return [UIColor colorFromHexString:@"#82c5d0"];
}

+(UIColor *)ben1D {
    return [UIColor colorFromHexString:@"#efd32c"];
}

+(UIColor *)ben1E {
    return [UIColor colorFromHexString:@"#dc8d8d"];
}

+(UIColor *)ben2A {
     //OLD adc35e
    return [UIColor colorFromHexString:@"#a7c138"];
}

+(UIColor *)ben2B {
    return [UIColor colorFromHexString:@"#b17181"];
}

+(UIColor *)ben2C {
    return [UIColor colorFromHexString:@"#83bec4"];
}

+(UIColor *)ben2D {
    return [UIColor colorFromHexString:@"#d39c75"];
}

+(UIColor *)ben2E {
    return [UIColor colorFromHexString:@"#6991b6"];
}

+(UIColor *)ben3A {
    return [UIColor colorFromHexString:@"#b77069"];
}

+(UIColor *)ben3B {
    return [UIColor colorFromHexString:@"#82b154"];
}

+(UIColor *)ben3C {
    return [UIColor colorFromHexString:@"#77acc8"];
}

+(UIColor *)ben3D {
    return [UIColor colorFromHexString:@"#c1b16f"];
}

+(UIColor *)ben3E {
    return [UIColor colorFromHexString:@"#4fb687"];
}

+(UIColor *)ben4A {
    return [UIColor colorFromHexString:@"#c47878"];
}

+(UIColor *)ben4B {
    return [UIColor colorFromHexString:@"#76a2a7"];
}

+(UIColor *)ben4C {
    return [UIColor colorFromHexString:@"#bccd77"];
}

+(UIColor *)ben4D {
//     OLD b77974
    return [UIColor colorFromHexString:@"#bc978d"];
}

+(UIColor *)ben4E {
    return [UIColor colorFromHexString:@"#5a92af"];
}

+ (UIColor *)benFlatOrange
{
//    235	168	94	SRGB
//    238 167 105 native
    return [UIColor colorWithRed:238/255.0f
                           green:167/255.0f
                            blue:105/255.0f
                           alpha:1];
}


+ (UIColor *)benBubbleGreen
{
    //    56	178	149	srgb
    //    38 178 151 native
    return [UIColor colorWithRed:38/255.0f
                           green:178/255.0f
                            blue:151/255.0f
                           alpha:1];
}

+ (UIColor *)benForestGreen
{
//40	129	111	
    return [UIColor colorWithRed:40/255.0f
                           green:129/255.0f
                            blue:111/255.0f
                           alpha:1];
}

+ (UIColor *)benDarkBlue
{
//29	68	74	
    return [UIColor colorWithRed:29/255.0f
                           green:68/255.0f
                            blue:74/255.0f
                           alpha:1];
}

+ (UIColor *)benFlatRed
{
//    207	96	93	
    return [UIColor colorWithRed:207/255.0f
                           green:96/255.0f
                            blue:93/255.0f
                           alpha:1];
}

+ (UIColor *)benFlatterGreen
{
//146	191	178	
    return [UIColor colorWithRed:146/255.0f
                           green:191/255.0f
                            blue:178/255.0f
                           alpha:1];
}

+ (UIColor *)mustardGreen
{
//146	191	178
    return [UIColor colorWithRed:146/255.0f
                           green:191/255.0f
                            blue:178/255.0f
                           alpha:1];
}


+ (NSString *) stringFromColor:(UIColor *)color
{
    CGColorRef colorRef = color.CGColor;
    NSString *colorString = [CIColor colorWithCGColor:colorRef].stringRepresentation;
    return colorString;
}

// Assumes input like "#00FF00" (#RRGGBB).
+ (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

+ (UIColor *) colorFromString:(NSString *)string
{
    CIColor *coreColor = [CIColor colorWithString:string];
    UIColor *color = [UIColor colorWithCIColor:coreColor];
    return color;
}

+(UIColor *)colorWithColor:(UIColor *)color {
    return color;
}

+ (NSArray *)arrayOfColorsCore {
    return [NSArray arrayWithObjects:[UIColor benBubbleGreen],
            [UIColor benFamousOrange], [UIColor benFamousGreen],[UIColor jsq_messageBubbleBlueColor],[UIColor jsq_messageBubbleGreenColor], nil];
}

+ (UIColor *) benRandomCore {
    return [[self arrayOfColorsCore] objectAtIndex:arc4random_uniform((int)[self arrayOfColorsCore].count)];
}

#pragma mark - Utilities

- (UIColor *)jsq_colorByDarkeningColorWithValue:(CGFloat)value
{
    NSUInteger totalComponents = CGColorGetNumberOfComponents(self.CGColor);
    BOOL isGreyscale = (totalComponents == 2) ? YES : NO;
    
    CGFloat *oldComponents = (CGFloat *)CGColorGetComponents(self.CGColor);
    CGFloat newComponents[4];
    
    if (isGreyscale) {
        newComponents[0] = oldComponents[0] - value < 0.0f ? 0.0f : oldComponents[0] - value;
        newComponents[1] = oldComponents[0] - value < 0.0f ? 0.0f : oldComponents[0] - value;
        newComponents[2] = oldComponents[0] - value < 0.0f ? 0.0f : oldComponents[0] - value;
        newComponents[3] = oldComponents[1];
    }
    else {
        newComponents[0] = oldComponents[0] - value < 0.0f ? 0.0f : oldComponents[0] - value;
        newComponents[1] = oldComponents[1] - value < 0.0f ? 0.0f : oldComponents[1] - value;
        newComponents[2] = oldComponents[2] - value < 0.0f ? 0.0f : oldComponents[2] - value;
        newComponents[3] = oldComponents[3];
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGColorRef newColor = CGColorCreate(colorSpace, newComponents);
	CGColorSpaceRelease(colorSpace);
    
	UIColor *retColor = [UIColor colorWithCGColor:newColor];
	CGColorRelease(newColor);
    
    return retColor;
}

@end