// LUBV Ultimate - Enhanced Edition
// For Among Us

#import <substrate.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

// ============================================================
// SETTINGS MANAGER
// ============================================================

@interface LUBVSettings : NSObject
@property (nonatomic, assign) BOOL alwaysImpostor;
@property (nonatomic, assign) BOOL noKillCooldown;
@property (nonatomic, assign) BOOL alwaysCanKill;
@property (nonatomic, assign) BOOL alwaysCanVent;
@property (nonatomic, assign) BOOL alwaysCanSabotage;
@property (nonatomic, assign) BOOL alwaysCanReport;
@property (nonatomic, assign) BOOL espEnabled;
@property (nonatomic, assign) BOOL godMode;
@property (nonatomic, assign) BOOL noVentCooldown;
@property (nonatomic, assign) BOOL fastSpeed;
@property (nonatomic, assign) BOOL showGUI;
@property (nonatomic, assign) BOOL wallhack;
@property (nonatomic, assign) BOOL instantTasks;
@property (nonatomic, assign) BOOL unlimitedVision;
@property (nonatomic, assign) BOOL seeGhosts;
+ (instancetype)sharedInstance;
@end

@implementation LUBVSettings

+ (instancetype)sharedInstance {
    static LUBVSettings *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LUBVSettings alloc] init];
        instance.alwaysImpostor = YES;
        instance.noKillCooldown = YES;
        instance.alwaysCanKill = YES;
        instance.alwaysCanVent = YES;
        instance.alwaysCanSabotage = YES;
        instance.alwaysCanReport = YES;
        instance.espEnabled = YES;
        instance.godMode = NO;
        instance.noVentCooldown = YES;
        instance.fastSpeed = NO;
        instance.showGUI = YES;
        instance.wallhack = YES;
        instance.instantTasks = NO;
        instance.unlimitedVision = YES;
        instance.seeGhosts = YES;
    });
    return instance;
}

@end

// ============================================================
// BEAUTIFUL GUI BUTTON - Glassmorphism Style
// ============================================================

@interface LUBVGUIButton : UIButton
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) BOOL isMenuOpen;
@property (nonatomic, strong) NSMutableDictionary *switches;
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) CAShapeLayer *gradientLayer;
@property (nonatomic, strong) UIView *handleBar;
@property (nonatomic, strong) UILabel *statusLabel;
@end

@implementation LUBVGUIButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Modern glass button
        self.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = 30;
        self.layer.masksToBounds = YES;
        
        // Glass effect
        UIVisualEffectView *glassView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
        glassView.frame = self.bounds;
        glassView.layer.cornerRadius = 30;
        glassView.layer.masksToBounds = YES;
        glassView.alpha = 0.85;
        [self addSubview:glassView];
        
        // Gradient border
        CAGradientLayer *borderLayer = [CAGradientLayer layer];
        borderLayer.frame = self.bounds;
        borderLayer.colors = @[
            (id)[UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:0.6].CGColor,
            (id)[UIColor colorWithRed:0.8 green:0.2 blue:1.0 alpha:0.6].CGColor
        ];
        borderLayer.startPoint = CGPointMake(0, 0);
        borderLayer.endPoint = CGPointMake(1, 1);
        borderLayer.cornerRadius = 30;
        [self.layer addSublayer:borderLayer];
        
        // Icon
        UILabel *iconLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        iconLabel.text = @"⚡";
        iconLabel.textAlignment = NSTextAlignmentCenter;
        iconLabel.font = [UIFont systemFontOfSize:30];
        [self addSubview:iconLabel];
        
        // Shadow
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 4);
        self.layer.shadowRadius = 15;
        self.layer.shadowOpacity = 0.3;
        
        self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:self.panGesture];
        [self addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
        
        self.isMenuOpen = NO;
        self.switches = [NSMutableDictionary dictionary];
        [self createMenu];
    }
    return self;
}

