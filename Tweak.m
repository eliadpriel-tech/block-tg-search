#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface UIWindow (SafeBlockSearch)
@end

@implementation UIWindow (SafeBlockSearch)

- (UIView *)safe_swizzled_hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // וידוא שהחלון מוכן ותקין
    if (self.hidden || self.alpha <= 0.01) {
        return [self safe_swizzled_hitTest:point withEvent:event];
    }

    // בדיקה האם יש חלון מודאלי פתוח (כגון שיתוף / העברת הודעה)
    BOOL hasModal = NO;
    UIViewController *root = self.rootViewController;
    if (root != nil && root.presentedViewController != nil) {
        hasModal = YES;
    }

    // אם אנחנו במסך הראשי ללא מסך מודאלי, חוסמים את אזור החיפוש העליון באייפון 11
    if (!hasModal) {
        if (point.y >= 44 && point.y <= 140) {
            // מבטל את המגע - מחזיר nil כדי ששום רכיב לא יקבל את הלחיצה
            return nil;
        }
    }

    return [self safe_swizzled_hitTest:point withEvent:event];
}

@end

__attribute__((constructor)) static void initSafeTweak(void) {
    Class class = [UIWindow class];
    SEL originalSelector = @selector(hitTest:withEvent:);
    SEL swizzledSelector = @selector(safe_swizzled_hitTest:withEvent:);

    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

    if (originalMethod && swizzledMethod) {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}
