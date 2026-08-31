// LUBV Ultimate - Complete Edition with Fixed GUI
// Fully Working with All Features

#import <substrate.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

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
@property (nonatomic, assign) BOOL godMode;
@property (nonatomic, assign) BOOL noVentCooldown;
@property (nonatomic, assign) BOOL fastSpeed;
@property (nonatomic, assign) BOOL unlimitedVision;
@property (nonatomic, assign) BOOL seeGhosts;
@property (nonatomic, assign) BOOL unlimitedEmergencies;
@property (nonatomic, assign) BOOL noClip;
@property (nonatomic, assign) float playerSpeed;
@property (nonatomic, assign) BOOL noPhantomCooldown;
@property (nonatomic, assign) BOOL noShapeshifterCooldown;
@property (nonatomic, assign) BOOL noEngineerCooldown;
@property (nonatomic, assign) BOOL noDetectiveCooldown;
@property (nonatomic, assign) BOOL noTrackerCooldown;
@property (nonatomic, assign) BOOL noGuardianAngelCooldown;
@property (nonatomic, assign) BOOL unlockAllIAP;
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
        instance.godMode = NO;
        instance.noVentCooldown = YES;
        instance.fastSpeed = NO;
        instance.unlimitedVision = YES;
        instance.seeGhosts = YES;
        instance.unlimitedEmergencies = NO;
        instance.noClip = NO;
        instance.playerSpeed = 1.5;
        instance.noPhantomCooldown = NO;
        instance.noShapeshifterCooldown = NO;
        instance.noEngineerCooldown = NO;
        instance.noDetectiveCooldown = NO;
        instance.noTrackerCooldown = NO;
        instance.noGuardianAngelCooldown = NO;
        instance.unlockAllIAP = NO;
    });
    return instance;
}

@end

// ============================================================
// GUI BUTTON
// ============================================================

@interface LUBVGUIButton : UIButton
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) BOOL isMenuOpen;
@property (nonatomic, strong) NSMutableDictionary *switches;
@property (nonatomic, strong) UISlider *speedSlider;
@property (nonatomic, strong) UILabel *speedLabel;
@property (nonatomic, strong) UIWindow *parentWindow;
@end

@implementation LUBVGUIButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // FIX: Make button visible with solid background initially
        self.backgroundColor = [UIColor colorWithRed:0.1 green:0.6 blue:1.0 alpha:0.9];
        self.layer.cornerRadius = 30;
        self.layer.masksToBounds = YES;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 4);
        self.layer.shadowRadius = 15;
        self.layer.shadowOpacity = 0.5;
        
        // Icon
        UILabel *iconLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        iconLabel.text = @"⚡";
        iconLabel.textAlignment = NSTextAlignmentCenter;
        iconLabel.font = [UIFont systemFontOfSize:30];
        iconLabel.textColor = [UIColor whiteColor];
        [self addSubview:iconLabel];
        
        // FIX: Add tap gesture directly
        [self addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
        
        // FIX: Add pan gesture
        self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:self.panGesture];
        
        self.isMenuOpen = NO;
        self.switches = [NSMutableDictionary dictionary];
        
        // FIX: Create menu after window is available
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self createMenu];
        });
    }
    return self;
}

