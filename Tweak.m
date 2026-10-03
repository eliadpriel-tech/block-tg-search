#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@implementation UIWindow (BlockSearchArea)

- (UIView *)block_hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [self block_hitTest:point withEvent:event];
    
    // אם נפתח חלון מעל המסך (שיתוף / העברת הודעה), מאפשרים שימוש כרגיל
    UIViewController *root = self.rootViewController;
    if (root != nil && root.presentedViewController != nil) {
        return hitView;
    }
    
    // חסימת אזור שורת החיפוש באייפון 11 (מתחת ל-Notch, בין 50 ל-105 פיקסלים)
    if (point.y >= 50.0 && point.y <= 105.0) {
        static UIView *dummyView = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            dummyView = [[UIView alloc] initWithFrame:CGRectZero];
            dummyView.userInteractionEnabled = NO;
        });
        return dummyView;
    }
    
    return hitView;
}

@end

__attribute__((constructor)) static void initTweak(void) {
    Class class = [UIWindow class];
    SEL origSEL = @selector(hitTest:withEvent:);
    SEL swizSEL = @selector(block_hitTest:withEvent:);
    
    Method origMethod = class_getInstanceMethod(class, origSEL);
    Method swizMethod = class_getInstanceMethod(class, swizSEL);
    
    if (origMethod && swizMethod) {
        method_exchangeImplementations(origMethod, swizMethod);
    }
}
