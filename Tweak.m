#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface DummyBlockerView : UIView
@end

@implementation DummyBlockerView
@end

@implementation UIWindow (BlockSearchArea)

- (UIView *)block_hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [self block_hitTest:point withEvent:event];
    
    // בדיקה האם יש חלון מודאלי פתוח (שיתוף / העברת הודעה)
    UIViewController *root = self.rootViewController;
    if (root != nil && root.presentedViewController != nil) {
        return hitView; // מאפשר שימוש רגיל אם נפתח חלון מעל המסך
    }
    
    // שורת החיפוש של טלגרם באייפון 11 ממוקמת מתחת ל-Notch (בין Y=50 ל-Y=105)
    // כפתור התחל נמצא בתחתית (מעל Y=600), ורשימת השיחות מתחת ל-Y=105
    if (point.y >= 50 && point.y <= 105) {
        static DummyBlockerView *dummyView = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            dummyView = [[DummyBlockerView alloc] initWithFrame:CGRectZero];
            dummyView.userInteractionEnabled = NO;
        });
        
        // החזרת View שקט שאינו מקבל אירועים - בולע את הנגיעה מבלי לרסק את ה-hitTest של החלון
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
