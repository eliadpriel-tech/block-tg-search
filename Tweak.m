#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface UIResponder (BlockGlobalSearchOnly)
@end

@implementation UIResponder (BlockGlobalSearchOnly)

- (BOOL)custom_becomeFirstResponder {
    if ([self isKindOfClass:[UIView class]]) {
        UIView *current = (UIView *)self;
        BOOL isSearchField = NO;
        UIViewController *containingVC = nil;

        // בדיקת שרשרת הרכיבים לאיתור שדה חיפוש ומציאת ה-ViewController
        UIResponder *responder = current;
        while (responder) {
            NSString *responderClassName = NSStringFromClass([responder class]);

            if ([responderClassName rangeOfString:@"Search" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                isSearchField = YES;
            }

            if ([responder isKindOfClass:[UIViewController class]]) {
                containingVC = (UIViewController *)responder;
                break;
            }
            responder = responder.nextResponder;
        }

        if (isSearchField && containingVC != nil) {
            NSString *vcName = NSStringFromClass([containingVC class]);

            // 1. החרגה להעברות, שיתופים ובחירת נמענים (Forward / Share / PeerSelection)
            if ([vcName rangeOfString:@"Share" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                [vcName rangeOfString:@"Forward" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                [vcName rangeOfString:@"PeerSelection" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                [vcName rangeOfString:@"Contact" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                return [self custom_becomeFirstResponder];
            }

            // 2. החרגה לתזמונים (Scheduled Messages / Timer)
            if ([vcName rangeOfString:@"Schedule" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                [vcName rangeOfString:@"Timer" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                return [self custom_becomeFirstResponder];
            }

            // 3. החרגה לכל מסך מודאלי שקופץ מעל האפליקציה (כמו תפריטי העברה ושיתוף)
            if (containingVC.presentingViewController != nil) {
                return [self custom_becomeFirstResponder];
            }

            // 4. החרגה לחיפוש פנימי בתוך שיחה, קבוצה או ערוץ (ChatController)
            if ([vcName rangeOfString:@"ChatController" options:NSCaseInsensitiveSearch].location != NSNotFound &&
                [vcName rangeOfString:@"ChatList" options:NSCaseInsensitiveSearch].location == NSNotFound) {
                return [self custom_becomeFirstResponder];
            }

            // חסימה אך ורק במסך הראשי של רשימת השיחות (החיפוש הגלובלי)
            if ([vcName rangeOfString:@"ChatList" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                return NO; // מונע עליית מקלדת בחיפוש הראשי בלבד
            }
        }
    }

    // בכל שאר חלקי האפליקציה (כניסה, הודעות, תזמונים, שיתופים) המקלדת תעלה כרגיל
    return [self custom_becomeFirstResponder];
}

@end

__attribute__((constructor)) static void initGlobalSearchFilter(void) {
    Class class = [UIResponder class];
    SEL origSEL = @selector(becomeFirstResponder);
    SEL swizSEL = @selector(custom_becomeFirstResponder);

    Method origMethod = class_getInstanceMethod(class, origSEL);
    Method swizMethod = class_getInstanceMethod(class, swizSEL);

    if (origMethod && swizMethod) {
        method_exchangeImplementations(origMethod, swizMethod);
    }
}