- (void)createMenu {
    // FIX: Position menu relative to button
    CGRect buttonFrame = self.frame;
    CGFloat menuX = buttonFrame.origin.x - 160;
    CGFloat menuY = buttonFrame.origin.y - 260;
    
    // Make sure menu stays within screen bounds
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    menuX = MAX(10, MIN(menuX, screenBounds.size.width - 370));
    menuY = MAX(10, MIN(menuY, screenBounds.size.height - 600));
    
    self.menuView = [[UIView alloc] initWithFrame:CGRectMake(menuX, menuY, 360, 580)];
    self.menuView.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.1 alpha:0.95];
    self.menuView.layer.cornerRadius = 25;
    self.menuView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.menuView.layer.shadowOffset = CGSizeMake(0, 10);
    self.menuView.layer.shadowRadius = 30;
    self.menuView.layer.shadowOpacity = 0.8;
    self.menuView.hidden = YES;
    self.menuView.alpha = 0;
    self.menuView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    [self.superview addSubview:self.menuView];
    
    // Title bar
    UIView *titleBar = [[UIView alloc] initWithFrame:CGRectMake(0, 10, 360, 50)];
    titleBar.backgroundColor = [UIColor clearColor];
    [self.menuView addSubview:titleBar];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(60, 0, 240, 40)];
    title.text = @"✦ LUBV ULTIMATE ✦";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:22];
    title.textAlignment = NSTextAlignmentCenter;
    [titleBar addSubview:title];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(310, 10, 35, 35);
    closeBtn.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
    closeBtn.layer.cornerRadius = 17.5;
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [closeBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [titleBar addSubview:closeBtn];
    
    // Scroll view
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, 65, 340, 500)];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.backgroundColor = [UIColor clearColor];
    [self.menuView addSubview:self.scrollView];
    
    // Features
    NSArray *features = @[
        @"🎭 Always Impostor",
        @"⏱️ No Kill Cooldown",
        @"🗡️ Always Can Kill",
        @"💨 Always Can Vent",
        @"🌀 No Vent Cooldown",
        @"⚡ Always Can Sabotage",
        @"📢 Always Can Report",
        @"🔭 Unlimited Vision",
        @"👻 See Ghosts",
        @"🛡️ God Mode",
        @"🏃 Fast Speed",
        @"📞 Unlimited Emergencies",
        @"🚶 No Clip (Walk Walls)",
        @"👻 No Phantom Cooldown",
        @"🔄 No Shapeshifter CD",
        @"🔧 No Engineer CD",
        @"🔍 No Detective CD",
        @"📍 No Tracker CD",
        @"😇 No Guardian Angel CD",
        @"🎁 Unlock All IAP"
    ];
    
    NSArray *keys = @[
        @"alwaysImpostor", @"noKillCooldown", @"alwaysCanKill",
        @"alwaysCanVent", @"noVentCooldown", @"alwaysCanSabotage",
        @"alwaysCanReport", @"unlimitedVision", @"seeGhosts",
        @"godMode", @"fastSpeed", @"unlimitedEmergencies",
        @"noClip", @"noPhantomCooldown", @"noShapeshifterCooldown",
        @"noEngineerCooldown", @"noDetectiveCooldown",
        @"noTrackerCooldown", @"noGuardianAngelCooldown",
        @"unlockAllIAP"
    ];
    
    int yPos = 0;
    
    for (int i = 0; i < features.count; i++) {
        // Row view
        UIView *rowView = [[UIView alloc] initWithFrame:CGRectMake(5, yPos, 330, 44)];
        rowView.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.7];
        rowView.layer.cornerRadius = 12;
        rowView.layer.borderWidth = 0.5;
        rowView.layer.borderColor = [UIColor colorWithWhite:0.3 alpha:0.3].CGColor;
        [self.scrollView addSubview:rowView];
        
        // Feature name
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 200, 24)];
        label.text = features[i];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:13];
        [rowView addSubview:label];
        
        if ([keys[i] isEqualToString:@"fastSpeed"]) {
            // Speed slider
            self.speedSlider = [[UISlider alloc] initWithFrame:CGRectMake(220, 6, 100, 32)];
            self.speedSlider.minimumValue = 1.0;
            self.speedSlider.maximumValue = 5.0;
            self.speedSlider.value = [LUBVSettings sharedInstance].playerSpeed;
            self.speedSlider.tintColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
            [self.speedSlider addTarget:self action:@selector(speedChanged:) forControlEvents:UIControlEventValueChanged];
            [rowView addSubview:self.speedSlider];
            
            self.speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(300, 10, 25, 24)];
            self.speedLabel.text = [NSString stringWithFormat:@"%.1f", self.speedSlider.value];
            self.speedLabel.textColor = [UIColor whiteColor];
            self.speedLabel.font = [UIFont systemFontOfSize:12];
            [rowView addSubview:self.speedLabel];
        } else {
            // Toggle switch
            UISwitch *switchControl = [[UISwitch alloc] initWithFrame:CGRectMake(260, 6, 50, 30)];
            switchControl.tag = i;
            switchControl.onTintColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
            switchControl.tintColor = [UIColor colorWithWhite:0.3 alpha:0.5];
            [switchControl addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
            
            LUBVSettings *settings = [LUBVSettings sharedInstance];
            BOOL isOn = [[settings valueForKey:keys[i]] boolValue];
            switchControl.on = isOn;
            
            [rowView addSubview:switchControl];
            [self.switches setObject:switchControl forKey:keys[i]];
        }
        
        yPos += 52;
    }
    
    // Status label
    UILabel *statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, yPos + 10, 320, 20)];
    statusLabel.text = @"⚡ Drag to move • Tap to toggle";
    statusLabel.textColor = [UIColor colorWithWhite:0.5 alpha:0.8];
    statusLabel.font = [UIFont systemFontOfSize:10];
    statusLabel.textAlignment = NSTextAlignmentCenter;
    [self.scrollView addSubview:statusLabel];
    
    yPos += 40;
    self.scrollView.contentSize = CGSizeMake(340, yPos + 10);
}

