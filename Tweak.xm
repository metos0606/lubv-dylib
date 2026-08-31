//
//  Tweak.xm
//  Among Us iOS Cheat (FINAL - ACTUALLY CLEAN)
//  
//  Features:
//  - Always Impostor
//  - All Cosmetics Unlocked
//  - ESP (Player positions, roles, names)
//  - Auto Win
//  - Anti-Ban features
//  - Simple settings menu with toggles
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>
#import <sys/mman.h>

// ============================================================
// MARK: - Configuration
// ============================================================

static BOOL g_alwaysImpostor = YES;
static BOOL g_unlockAllCosmetics = YES;
static BOOL g_espEnabled = YES;
static BOOL g_autoWinEnabled = NO;
static BOOL g_showAllPlayers = YES;
static BOOL g_noBanMode = YES;

// ============================================================
// MARK: - GLOBAL ESP OVERLAY
// ============================================================

static void *g_espOverlay = nil;

// ============================================================
// MARK: - FORWARD DECLARATIONS
// ============================================================

static void updateESP(void);
static BOOL hooked_CanMakePurchases(id self, SEL sel);
static id hooked_GetProductInfo(id self, SEL sel, id productId);
static void hooked_OnPlayerSpawn(id self, SEL sel, id player);
static void showSettingsMenu(void);
static void handleTripleTap(UIGestureRecognizer *gesture);

// ============================================================
// MARK: - Memory Protection Helper
// ============================================================

static void enable_writing(void *ptr, size_t size) {
    uintptr_t page = (uintptr_t)ptr & ~(uintptr_t)(PAGE_SIZE - 1);
    mprotect((void *)page, size + ((uintptr_t)ptr - page), PROT_READ | PROT_WRITE | PROT_EXEC);
}

// ============================================================
// MARK: - Game State Tracking
// ============================================================

typedef struct {
    BOOL inGame;
    BOOL isImpostor;
    int myPlayerId;
    int playerCount;
    void *gameManager;
    void *shipStatus;
} GameState;

static GameState g_gameState = {0};

// ============================================================
// MARK: - Class Definitions for Runtime Hooking
// ============================================================

@interface PlayerControl : NSObject
@property (nonatomic, assign) int PlayerId;
@property (nonatomic, assign) BOOL IsImpostor;
@property (nonatomic, assign) BOOL IsDead;
@property (nonatomic, assign) BOOL IsDisconnected;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) int colorId;
@property (nonatomic, assign) void *myPhysics;
@end

@interface GameData : NSObject
@property (nonatomic, strong) NSArray *AllPlayers;
@property (nonatomic, assign) int TotalTasks;
@property (nonatomic, assign) int CompletedTasks;
+ (GameData *)Instance;
- (PlayerControl *)GetPlayerById:(int)playerId;
@end

@interface ShipStatus : NSObject
@property (nonatomic, assign) int MapId;
@property (nonatomic, assign) int NumImpostors;
@property (nonatomic, assign) int MaxPlayers;
@property (nonatomic, assign) BOOL GameEnded;
+ (ShipStatus *)Instance;
@end

@interface MeetingHud : NSObject
@property (nonatomic, assign) int state;
@property (nonatomic, strong) NSArray *playerStates;
- (void)Close;
- (void)SkipVote;
@end

@interface InnerNetClient : NSObject
- (void)SendRpc;
@property (nonatomic, assign) int ClientId;
+ (InnerNetClient *)Instance;
@end

// ============================================================
// MARK: - Settings Menu GUI
// ============================================================

@interface CheatSettingsViewController : UIViewController {
    NSMutableDictionary *toggles;
    UILabel *statusLabel;
}
@end

@implementation CheatSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    toggles = [NSMutableDictionary dictionary];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.95];
    self.title = @"Cheat Menu";
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    
    UIBarButtonItem *closeBtn = [[UIBarButtonItem alloc] initWithTitle:@"✕" 
                                                                 style:UIBarButtonItemStylePlain 
                                                                target:self 
                                                                action:@selector(closeTapped)];
    closeBtn.tintColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem = closeBtn;
    
    UIBarButtonItem *applyBtn = [[UIBarButtonItem alloc] initWithTitle:@"Apply" 
                                                                 style:UIBarButtonItemStyleDone 
                                                                target:self 
                                                                action:@selector(applyTapped)];
    applyBtn.tintColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.4 alpha:1.0];
    self.navigationItem.rightBarButtonItem = applyBtn;
    
    [self setupUI];
}