- (void)createMenu {
    // Modern menu with blur
    self.menuView = [[UIView alloc] initWithFrame:CGRectMake(-280, -400, 320, 480)];
    self.menuView.backgroundColor = [UIColor clearColor];
    self.menuView.layer.cornerRadius = 25;
    self.menuView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.menuView.layer.shadowOffset = CGSizeMake(0, 10);
    self.menuView.layer.shadowRadius = 30;
    self.menuView.layer.shadowOpacity = 0.5;
    self.menuView.hidden = YES;
    self.menuView.alpha = 0;
    [self addSubview:self.menuView];
    
    // Blur background
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    self.blurView.frame = self.menuView.bounds;
    self.blurView.layer.cornerRadius = 25;
    self.blurView.layer.masksToBounds = YES;
    [self.menuView addSubview:self.blurView];
    
    // Gradient overlay
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.menuView.bounds;
    gradient.colors = @[
        (id)[UIColor colorWithRed:0.2 green:0.0 blue:0.4 alpha:0.3].CGColor,
        (id)[UIColor colorWithRed:0.0 green:0.4 blue:0.8 alpha:0.1].CGColor
    ];
    gradient.cornerRadius = 25;
    [self.menuView.layer addSublayer:gradient];
    
    // Handle bar
    self.handleBar = [[UIView alloc] initWithFrame:CGRectMake(140, 12, 40, 4)];
    self.handleBar.backgroundColor = [UIColor colorWithWhite:0.6 alpha:0.5];
    self.handleBar.layer.cornerRadius = 2;
    [self.menuView addSubview:self.handleBar];
    
    // Title
    UIView *titleBar = [[UIView alloc] initWithFrame:CGRectMake(0, 20, 320, 50)];
    titleBar.backgroundColor = [UIColor clearColor];
    [self.menuView addSubview:titleBar];
    
    // Animated title with gradient
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(40, 0, 200, 40)];
    title.text = @"✦ LUBV CONTROLS ✦";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:20];
    title.textAlignment = NSTextAlignmentCenter;
    [titleBar addSubview:title];
    
    // Glow effect on title
    title.layer.shadowColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:0.5].CGColor;
    title.layer.shadowRadius = 10;
    title.layer.shadowOpacity = 0.5;
    
    // Close button with animation
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(270, 8, 40, 40);
    closeBtn.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.3];
    closeBtn.layer.cornerRadius = 20;
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [closeBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [titleBar addSubview:closeBtn];
    
    // Scroll view for features
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, 75, 300, 390)];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.backgroundColor = [UIColor clearColor];
    [self.menuView addSubview:self.scrollView];
    
    // Features with categories
    NSArray *categories = @[
        @"🎯 IMPOSTOR", @"💀 COMBAT", @"👁️ VISION", @"⚡ UTILITY"
    ];
    
    NSArray *features = @[
        // Impostor
        @[@"Always Impostor", @"alwaysImpostor"],
        // Combat
        @[@"No Kill Cooldown", @"noKillCooldown"],
        @[@"Always Can Kill", @"alwaysCanKill"],
        @[@"Always Can Vent", @"alwaysCanVent"],
        @[@"No Vent Cooldown", @"noVentCooldown"],
        @[@"Always Can Sabotage", @"alwaysCanSabotage"],
        // Vision
        @[@"ESP Outline", @"espEnabled"],
        @[@"Wallhack", @"wallhack"],
        @[@"Unlimited Vision", @"unlimitedVision"],
        @[@"See Ghosts", @"seeGhosts"],
        // Utility
        @[@"God Mode", @"godMode"],
        @[@"Fast Speed", @"fastSpeed"],
        @[@"Instant Tasks", @"instantTasks"],
        @[@"Always Can Report", @"alwaysCanReport"]
    ];
    
    int yPos = 0;
    int categoryIndex = 0;
    
    for (int i = 0; i < features.count; i++) {
        // Add category headers
        if (i == 0 || i == 2 || i == 6 || i == 10) {
            if (i > 0) {
                // Separator
                UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(20, yPos, 260, 1)];
                separator.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.3];
                [self.scrollView addSubview:separator];
                yPos += 15;
            }
            
            UILabel *categoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, yPos, 260, 25)];
            categoryLabel.text = categories[categoryIndex];
            categoryLabel.textColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:0.8];
            categoryLabel.font = [UIFont boldSystemFontOfSize:13];
            categoryLabel.textAlignment = NSTextAlignmentCenter;
            categoryLabel.layer.cornerRadius = 5;
            categoryLabel.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.3];
            [self.scrollView addSubview:categoryLabel];
            yPos += 30;
            categoryIndex++;
        }
        
        NSArray *feature = features[i];
        NSString *featureName = feature[0];
        NSString *key = feature[1];
        
        // Modern toggle row
        UIView *rowView = [[UIView alloc] initWithFrame:CGRectMake(5, yPos, 290, 44)];
        rowView.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.4];
        rowView.layer.cornerRadius = 12;
        rowView.layer.borderWidth = 0.5;
        rowView.layer.borderColor = [UIColor colorWithWhite:0.3 alpha:0.3].CGColor;
        [self.scrollView addSubview:rowView];
        
        // Feature icon
        UILabel *iconLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 10, 20, 24)];
        iconLabel.text = [self getIconForFeature:featureName];
        iconLabel.font = [UIFont systemFontOfSize:16];
        [rowView addSubview:iconLabel];
        
        // Feature name
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(40, 10, 160, 24)];
        label.text = featureName;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:14];
        [rowView addSubview:label];
        
        // Custom toggle switch
        UISwitch *switchControl = [[UISwitch alloc] initWithFrame:CGRectMake(220, 6, 50, 30)];
        switchControl.tag = i;
        switchControl.onTintColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
        switchControl.tintColor = [UIColor colorWithWhite:0.3 alpha:0.5];
        [switchControl addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
        
        LUBVSettings *settings = [LUBVSettings sharedInstance];
        BOOL isOn = [[settings valueForKey:key] boolValue];
        switchControl.on = isOn;
        
        [rowView addSubview:switchControl];
        [self.switches setObject:switchControl forKey:key];
        
        yPos += 52;
    }
    
    // Status label at bottom
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, yPos + 10, 280, 20)];
    self.statusLabel.text = @"LUBV v2.0 • Drag to move • Tap to toggle";
    self.statusLabel.textColor = [UIColor colorWithWhite:0.5 alpha:0.8];
    self.statusLabel.font = [UIFont systemFontOfSize:10];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    [self.scrollView addSubview:self.statusLabel];
    
    yPos += 40;
    self.scrollView.contentSize = CGSizeMake(300, yPos + 10);
}