- (void)speedChanged:(UISlider *)sender {
    LUBVSettings *settings = [LUBVSettings sharedInstance];
    settings.playerSpeed = sender.value;
    settings.fastSpeed = YES;
    self.speedLabel.text = [NSString stringWithFormat:@"%.1f", sender.value];
}

- (void)switchToggled:(UISwitch *)sender {
    LUBVSettings *settings = [LUBVSettings sharedInstance];
    NSArray *keys = @[
        @"alwaysImpostor", @"noKillCooldown", @"alwaysCanKill",
        @"alwaysCanVent", @"noVentCooldown", @"alwaysCanSabotage",
        @"alwaysCanReport", @"unlimitedVision", @"seeGhosts",
        @"godMode", @"fastSpeed", @"unlimitedEmergencies",
        @"noClip", @"noPhantomCooldown", @"noShapeshifterCooldown",
        @"noEngineerCooldown", @"noDetectiveCooldown",
        @"noTrackerCooldown", @"noGuardianAngelCooldown",
        @"unlockAllIAP"
    ];
    
    NSString *key = keys[sender.tag];
    [settings setValue:@(sender.on) forKey:key];
}

- (void)toggleMenu {
    self.isMenuOpen = !self.isMenuOpen;
    
    if (self.isMenuOpen) {
        self.menuView.hidden = NO;
        [self.superview bringSubviewToFront:self.menuView];
        [self.superview bringSubviewToFront:self];
        
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.6 options:0 animations:^{
            self.menuView.alpha = 1.0;
            self.menuView.transform = CGAffineTransformIdentity;
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
    
    // FIX: Update menu position when button moves
    if (self.menuView && !self.menuView.hidden) {
        CGRect buttonFrame = self.frame;
        CGFloat menuX = buttonFrame.origin.x - 160;
        CGFloat menuY = buttonFrame.origin.y - 260;
        
        menuX = MAX(10, MIN(menuX, screenBounds.size.width - 370));
        menuY = MAX(10, MIN(menuY, screenBounds.size.height - 600));
        
        [UIView animateWithDuration:0.2 animations:^{
            self.menuView.frame = CGRectMake(menuX, menuY, 360, 580);
        }];
    }
}

- (void)dealloc {
    if (self.menuView) {
        [self.menuView removeFromSuperview];
        self.menuView = nil;
    }
}

@end

// ============================================================
// INJECT GUI - FIXED
// ============================================================

static LUBVGUIButton *guiButton = nil;

__attribute__((constructor)) static void initialize() {
    NSLog(@"========================================");
    NSLog(@"⚡ LUBV ULTIMATE v3.0 Loaded!");
    NSLog(@"========================================");
    NSLog(@"Drag ⚡ button anywhere");
    NSLog(@"Tap ⚡ to open control panel");
    NSLog(@"========================================");
    
    // FIX: Wait for UI to be ready
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        if (!keyWindow) {
            keyWindow = [UIApplication sharedApplication].windows.firstObject;
        }
        
        if (!keyWindow) {
            // Create a new window if none exists
            keyWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            keyWindow.windowLevel = UIWindowLevelNormal;
            keyWindow.hidden = NO;
            [keyWindow makeKeyAndVisible];
        }
        
        if (keyWindow) {
            // FIX: Remove existing button if any
            if (guiButton) {
                [guiButton removeFromSuperview];
                guiButton = nil;
            }
            
            guiButton = [[LUBVGUIButton alloc] initWithFrame:CGRectMake(20, 120, 60, 60)];
            [keyWindow addSubview:guiButton];
            [keyWindow bringSubviewToFront:guiButton];
            
            NSLog(@"✅ LUBV GUI Button added to window");
        }
    });
}