- (void)setupUI {
    CGFloat screenWidth = self.view.bounds.size.width;
    CGFloat padding = 20;
    CGFloat innerY = padding;
    CGFloat contentWidth = screenWidth - (padding * 2);
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.backgroundColor = [UIColor clearColor];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:scrollView];
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(padding, 0, contentWidth, 0)];
    contentView.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    contentView.layer.cornerRadius = 16;
    contentView.layer.masksToBounds = YES;
    [scrollView addSubview:contentView];
    
    // Title
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, innerY, contentWidth - (padding * 2), 30)];
    titleLabel.text = @"⚙️ Cheat Settings";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:22];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [contentView addSubview:titleLabel];
    innerY += 40;
    
    // Status
    statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, innerY, contentWidth - (padding * 2), 20)];
    statusLabel.text = @"Status: Ready";
    statusLabel.textColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.4 alpha:1.0];
    statusLabel.font = [UIFont systemFontOfSize:14];
    statusLabel.textAlignment = NSTextAlignmentCenter;
    [contentView addSubview:statusLabel];
    innerY += 30;
    
    // Separator
    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(padding, innerY, contentWidth - (padding * 2), 1)];
    sep.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    [contentView addSubview:sep];
    innerY += 20;
    
    // Toggle helpers - store toggles in dictionary with keys
    innerY += [self createToggleWithKey:@"impostor" title:@"🔴 Always Impostor" 
                               subtitle:@"You will always be the Impostor"
                                default:g_alwaysImpostor
                                    atY:innerY width:contentWidth - (padding * 2)];
    innerY += 10;
    
    innerY += [self createToggleWithKey:@"cosmetics" title:@"👗 Unlock Cosmetics" 
                               subtitle:@"All hats, skins, pets, visors"
                                default:g_unlockAllCosmetics
                                    atY:innerY width:contentWidth - (padding * 2)];
    innerY += 10;
    
    innerY += [self createToggleWithKey:@"esp" title:@"👁️ ESP" 
                               subtitle:@"Show player positions, roles"
                                default:g_espEnabled
                                    atY:innerY width:contentWidth - (padding * 2)];
    innerY += 10;
    
    innerY += [self createToggleWithKey:@"autowin" title:@"🏆 Auto Win" 
                               subtitle:@"Instantly win as Impostor"
                                default:g_autoWinEnabled
                                    atY:innerY width:contentWidth - (padding * 2)];
    innerY += 10;
    
    innerY += [self createToggleWithKey:@"antiban" title:@"🛡️ Anti-Ban" 
                               subtitle:@"Bypass anti-cheat detection"
                                default:g_noBanMode
                                    atY:innerY width:contentWidth - (padding * 2)];
    innerY += 20;
    
    // Separator
    UIView *sep2 = [[UIView alloc] initWithFrame:CGRectMake(padding, innerY, contentWidth - (padding * 2), 1)];
    sep2.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    [contentView addSubview:sep2];
    innerY += 20;
    
    // Credits
    UILabel *creditsLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, innerY, contentWidth - (padding * 2), 20)];
    creditsLabel.text = @"Made with ❤️ for LO";
    creditsLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    creditsLabel.font = [UIFont systemFontOfSize:12];
    creditsLabel.textAlignment = NSTextAlignmentCenter;
    [contentView addSubview:creditsLabel];
    innerY += 30;
    
    contentView.frame = CGRectMake(padding, 20, contentWidth, innerY);
    scrollView.contentSize = CGSizeMake(screenWidth, innerY + 40);
}