- (NSString *)getIconForFeature:(NSString *)feature {
    NSDictionary *icons = @{
        @"Always Impostor": @"🎭",
        @"No Kill Cooldown": @"⏱️",
        @"Always Can Kill": @"🗡️",
        @"Always Can Vent": @"💨",
        @"No Vent Cooldown": @"🌀",
        @"Always Can Sabotage": @"⚡",
        @"Always Can Report": @"📢",
        @"ESP Outline": @"👁️",
        @"Wallhack": @"🧱",
        @"Unlimited Vision": @"🔭",
        @"See Ghosts": @"👻",
        @"God Mode": @"🛡️",
        @"Fast Speed": @"🏃",
        @"Instant Tasks": @"⚡"
    };
    return icons[feature] ?: @"•";
}

- (void)switchToggled:(UISwitch *)sender {
    LUBVSettings *settings = [LUBVSettings sharedInstance];
    NSArray *keys = @[
        @"alwaysImpostor", @"noKillCooldown", @"alwaysCanKill",
        @"alwaysCanVent", @"noVentCooldown", @"alwaysCanSabotage",
        @"alwaysCanReport", @"espEnabled", @"wallhack",
        @"unlimitedVision", @"seeGhosts", @"godMode",
        @"fastSpeed", @"instantTasks"
    ];
    
    NSString *key = keys[sender.tag];
    [settings setValue:@(sender.on) forKey:key];
    
    // Apply changes immediately
    [self applyFeature:key enabled:sender.on];
    
    // Show toast notification
    [self showToast:[NSString stringWithFormat:@"%@ %@", key, sender.on ? @"✓ ON" : @"✕ OFF"]];
}