// ============================================================
// HOOKS - ALL FEATURES
// ============================================================

// PlayerControl Hooks
%hook PlayerControl

- (BOOL)IsImpostor {
    if ([LUBVSettings sharedInstance].alwaysImpostor) {
        return YES;
    }
    return %orig;
}

- (float)GetKillCooldown {
    if ([LUBVSettings sharedInstance].noKillCooldown) {
        return 0.0f;
    }
    return %orig;
}

- (void)SetKilled:(id)player {
    if ([LUBVSettings sharedInstance].godMode) {
        return;
    }
    %orig;
}

- (float)GetSpeed {
    if ([LUBVSettings sharedInstance].fastSpeed) {
        return [LUBVSettings sharedInstance].playerSpeed;
    }
    return %orig;
}

- (float)GetVisionRadius {
    if ([LUBVSettings sharedInstance].unlimitedVision) {
        return 999.0f;
    }
    return %orig;
}

- (BOOL)IsGhost {
    if ([LUBVSettings sharedInstance].seeGhosts) {
        return NO;
    }
    return %orig;
}

- (BOOL)CanMove {
    if ([LUBVSettings sharedInstance].noClip) {
        return YES;
    }
    return %orig;
}

%end

// Vent Hooks
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

// SabotageManager Hooks
%hook SabotageManager

- (BOOL)CanSabotage {
    if ([LUBVSettings sharedInstance].alwaysCanSabotage) {
        return YES;
    }
    return %orig;
}

%end

// KillButtonManager Hooks
%hook KillButtonManager

- (BOOL)CanKill {
    if ([LUBVSettings sharedInstance].alwaysCanKill) {
        return YES;
    }
    return %orig;
}

%end

// MeetingHud Hooks
%hook MeetingHud

- (BOOL)CanReport {
    if ([LUBVSettings sharedInstance].alwaysCanReport) {
        return YES;
    }
    return %orig;
}

%end

// EmergencyButton Hooks
%hook EmergencyButton

- (int)GetRemainingUses {
    if ([LUBVSettings sharedInstance].unlimitedEmergencies) {
        return 99;
    }
    return %orig;
}

- (BOOL)CanUse {
    if ([LUBVSettings sharedInstance].unlimitedEmergencies) {
        return YES;
    }
    return %orig;
}

%end

// Role Cooldown Hooks
%hook PhantomRole

- (float)GetCooldown {
    if ([LUBVSettings sharedInstance].noPhantomCooldown) {
        return 0.0f;
    }
    return %orig;
}

%end

%hook ShapeshifterRole

- (float)GetCooldown {
    if ([LUBVSettings sharedInstance].noShapeshifterCooldown) {
        return 0.0f;
    }
    return %orig;
}

%end

%hook EngineerRole

- (float)GetCooldown {
    if ([LUBVSettings sharedInstance].noEngineerCooldown) {
        return 0.0f;
    }
    return %orig;
}

%end

%hook DetectiveRole

- (float)GetCooldown {
    if ([LUBVSettings sharedInstance].noDetectiveCooldown) {
        return 0.0f;
    }
    return %orig;
}

%end

%hook TrackerRole

- (float)GetCooldown {
    if ([LUBVSettings sharedInstance].noTrackerCooldown) {
        return 0.0f;
    }
    return %orig;
}

%end

%hook GuardianAngelRole

- (float)GetCooldown {
    if ([LUBVSettings sharedInstance].noGuardianAngelCooldown) {
        return 0.0f;
    }
    return %orig;
}

%end

// IAP Unlock Hooks
%hook HatManager

- (BOOL)IsHatUnlocked:(id)hat {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return YES;
    }
    return %orig;
}

%end

%hook PetManager

- (BOOL)IsPetUnlocked:(id)pet {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return YES;
    }
    return %orig;
}

%end

%hook SkinManager

- (BOOL)IsSkinUnlocked:(id)skin {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return YES;
    }
    return %orig;
}

%end

%hook VisorManager

- (BOOL)IsVisorUnlocked:(id)visor {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return YES;
    }
    return %orig;
}

%end

%hook NamePlateManager

- (BOOL)IsNamePlateUnlocked:(id)nameplate {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return YES;
    }
    return %orig;
}

%end