- (CGFloat)createToggleWithKey:(NSString *)key title:(NSString *)title 
                      subtitle:(NSString *)subtitle default:(BOOL)defaultValue
                          atY:(CGFloat)y width:(CGFloat)width {
    
    UISwitch *toggle = [[UISwitch alloc] init];
    toggle.onTintColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.4 alpha:1.0];
    toggle.tintColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    toggle.on = defaultValue;
    
    CGFloat switchWidth = 51;
    toggle.frame = CGRectMake(width - switchWidth, y + 14, switchWidth, 31);
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, y + 4, width - switchWidth - 24, 22)];
    titleLabel.text = title;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    
    UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, y + 26, width - switchWidth - 24, 18)];
    subtitleLabel.text = subtitle;
    subtitleLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    subtitleLabel.font = [UIFont systemFontOfSize:12];
    
    UIView *wrapper = [[UIView alloc] initWithFrame:CGRectMake(0, y, width, 60)];
    wrapper.backgroundColor = [UIColor colorWithWhite:0.12 alpha:1.0];
    wrapper.layer.cornerRadius = 12;
    wrapper.layer.masksToBounds = YES;
    
    [wrapper addSubview:titleLabel];
    [wrapper addSubview:subtitleLabel];
    [wrapper addSubview:toggle];
    
    toggles[key] = toggle;
    
    // Add to the view hierarchy
    UIScrollView *scrollView = (UIScrollView *)self.view.subviews.firstObject;
    if ([scrollView isKindOfClass:[UIScrollView class]]) {
        UIView *cv = scrollView.subviews.firstObject;
        if (cv) {
            [cv addSubview:wrapper];
        }
    }
    
    return 70;
}

- (void)closeTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)applyTapped {
    UISwitch *impostorToggle = toggles[@"impostor"];
    UISwitch *cosmeticsToggle = toggles[@"cosmetics"];
    UISwitch *espToggle = toggles[@"esp"];
    UISwitch *autoWinToggle = toggles[@"autowin"];
    UISwitch *antiBanToggle = toggles[@"antiban"];
    
    if (impostorToggle) g_alwaysImpostor = impostorToggle.on;
    if (cosmeticsToggle) g_unlockAllCosmetics = cosmeticsToggle.on;
    if (espToggle) g_espEnabled = espToggle.on;
    if (autoWinToggle) g_autoWinEnabled = autoWinToggle.on;
    if (antiBanToggle) g_noBanMode = antiBanToggle.on;
    
    statusLabel.text = @"✅ Applied!";
    statusLabel.textColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.4 alpha:1.0];
    
    if (g_espOverlay) {
        UIView *overlay = (__bridge UIView *)g_espOverlay;
        overlay.hidden = !g_espEnabled;
        if (g_espEnabled) {
            updateESP();
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        statusLabel.text = @"Status: Ready";
    });
}

@end

// ============================================================
// MARK: - Show Settings Menu
// ============================================================

static void showSettingsMenu(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) {
            window = [[UIApplication sharedApplication].windows firstObject];
        }
        
        CheatSettingsViewController *vc = [[CheatSettingsViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        nav.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        UIViewController *rootVC = window.rootViewController;
        if (rootVC) {
            [rootVC presentViewController:nav animated:YES completion:nil];
        }
    });
}

static void handleTripleTap(UIGestureRecognizer *gesture) {
    showSettingsMenu();
}

// ============================================================
// MARK: - Hook Functions - Always Impostor
// ============================================================

static BOOL (*orig_PlayerControl_get_IsImpostor)(id self, SEL sel);
static BOOL hooked_PlayerControl_get_IsImpostor(id self, SEL sel) {
    if (g_alwaysImpostor) {
        PlayerControl *localPlayer = [objc_getClass("PlayerControl") performSelector:@selector(LocalPlayer)];
        if (localPlayer && self == localPlayer) {
            return YES;
        }
        if (orig_PlayerControl_get_IsImpostor) {
            return orig_PlayerControl_get_IsImpostor(self, sel);
        }
        return NO;
    }
    return orig_PlayerControl_get_IsImpostor ? orig_PlayerControl_get_IsImpostor(self, sel) : NO;
}

// ============================================================
// MARK: - Hook Functions - Unlock All Cosmetics
// ============================================================

@interface HatManager : NSObject
- (NSArray *)AllHats;
- (NSArray *)AllPets;
- (NSArray *)AllSkins;
- (NSArray *)AllVisors;
- (NSArray *)AllNamePlates;
+ (HatManager *)Instance;
@end