- (void)applyFeature:(NSString *)key enabled:(BOOL)enabled {
    // Immediately apply ESP/wallhack changes
    if ([key isEqualToString:@"espEnabled"] || [key isEqualToString:@"wallhack"]) {
        [self refreshESP];
    }
    
    // Apply vent cooldown changes
    if ([key isEqualToString:@"noVentCooldown"]) {
        [self refreshVentCooldown];
    }
}

- (void)refreshESP {
    // Force update ESP on all players
    Class playerClass = NSClassFromString(@"PlayerControl");
    if (playerClass) {
        // Get all players and refresh their outline
        id localPlayer = [playerClass performSelector:@selector(localPlayer)];
        if (localPlayer) {
            // Force outline refresh
            SEL refreshSel = NSSelectorFromString(@"refreshOutline");
            if ([localPlayer respondsToSelector:refreshSel]) {
                [localPlayer performSelector:refreshSel];
            }
        }
    }
}

- (void)refreshVentCooldown {
    // Reset vent cooldown for all players
    Class ventClass = NSClassFromString(@"Vent");
    if (ventClass) {
        // Get all vents and reset cooldown
        id allVents = [ventClass performSelector:@selector(allVents)];
        if (allVents && [allVents respondsToSelector:@selector(makeObjectsPerformSelector:)]) {
            [allVents makeObjectsPerformSelector:NSSelectorFromString(@"resetCooldown")];
        }
    }
}

- (void)showToast:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Get key window
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        if (!keyWindow) {
            keyWindow = [UIApplication sharedApplication].windows.firstObject;
        }
        
        // Create toast view
        UIView *toastView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
        toastView.center = CGPointMake(keyWindow.bounds.size.width / 2, 100);
        toastView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.9];
        toastView.layer.cornerRadius = 20;
        toastView.layer.shadowColor = [UIColor blackColor].CGColor;
        toastView.layer.shadowOffset = CGSizeMake(0, 4);
        toastView.layer.shadowRadius = 12;
        toastView.layer.shadowOpacity = 0.5;
        toastView.alpha = 0;
        [keyWindow addSubview:toastView];
        
        // Label
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 180, 40)];
        label.text = message;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:14];
        label.textAlignment = NSTextAlignmentCenter;
        [toastView addSubview:label];
        
        // Animate in
        [UIView animateWithDuration:0.3 animations:^{
            toastView.alpha = 1;
        } completion:^(BOOL finished) {
            // Animate out
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.3 animations:^{
                    toastView.alpha = 0;
                } completion:^(BOOL finished) {
                    [toastView removeFromSuperview];
                }];
            });
        }];
    });
}

- (void)toggleMenu {
    self.isMenuOpen = !self.isMenuOpen;
    
    if (self.isMenuOpen) {
        self.menuView.hidden = NO;
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.6 options:0 animations:^{
            self.menuView.alpha = 1.0;
            self.menuView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        } completion:nil];
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            self.menuView.alpha = 0.0;
            self.menuView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        } completion:^(BOOL finished) {
            self.menuView.hidden = YES;
        }];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.superview];
    CGPoint newCenter = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    newCenter.x = MAX(40, MIN(screenBounds.size.width - 40, newCenter.x));
    newCenter.y = MAX(40, MIN(screenBounds.size.height - 40, newCenter.y));
    
    self.center = newCenter;
    [gesture setTranslation:CGPointZero inView:self.superview];
}

@end

// ============================================================
// INJECT GUI
// ============================================================

static LUBVGUIButton *guiButton = nil;
static BOOL guiVisible = YES;

