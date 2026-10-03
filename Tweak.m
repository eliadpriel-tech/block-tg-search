#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@implementation UIWindow (SafeCoordBlock)

- (UIView *)safe_hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [self safe_hitTest:point withEvent:event];

    // בדיקה האם המשתמש כבר מחובר (במסך הראשי יש UITabBarController פעיל)
    UIViewController *root = self.rootViewController;
    BOOL isInsideMainApp = NO;

    if ([root isKindOfClass:[UITabBarController class]]) {
        isInsideMainApp = YES;
    } else if (root.presentedViewController != nil) {
        // אם נפתח חלון מעל (כמו שיתוף/העברה), לא חוסמים
        return hitView;
    }

    // חוסם רק אם אנחנו בתוך האפליקציה המחוברת ובטווח הגובה של שורת החיפוש באייפון 11
    if (isInsideMainApp && point.y >= 50.0 && point.y <= 105.0) {
        // החזרת View שקט בלי לפגוע במבנה הניווט
        static UIView *dummyView = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            CGRect zeroRect = (CGRect){{0, 0}, {0, 0}};
            dummyView = [[UIView alloc] initWithFrame:zeroRect];
            dummyView.userInteractionEnabled = NO;
        });
        return dummyView;
    }

    return hitView;
}

@end

__attribute__((constructor)) static void initSafeCoordBlock(void) {
    Class class = [UIWindow class];
    SEL origSEL = @selector(hitTest:withEvent:);
    SEL swizSEL = @selector(safe_hitTest:withEvent:);

    Method origMethod = class_getInstanceMethod(class, origSEL);
    Method swizMethod = class_getInstanceMethod(class, swizSEL);

    if (origMethod && swizMethod) {
        method_exchangeImplementations(origMethod, swizMethod);
    }
}