static BOOL (*orig_HasPurchased)(id self, SEL sel, id itemId);
static BOOL hooked_HasPurchased(id self, SEL sel, id itemId) {
    if (g_unlockAllCosmetics) {
        return YES;
    }
    return orig_HasPurchased ? orig_HasPurchased(self, sel, itemId) : NO;
}

static BOOL (*orig_IsAvailable)(id self, SEL sel);
static BOOL hooked_IsAvailable(id self, SEL sel) {
    if (g_unlockAllCosmetics) {
        return YES;
    }
    return orig_IsAvailable ? orig_IsAvailable(self, sel) : NO;
}

// ============================================================
// MARK: - ESP Rendering
// ============================================================

@interface ESPOverlay : UIView
@property (nonatomic, strong) NSMutableArray *playerLabels;
@end

@implementation ESPOverlay

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        self.playerLabels = [NSMutableArray array];
        self.hidden = !g_espEnabled;
        
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (window) {
            self.frame = window.bounds;
            [window addSubview:self];
            [window bringSubviewToFront:self];
        }
    }
    return self;
}

- (void)updateESP {
    if (!g_espEnabled) {
        self.hidden = YES;
        return;
    }
    self.hidden = NO;
    
    for (UILabel *label in self.playerLabels) {
        [label removeFromSuperview];
    }
    [self.playerLabels removeAllObjects];
    
    GameData *gameData = [objc_getClass("GameData") performSelector:@selector(Instance)];
    if (!gameData) return;
    
    NSArray *players = [gameData performSelector:@selector(AllPlayers)];
    if (!players) return;
    
    PlayerControl *localPlayer = [objc_getClass("PlayerControl") performSelector:@selector(LocalPlayer)];
    if (!localPlayer) return;
    
    int localId = [[localPlayer valueForKey:@"PlayerId"] intValue];
    
    for (id player in players) {
        BOOL isDead = [[player valueForKey:@"IsDead"] boolValue];
        BOOL isDisconnected = [[player valueForKey:@"IsDisconnected"] boolValue];
        if (!g_showAllPlayers && (isDead || isDisconnected)) continue;
        
        int playerId = [[player valueForKey:@"PlayerId"] intValue];
        if (playerId == localId) continue;
        
        NSString *playerName = [player valueForKey:@"name"];
        BOOL isImpostor = [[player valueForKey:@"IsImpostor"] boolValue];
        
        id playerPhysics = [player valueForKey:@"myPhysics"];
        if (!playerPhysics) continue;
        
        CGPoint position = [[playerPhysics valueForKey:@"position"] CGPointValue];
        
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        CGSize screenSize = window.bounds.size;
        
        float x = position.x / 100.0f * screenSize.width + screenSize.width/2;
        float y = screenSize.height - (position.y / 100.0f * screenSize.height + screenSize.height/2);
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(x - 50, y - 30, 100, 30)];
        label.text = [NSString stringWithFormat:@"%@ %@", playerName, isImpostor ? @"🔴" : @"🟢"];
        label.textColor = isImpostor ? [UIColor redColor] : [UIColor greenColor];
        label.font = [UIFont systemFontOfSize:12];
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        label.layer.cornerRadius = 4;
        label.clipsToBounds = YES;
        
        [self addSubview:label];
        [self.playerLabels addObject:label];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (window) {
        self.frame = window.bounds;
    }
}

@end

// ============================================================
// MARK: - ESP Update Timer
// ============================================================

static void updateESP(void) {
    if (g_espOverlay) {
        ESPOverlay *overlay = (__bridge ESPOverlay *)g_espOverlay;
        [overlay updateESP];
    }
}

// ============================================================
// MARK: - Hook Functions - Auto Win
// ============================================================