__attribute__((constructor)) static void initialize() {
    NSLog(@"========================================");
    NSLog(@"LUBV ULTIMATE v2.0 Loaded!");
    NSLog(@"========================================");
    NSLog(@"Drag ⚡ button anywhere");
    NSLog(@"Tap ⚡ to open/close menu");
    NSLog(@"All features apply instantly");
    NSLog(@"========================================");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        if (!keyWindow) {
            keyWindow = [UIApplication sharedApplication].windows.firstObject;
        }
        
        guiButton = [[LUBVGUIButton alloc] initWithFrame:CGRectMake(20, 120, 60, 60)];
        [keyWindow addSubview:guiButton];
    });
}

// ============================================================
// HOOKS - ESP & WALLHACK
// ============================================================

// Hook PlayerControl for ESP
%hook PlayerControl

// ESP Outline
- (void)setOutline:(id)outline {
    %orig;
    if ([LUBVSettings sharedInstance].espEnabled) {
        // Make outline bright and colorful
        if ([outline respondsToSelector:@selector(setColor:)]) {
            [outline setColor:[UIColor colorWithRed:0.0 green:1.0 blue:0.5 alpha:0.9]];
        }
    }
}

// Wallhack - See through walls
- (void)setVisible:(BOOL)visible {
    if ([LUBVSettings sharedInstance].wallhack) {
        %orig(YES);
    } else {
        %orig;
    }
}

// Unlimited Vision
- (float)GetVisionRadius {
    if ([LUBVSettings sharedInstance].unlimitedVision) {
        return 999.0f;
    }
    return %orig;
}

// See Ghosts
- (BOOL)IsGhost {
    if ([LUBVSettings sharedInstance].seeGhosts) {
        return NO;
    }
    return %orig;
}

// No Kill Cooldown
- (float)GetKillCooldown {
    if ([LUBVSettings sharedInstance].noKillCooldown) {
        return 0.0f;
    }
    return %orig;
}

// God Mode
- (void)SetKilled:(id)player {
    if ([LUBVSettings sharedInstance].godMode) {
        return;
    }
    %orig;
}

// Fast Speed
- (float)GetSpeed {
    if ([LUBVSettings sharedInstance].fastSpeed) {
        return 5.0f;
    }
    return %orig;
}

// Instant Tasks
- (void)CompleteTask:(id)task {
    if ([LUBVSettings sharedInstance].instantTasks) {
        [task setValue:@(1.0) forKey:@"progress"];
    }
    %orig;
}

%end

// ============================================================
// HOOKS - VENT COOLDOWN
// ============================================================

%hook Vent

- (float)GetCooldown {
    if ([LUBVSettings sharedInstance].noVentCooldown) {
        return 0.0f;
    }
    return %orig;
}

- (BOOL)CanUse {
    if ([LUBVSettings sharedInstance].alwaysCanVent) {
        return YES;
    }
    return %orig;
}

%end

// ============================================================
// HOOKS - SABOTAGE
// ============================================================

%hook SabotageManager

- (BOOL)CanSabotage {
    if ([LUBVSettings sharedInstance].alwaysCanSabotage) {
        return YES;
    }
    return %orig;
}

%end

// ============================================================
// HOOKS - REPORT
// ============================================================

%hook MeetingHud

- (BOOL)CanReport {
    if ([LUBVSettings sharedInstance].alwaysCanReport) {
        return YES;
    }
    return %orig;
}

%end

// ============================================================
// HOOKS - IMPOSTOR
// ============================================================

%hook GameData

- (BOOL)IsImpostor:(id)player {
    if ([LUBVSettings sharedInstance].alwaysImpostor) {
        return YES;
    }
    return %orig;
}

%end

// ============================================================
// HOOKS - KILL
// ============================================================

%hook KillButtonManager

- (BOOL)CanKill {
    if ([LUBVSettings sharedInstance].alwaysCanKill) {
        return YES;
    }
    return %orig;
}

%end