static void (*orig_CheckEndCriteria)(id self, SEL sel);
static void hooked_CheckEndCriteria(id self, SEL sel) {
    if (g_autoWinEnabled) {
        GameData *gameData = [objc_getClass("GameData") performSelector:@selector(Instance)];
        if (gameData) {
            NSArray *players = [gameData performSelector:@selector(AllPlayers)];
            if (players) {
                BOOL allDead = YES;
                for (id player in players) {
                    BOOL isDead = [[player valueForKey:@"IsDead"] boolValue];
                    if (!isDead) {
                        allDead = NO;
                        break;
                    }
                }
                if (allDead) {
                    return;
                }
            }
        }
        
        GameData *gd = [objc_getClass("GameData") performSelector:@selector(Instance)];
        NSArray *allPlayers = [gd performSelector:@selector(AllPlayers)];
        PlayerControl *localPlayer = [objc_getClass("PlayerControl") performSelector:@selector(LocalPlayer)];
        
        for (id player in allPlayers) {
            if (player != localPlayer) {
                BOOL isImpostor = [[player valueForKey:@"IsImpostor"] boolValue];
                if (!isImpostor) {
                    [player setValue:@YES forKey:@"IsDead"];
                    
                    SEL onMurderSel = NSSelectorFromString(@"OnMurder:isKiller:isVictim:isShapeShifted:shapeshiftTargetId:victimId:");
                    if ([localPlayer respondsToSelector:onMurderSel]) {
                        id playerId = [player valueForKey:@"PlayerId"];
                        ((void (*)(id, SEL, id, BOOL, BOOL, BOOL, int, int))objc_msgSend)(
                            localPlayer, onMurderSel, playerId, YES, NO, NO, 0, [playerId intValue]
                        );
                    }
                }
            }
        }
        
        ShipStatus *shipStatus = [objc_getClass("ShipStatus") performSelector:@selector(Instance)];
        if (shipStatus) {
            [shipStatus setValue:@YES forKey:@"GameEnded"];
        }
        return;
    }
    
    if (orig_CheckEndCriteria) {
        orig_CheckEndCriteria(self, sel);
    }
}

// ============================================================
// MARK: - Anti-Ban Features (ENHANCED)
// ============================================================

static BOOL (*orig_SystemIntegrityCheck)(id, SEL);
static BOOL hooked_SystemIntegrityCheck(id self, SEL sel) {
    if (g_noBanMode) {
        return YES;
    }
    return orig_SystemIntegrityCheck ? orig_SystemIntegrityCheck(self, sel) : YES;
}

static void (*orig_ValidatePacket_enhanced)(id, SEL, id);
static void hooked_ValidatePacket_enhanced(id self, SEL sel, id packet) {
    if (g_noBanMode && packet) {
        @try {
            if ([packet respondsToSelector:@selector(setCheatReported:)]) {
                [packet setValue:@NO forKey:@"cheatReported"];
            }
            if ([packet respondsToSelector:@selector(setDetected:)]) {
                [packet setValue:@NO forKey:@"detected"];
            }
            NSArray *keys = @[@"suspicious", @"flagged", @"invalid", @"hackDetected"];
            for (NSString *key in keys) {
                NSString *setter = [NSString stringWithFormat:@"set%@:", [key capitalizedString]];
                SEL setterSel = NSSelectorFromString(setter);
                if ([packet respondsToSelector:setterSel]) {
                    [packet setValue:@0 forKey:key];
                }
            }
        } @catch (NSException *e) {
            // Silent fail
        }
        return;
    }
    if (orig_ValidatePacket_enhanced) {
        orig_ValidatePacket_enhanced(self, sel, packet);
    }
}

static BOOL (*orig_IsBanned)(id, SEL);
static BOOL hooked_IsBanned(id self, SEL sel) {
    if (g_noBanMode) {
        return NO;
    }
    return orig_IsBanned ? orig_IsBanned(self, sel) : NO;
}

static void (*orig_SendHeartbeat)(id, SEL);
static void hooked_SendHeartbeat(id self, SEL sel) {
    if (g_noBanMode) {
        if (orig_SendHeartbeat) {
            orig_SendHeartbeat(self, sel);
        }
        return;
    }
    if (orig_SendHeartbeat) {
        orig_SendHeartbeat(self, sel);
    }
}

// ============================================================
// MARK: - Additional Hook Implementations
// ============================================================

static BOOL hooked_CanMakePurchases(id self, SEL sel) {
    if (g_unlockAllCosmetics) {
        return YES;
    }
    static BOOL (*orig_CanMakePurchases)(id, SEL);
    return orig_CanMakePurchases ? orig_CanMakePurchases(self, sel) : NO;
}

static id hooked_GetProductInfo(id self, SEL sel, id productId) {
    if (g_unlockAllCosmetics) {
        return nil;
    }
    static id (*orig_GetProductInfo)(id, SEL, id);
    return orig_GetProductInfo ? orig_GetProductInfo(self, sel, productId) : nil;
}

static void hooked_OnPlayerSpawn(id self, SEL sel, id player) {
    if (g_alwaysImpostor) {
        PlayerControl *localPlayer = [objc_getClass("PlayerControl") performSelector:@selector(LocalPlayer)];
        if (player == localPlayer) {
            [player setValue:@YES forKey:@"IsImpostor"];
            
            Class roleBehaviour = objc_getClass("RoleBehaviour");
            if (roleBehaviour) {
                id impostorRole = [roleBehaviour performSelector:@selector(ImpostorRole)];
                if (impostorRole) {
                    [player setValue:impostorRole forKey:@"role"];
                }
            }
        }
    }
    
    static void (*orig_OnPlayerSpawn)(id, SEL, id);
    if (orig_OnPlayerSpawn) {
        orig_OnPlayerSpawn(self, sel, player);
    }
}

// ============================================================
// MARK: - Injection Entry Point
// ============================================================

__attribute__((constructor))
static void init_cheat(void) {
    NSLog(@"[AmongUsCheat] Injecting...");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"[AmongUsCheat] Initializing cheat features...");
        
        Class playerControl = objc_getClass("PlayerControl");
        Class shipStatus = objc_getClass("ShipStatus");
        Class innerNetClient = objc_getClass("InnerNetClient");
        Class hatManager = objc_getClass("HatManager");
        
        if (!playerControl) {
            NSLog(@"[AmongUsCheat] PlayerControl class not found!");
            return;
        }
        
        // ============================================================
        // Hook PlayerControl - Always Impostor
        // ============================================================
        SEL isImpostorSel = NSSelectorFromString(@"IsImpostor");
        
        if (isImpostorSel) {
            Method origMethod = class_getInstanceMethod(playerControl, isImpostorSel);
            if (origMethod) {
                orig_PlayerControl_get_IsImpostor = (BOOL (*)(id, SEL))method_getImplementation(origMethod);
                class_replaceMethod(playerControl, isImpostorSel, (IMP)hooked_PlayerControl_get_IsImpostor, method_getTypeEncoding(origMethod));
                NSLog(@"[AmongUsCheat] Hooked IsImpostor");
            }
        }
        
        // ============================================================
        // Hook HatManager - Unlock All Cosmetics
        // ============================================================
        if (g_unlockAllCosmetics && hatManager) {
            SEL hasPurchasedSel = NSSelectorFromString(@"HasPurchased:");
            if (hasPurchasedSel) {
                Method origMethod = class_getInstanceMethod(hatManager, hasPurchasedSel);
                if (origMethod) {
                    orig_HasPurchased = (BOOL (*)(id, SEL, id))method_getImplementation(origMethod);
                    class_replaceMethod(hatManager, hasPurchasedSel, (IMP)hooked_HasPurchased, method_getTypeEncoding(origMethod));
                    NSLog(@"[AmongUsCheat] Hooked HasPurchased");
                }
            }
            
            SEL isAvailableSel = NSSelectorFromString(@"IsAvailable");
            if (isAvailableSel) {
                Method origMethod = class_getInstanceMethod(hatManager, isAvailableSel);
                if (origMethod) {
                    orig_IsAvailable = (BOOL (*)(id, SEL))method_getImplementation(origMethod);
                    class_replaceMethod(hatManager, isAvailableSel, (IMP)hooked_IsAvailable, method_getTypeEncoding(origMethod));
                    NSLog(@"[AmongUsCheat] Hooked IsAvailable");
                }
            }
        }
        
        // ============================================================
        // Hook ShipStatus - Auto Win
        // ============================================================
        if (g_autoWinEnabled && shipStatus) {
            SEL checkEndSel = NSSelectorFromString(@"CheckEndCriteria");
            if (checkEndSel) {
                Method origMethod = class_getInstanceMethod(shipStatus, checkEndSel);
                if (origMethod) {
                    orig_CheckEndCriteria = (void (*)(id, SEL))method_getImplementation(origMethod);
                    class_replaceMethod(shipStatus, checkEndSel, (IMP)hooked_CheckEndCriteria, method_getTypeEncoding(origMethod));
                    NSLog(@"[AmongUsCheat] Hooked CheckEndCriteria");
                }
            }
        }
        
        // ============================================================
        // Hook Anti-Cheat - Enhanced Anti-Ban
        // ============================================================
        if (g_noBanMode) {
            NSArray *antiCheatClasses = @[
                @"AntiCheatManager",
                @"SecurityManager",
                @"IntegrityChecker",
                @"CheatDetection",
                @"ServerValidator",
                @"BanManager"
            ];
            
            for (NSString *className in antiCheatClasses) {
                Class cls = objc_getClass([className UTF8String]);
                if (!cls) continue;
                
                SEL integritySel = NSSelectorFromString(@"VerifyIntegrity");
                if (integritySel) {
                    Method m = class_getInstanceMethod(cls, integritySel);
                    if (m) {
                        orig_SystemIntegrityCheck = (BOOL (*)(id, SEL))method_getImplementation(m);
                        class_replaceMethod(cls, integritySel, (IMP)hooked_SystemIntegrityCheck, method_getTypeEncoding(m));
                        NSLog(@"[AmongUsCheat] Hooked %@.VerifyIntegrity", className);
                    }
                }
                
                SEL banSel = NSSelectorFromString(@"IsDeviceBanned");
                if (banSel) {
                    Method m = class_getInstanceMethod(cls, banSel);
                    if (m) {
                        orig_IsBanned = (BOOL (*)(id, SEL))method_getImplementation(m);
                        class_replaceMethod(cls, banSel, (IMP)hooked_IsBanned, method_getTypeEncoding(m));
                        NSLog(@"[AmongUsCheat] Hooked %@.IsDeviceBanned", className);
                    }
                }
            }
            
            if (innerNetClient) {
                SEL validateSel = NSSelectorFromString(@"ValidatePacket:");
                if (validateSel) {
                    Method origMethod = class_getInstanceMethod(innerNetClient, validateSel);
                    if (origMethod) {
                        orig_ValidatePacket_enhanced = (void (*)(id, SEL, id))method_getImplementation(origMethod);
                        class_replaceMethod(innerNetClient, validateSel, (IMP)hooked_ValidatePacket_enhanced, method_getTypeEncoding(origMethod));
                        NSLog(@"[AmongUsCheat] Hooked ValidatePacket (enhanced)");
                    }
                }
                
                SEL heartbeatSel = NSSelectorFromString(@"SendHeartbeat");
                if (heartbeatSel) {
                    Method m = class_getInstanceMethod(innerNetClient, heartbeatSel);
                    if (m) {
                        orig_SendHeartbeat = (void (*)(id, SEL))method_getImplementation(m);
                        class_replaceMethod(innerNetClient, heartbeatSel, (IMP)hooked_SendHeartbeat, method_getTypeEncoding(m));
                        NSLog(@"[AmongUsCheat] Hooked SendHeartbeat");
                    }
                }
            }
        }
        
        // ============================================================
        // Setup ESP
        // ============================================================
        if (g_espEnabled) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ESPOverlay *overlay = [[ESPOverlay alloc] init];
                g_espOverlay = (__bridge_retained void *)overlay;
                
                [NSTimer scheduledTimerWithTimeInterval:0.1
                                                repeats:YES
                                                  block:^(NSTimer *timer) {
                    updateESP();
                }];
                
                NSLog(@"[AmongUsCheat] ESP initialized");
            });
        }
        
        // ============================================================
        // Hook IAP Manager - Additional Anti-Ban/Unlock
        // ============================================================
        Class iapManager = objc_getClass("IAPManager");
        if (iapManager) {
            SEL canMakePurchasesSel = NSSelectorFromString(@"CanMakePurchases");
            if (canMakePurchasesSel) {
                Method origMethod = class_getInstanceMethod(iapManager, canMakePurchasesSel);
                if (origMethod) {
                    class_replaceMethod(iapManager, canMakePurchasesSel, (IMP)hooked_CanMakePurchases, method_getTypeEncoding(origMethod));
                    NSLog(@"[AmongUsCheat] Hooked CanMakePurchases");
                }
            }
        }
        
        Class storeManager = objc_getClass("StoreManager");
        if (storeManager) {
            SEL getProductInfoSel = NSSelectorFromString(@"GetProductInfo:");
            if (getProductInfoSel) {
                Method origMethod = class_getInstanceMethod(storeManager, getProductInfoSel);
                if (origMethod) {
                    class_replaceMethod(storeManager, getProductInfoSel, (IMP)hooked_GetProductInfo, method_getTypeEncoding(origMethod));
                    NSLog(@"[AmongUsCheat] Hooked GetProductInfo");
                }
            }
        }
        
        // Hook player spawn
        if (playerControl) {
            SEL onSpawnSel = NSSelectorFromString(@"OnSpawn");
            if (onSpawnSel) {
                Method origMethod = class_getInstanceMethod(playerControl, onSpawnSel);
                if (origMethod) {
                    class_replaceMethod(playerControl, onSpawnSel, (IMP)hooked_OnPlayerSpawn, method_getTypeEncoding(origMethod));
                    NSLog(@"[AmongUsCheat] Hooked OnSpawn");
                }
            }
        }
        
        // ============================================================
        // Add gesture to show settings menu (triple tap on screen)
        // ============================================================
        dispatch_async(dispatch_get_main_queue(), ^{
            UIWindow *window = [UIApplication sharedApplication].keyWindow;
            if (!window) {
                window = [[UIApplication sharedApplication].windows firstObject];
            }
            
            UITapGestureRecognizer *tripleTap = [[UITapGestureRecognizer alloc] init];
            tripleTap.numberOfTapsRequired = 3;
            [tripleTap addTarget:tripleTap action:@selector(handleTripleTap:)];
            [window addGestureRecognizer:tripleTap];
            
            NSLog(@"[AmongUsCheat] Triple-tap gesture added to show settings menu");
        });
        
        NSLog(@"[AmongUsCheat] Injection complete!");
        NSLog(@"[AmongUsCheat] Features: AlwaysImpostor=%@, Cosmetics=%@, ESP=%@, AutoWin=%@, AntiBan=%@",
              g_alwaysImpostor ? @"ON" : @"OFF",
              g_unlockAllCosmetics ? @"ON" : @"OFF",
              g_espEnabled ? @"ON" : @"OFF",
              g_autoWinEnabled ? @"ON" : @"OFF",
              g_noBanMode ? @"ON" : @"OFF");
    });
}

// ============================================================
// MARK: - Command Handling (for debugging)
// ============================================================

extern "C" void ToggleImpostor() {
    g_alwaysImpostor = !g_alwaysImpostor;
    NSLog(@"[AmongUsCheat] AlwaysImpostor: %@", g_alwaysImpostor ? @"ON" : @"OFF");
}

extern "C" void ToggleESP() {
    g_espEnabled = !g_espEnabled;
    if (g_espOverlay) {
        ESPOverlay *overlay = (__bridge ESPOverlay *)g_espOverlay;
        overlay.hidden = !g_espEnabled;
    }
    NSLog(@"[AmongUsCheat] ESP: %@", g_espEnabled ? @"ON" : @"OFF");
}

extern "C" void ToggleAutoWin() {
    g_autoWinEnabled = !g_autoWinEnabled;
    NSLog(@"[AmongUsCheat] AutoWin: %@", g_autoWinEnabled ? @"ON" : @"OFF");
}

extern "C" void ToggleAntiBan() {
    g_noBanMode = !g_noBanMode;
    NSLog(@"[AmongUsCheat] AntiBan: %@", g_noBanMode ? @"ON" : @"OFF");
}

// ============================================================
// MARK: - Memory Analysis Helper
// ============================================================

extern "C" void AnalyzeMemory() {
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = (Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    NSMutableArray *gameClasses = [NSMutableArray array];
    for (int i = 0; i < numClasses; i++) {
        NSString *className = NSStringFromClass(classes[i]);
        if ([className hasPrefix:@"AmongUs"] || 
            [className hasPrefix:@"Player"] ||
            [className hasPrefix:@"Game"]) {
            [gameClasses addObject:className];
        }
    }
    free(classes);
    
    NSLog(@"[AmongUsCheat] Found game classes: %@", gameClasses);
}
