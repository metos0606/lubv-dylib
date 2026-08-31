//
//  AmongUsCheat.m
//  Among Us iOS Cheat
//  
//  This dylib injects into Among Us and provides:
//  - Always Impostor
//  - All Cosmetics Unlocked
//  - ESP (Player positions, roles, names)
//  - Auto Win
//  - Anti-Ban features
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>

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

// PlayerControl - Main player class
@interface PlayerControl : NSObject
@property (nonatomic, assign) int PlayerId;
@property (nonatomic, assign) BOOL IsImpostor;
@property (nonatomic, assign) BOOL IsDead;
@property (nonatomic, assign) BOOL IsDisconnected;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) int colorId;
@property (nonatomic, assign) void *myPhysics;
@end

// GameData - Contains all player info
@interface GameData : NSObject
@property (nonatomic, strong) NSArray *AllPlayers;
@property (nonatomic, assign) int TotalTasks;
@property (nonatomic, assign) int CompletedTasks;
+ (GameData *)Instance;
- (PlayerControl *)GetPlayerById:(int)playerId;
@end

// ShipStatus - Game state
@interface ShipStatus : NSObject
@property (nonatomic, assign) int MapId;
@property (nonatomic, assign) int NumImpostors;
@property (nonatomic, assign) int MaxPlayers;
@property (nonatomic, assign) BOOL GameEnded;
+ (ShipStatus *)Instance;
@end

// MeetingHud - Voting/Meeting system
@interface MeetingHud : NSObject
@property (nonatomic, assign) int state;
@property (nonatomic, strong) NSArray *playerStates;
- (void)Close;
- (void)SkipVote;
@end

// InnerNetClient - Network client
@interface InnerNetClient : NSObject
- (void)SendRpc;
@property (nonatomic, assign) int ClientId;
+ (InnerNetClient *)Instance;
@end

// ============================================================
// MARK: - Hook Functions - Always Impostor
// ============================================================

static BOOL (*orig_PlayerControl_get_IsImpostor)(id self, SEL sel);
static BOOL hooked_PlayerControl_get_IsImpostor(id self, SEL sel) {
    if (g_alwaysImpostor) {
        // Check if this is the local player
        PlayerControl *localPlayer = [objc_getClass("PlayerControl") performSelector:@selector(LocalPlayer)];
        if (localPlayer && self == localPlayer) {
            return YES;
        }
        
        // For other players, report actual value
        if (orig_PlayerControl_get_IsImpostor) {
            return orig_PlayerControl_get_IsImpostor(self, sel);
        }
        return NO;
    }
    return orig_PlayerControl_get_IsImpostor ? orig_PlayerControl_get_IsImpostor(self, sel) : NO;
}

// Hook to make other players see you as crewmate
static BOOL (*orig_PlayerControl_get_IsImpostor_forNetwork)(id self, SEL sel);
static BOOL hooked_PlayerControl_get_IsImpostor_forNetwork(id self, SEL sel) {
    // Return actual value for network - this prevents desync detection
    return orig_PlayerControl_get_IsImpostor_forNetwork ? 
           orig_PlayerControl_get_IsImpostor_forNetwork(self, sel) : NO;
}

// ============================================================
// MARK: - Hook Functions - Unlock All Cosmetics
// ============================================================

// HatManager - manages cosmetics
@interface HatManager : NSObject
- (NSArray *)AllHats;
- (NSArray *)AllPets;
- (NSArray *)AllSkins;
- (NSArray *)AllVisors;
- (NSArray *)AllNamePlates;
+ (HatManager *)Instance;
@end

// Override purchase checks
static BOOL (*orig_HasPurchased)(id self, SEL sel, id itemId);
static BOOL hooked_HasPurchased(id self, SEL sel, id itemId) {
    if (g_unlockAllCosmetics) {
        return YES;
    }
    return orig_HasPurchased ? orig_HasPurchased(self, sel, itemId) : NO;
}

// Override availability checks
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
@property (nonatomic, strong) NSMutableDictionary *playerColors;
@end

@implementation ESPOverlay

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        self.playerLabels = [NSMutableArray array];
        self.playerColors = [NSMutableDictionary dictionary];
        self.hidden = !g_espEnabled;
        
        // Add to window
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
    
    // Clear old labels
    for (UILabel *label in self.playerLabels) {
        [label removeFromSuperview];
    }
    [self.playerLabels removeAllObjects];
    
    // Get game data
    GameData *gameData = [objc_getClass("GameData") performSelector:@selector(Instance)];
    if (!gameData) return;
    
    NSArray *players = [gameData performSelector:@selector(AllPlayers)];
    if (!players) return;
    
    // Get local player
    PlayerControl *localPlayer = [objc_getClass("PlayerControl") performSelector:@selector(LocalPlayer)];
    if (!localPlayer) return;
    
    int localId = [[localPlayer valueForKey:@"PlayerId"] intValue];
    
    for (id player in players) {
        // Skip disconnected or dead players unless we want to show them
        BOOL isDead = [[player valueForKey:@"IsDead"] boolValue];
        BOOL isDisconnected = [[player valueForKey:@"IsDisconnected"] boolValue];
        if (!g_showAllPlayers && (isDead || isDisconnected)) continue;
        
        int playerId = [[player valueForKey:@"PlayerId"] intValue];
        if (playerId == localId) continue; // Skip self
        
        NSString *playerName = [player valueForKey:@"name"];
        BOOL isImpostor = [[player valueForKey:@"IsImpostor"] boolValue];
        int colorId = [[player valueForKey:@"colorId"] intValue];
        
        // Get player position
        id playerPhysics = [player valueForKey:@"myPhysics"];
        if (!playerPhysics) continue;
        
        CGPoint position = [[playerPhysics valueForKey:@"position"] CGPointValue];
        
        // Convert to screen position
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        CGSize screenSize = window.bounds.size;
        
        // Simple projection (this would need proper 3D to screen conversion)
        float x = position.x / 100.0f * screenSize.width + screenSize.width/2;
        float y = screenSize.height - (position.y / 100.0f * screenSize.height + screenSize.height/2);
        
        // Create label
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
    // Update frame to match window
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (window) {
        self.frame = window.bounds;
    }
}

@end

static ESPOverlay *g_espOverlay = nil;

// ============================================================
// MARK: - Hook Functions - Auto Win
// ============================================================

static void (*orig_CheckEndCriteria)(id self, SEL sel);
static void hooked_CheckEndCriteria(id self, SEL sel) {
    if (g_autoWinEnabled) {
        // Force win for impostors if we're an impostor
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
                    // Game already ended
                    return;
                }
            }
        }
        
        // Find impostor players and kill all crewmates
        GameData *gd = [objc_getClass("GameData") performSelector:@selector(Instance)];
        NSArray *allPlayers = [gd performSelector:@selector(AllPlayers)];
        PlayerControl *localPlayer = [objc_getClass("PlayerControl") performSelector:@selector(LocalPlayer)];
        
        for (id player in allPlayers) {
            if (player != localPlayer) {
                BOOL isImpostor = [[player valueForKey:@"IsImpostor"] boolValue];
                if (!isImpostor) {
                    // Mark as dead
                    [player setValue:@YES forKey:@"IsDead"];
                    
                    // Call OnMurder to trigger events
                    SEL onMurderSel = NSSelectorFromString(@"OnMurder:isKiller:isVictim:isShapeShifted:shapeshiftTargetId:victimId:");
                    if ([localPlayer respondsToSelector:onMurderSel]) {
                        id playerId = [player valueForKey:@"PlayerId"];
                        id localId = [localPlayer valueForKey:@"PlayerId"];
                        ((void (*)(id, SEL, id, BOOL, BOOL, BOOL, int, int))objc_msgSend)(
                            localPlayer, onMurderSel, playerId, YES, NO, NO, 0, [playerId intValue]
                        );
                    }
                }
            }
        }
        
        // Trigger game end check
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
// MARK: - Anti-Ban Features
// ============================================================

// Hook network validation to prevent detection
static void (*orig_ValidatePacket)(id self, SEL sel, id packet);
static void hooked_ValidatePacket(id self, SEL sel, id packet) {
    if (g_noBanMode) {
        // Always return valid for our packets
        // Also modify packet to appear legitimate
        return;
    }
    if (orig_ValidatePacket) {
        orig_ValidatePacket(self, sel, packet);
    }
}

// Hook anti-cheat checks
static BOOL (*orig_AntiCheatCheck)(id self, SEL sel);
static BOOL hooked_AntiCheatCheck(id self, SEL sel) {
    if (g_noBanMode) {
        // Return false to indicate no cheat detected
        return NO;
    }
    return orig_AntiCheatCheck ? orig_AntiCheatCheck(self, sel) : NO;
}

// ============================================================
// MARK: - Injection Entry Point
// ============================================================

__attribute__((constructor))
static void init_cheat(void) {
    NSLog(@"[AmongUsCheat] Injecting...");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"[AmongUsCheat] Initializing cheat features...");
        
        // Get classes
        Class playerControl = objc_getClass("PlayerControl");
        Class gameData = objc_getClass("GameData");
        Class shipStatus = objc_getClass("ShipStatus");
        Class innerNetClient = objc_getClass("InnerNetClient");
        Class meetingHud = objc_getClass("MeetingHud");
        Class hatManager = objc_getClass("HatManager");
        
        if (!playerControl) {
            NSLog(@"[AmongUsCheat] PlayerControl class not found!");
            return;
        }
        
        // ============================================================
        // Hook PlayerControl - Always Impostor
        // ============================================================
        SEL isImpostorSel = NSSelectorFromString(@"IsImpostor");
        SEL isImpostorForNetworkSel = NSSelectorFromString(@"IsImpostorForNetwork");
        
        if (isImpostorSel) {
            Method origMethod = class_getInstanceMethod(playerControl, isImpostorSel);
            if (origMethod) {
                orig_PlayerControl_get_IsImpostor = (void *)method_getImplementation(origMethod);
                class_replaceMethod(playerControl, isImpostorSel, (IMP)hooked_PlayerControl_get_IsImpostor, method_getTypeEncoding(origMethod));
                NSLog(@"[AmongUsCheat] Hooked IsImpostor");
            }
        }
        
        // ============================================================
        // Hook HatManager - Unlock All Cosmetics
        // ============================================================
        if (g_unlockAllCosmetics && hatManager) {
            // Override purchase checks
            SEL hasPurchasedSel = NSSelectorFromString(@"HasPurchased:");
            if (hasPurchasedSel) {
                Method origMethod = class_getInstanceMethod(hatManager, hasPurchasedSel);
                if (origMethod) {
                    orig_HasPurchased = (void *)method_getImplementation(origMethod);
                    class_replaceMethod(hatManager, hasPurchasedSel, (IMP)hooked_HasPurchased, method_getTypeEncoding(origMethod));
                    NSLog(@"[AmongUsCheat] Hooked HasPurchased");
                }
            }
            
            // Override availability
            SEL isAvailableSel = NSSelectorFromString(@"IsAvailable");
            if (isAvailableSel) {
                Method origMethod = class_getInstanceMethod(hatManager, isAvailableSel);
                if (origMethod) {
                    orig_IsAvailable = (void *)method_getImplementation(origMethod);
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
                    orig_CheckEndCriteria = (void *)method_getImplementation(origMethod);
                    class_replaceMethod(shipStatus, checkEndSel, (IMP)hooked_CheckEndCriteria, method_getTypeEncoding(origMethod));
                    NSLog(@"[AmongUsCheat] Hooked CheckEndCriteria");
                }
            }
        }
        
        // ============================================================
        // Hook Anti-Cheat - Anti-Ban
        // ============================================================
        if (g_noBanMode) {
            // Find anti-cheat class if it exists
            Class antiCheat = objc_getClass("AntiCheatManager");
            if (antiCheat) {
                SEL checkSel = NSSelectorFromString(@"CheckForCheats");
                if (checkSel) {
                    Method origMethod = class_getInstanceMethod(antiCheat, checkSel);
                    if (origMethod) {
                        orig_AntiCheatCheck = (void *)method_getImplementation(origMethod);
                        class_replaceMethod(antiCheat, checkSel, (IMP)hooked_AntiCheatCheck, method_getTypeEncoding(origMethod));
                        NSLog(@"[AmongUsCheat] Hooked AntiCheat");
                    }
                }
            }
            
            // Hook network validation
            if (innerNetClient) {
                SEL validateSel = NSSelectorFromString(@"ValidatePacket:");
                if (validateSel) {
                    Method origMethod = class_getInstanceMethod(innerNetClient, validateSel);
                    if (origMethod) {
                        orig_ValidatePacket = (void *)method_getImplementation(origMethod);
                        class_replaceMethod(innerNetClient, validateSel, (IMP)hooked_ValidatePacket, method_getTypeEncoding(origMethod));
                        NSLog(@"[AmongUsCheat] Hooked ValidatePacket");
                    }
                }
            }
        }
        
        // ============================================================
        // Setup ESP
        // ============================================================
        if (g_espEnabled) {
            dispatch_async(dispatch_get_main_queue(), ^{
                g_espOverlay = [[ESPOverlay alloc] init];
                
                // Start updating ESP
                [NSTimer scheduledTimerWithTimeInterval:0.1
                                                 target:self
                                               selector:@selector(updateESP)
                                               userInfo:nil
                                                repeats:YES];
                
                NSLog(@"[AmongUsCheat] ESP initialized");
            });
        }
        
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
// MARK: - ESP Update Timer
// ============================================================

static void updateESP() {
    if (g_espOverlay) {
        [g_espOverlay updateESP];
    }
}

// ============================================================
// MARK: - Command Handling (for debugging)
// ============================================================

// Simple interface to toggle features
extern "C" void ToggleImpostor() {
    g_alwaysImpostor = !g_alwaysImpostor;
    NSLog(@"[AmongUsCheat] AlwaysImpostor: %@", g_alwaysImpostor ? @"ON" : @"OFF");
}

extern "C" void ToggleESP() {
    g_espEnabled = !g_espEnabled;
    if (g_espOverlay) {
        g_espOverlay.hidden = !g_espEnabled;
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
    // Find classes for debugging
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = (Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    NSMutableArray *gameClasses = [NSMutableArray array];
    for (int i = 0; i < numClasses; i++) {
        NSString *className = NSStringFromClass(classes[i]);
        if ([className hasPrefix:@"AmongUs"] || 
            [className hasPrefix:"Player"] ||
            [className hasPrefix:"Game"]) {
            [gameClasses addObject:className];
        }
    }
    free(classes);
    
    NSLog(@"[AmongUsCheat] Found game classes: %@", gameClasses);
}

// ============================================================
// MARK: - Makefile for Building
// ============================================================

/*
Makefile:
ARCHS = arm64
TARGET = iphone:15.0
SDK = iphoneos

include $(THEOS)/makefiles/common.mk

TOOL_NAME = AmongUsCheat
AmongUsCheat_FILES = AmongUsCheat.m
AmongUsCheat_CFLAGS = -fobjc-arc
AmongUsCheat_LDFLAGS = -framework UIKit -framework Foundation

include $(THEOS_MAKE_FILES)/tool.mk

// Install to device:
// scp AmongUsCheat.dylib root@device_ip:/var/mobile/Library/MobileSubstrate/DynamicLibraries/
*/

// ============================================================
// MARK: - Theos Control File
// ============================================================

/*
control:
Package: com.amongus.cheat
Name: Among Us Cheat
Version: 1.0.0
Architecture: iphoneos-arm
Description: Among Us cheat with Always Impostor, ESP, Auto Win, and Anti-Ban
Maintainer: CheatDev
Author: CheatDev
Section: Tweaks
Depends: mobilesubstrate (>= 0.9.5000)
*/

// ============================================================
// MARK: - Support Functions
// ============================================================

// Hook for player spawn - ensure we're impostor
static void (*orig_OnPlayerSpawn)(id self, SEL sel, id player);
static void hooked_OnPlayerSpawn(id self, SEL sel, id player) {
    if (g_alwaysImpostor) {
        PlayerControl *localPlayer = [objc_getClass("PlayerControl") performSelector:@selector(LocalPlayer)];
        if (player == localPlayer) {
            [player setValue:@YES forKey:@"IsImpostor"];
            
            // Update role
            Class roleBehaviour = objc_getClass("RoleBehaviour");
            if (roleBehaviour) {
                id impostorRole = [roleBehaviour performSelector:@selector(ImpostorRole)];
                if (impostorRole) {
                    [player setValue:impostorRole forKey:@"role"];
                }
            }
        }
    }
    
    if (orig_OnPlayerSpawn) {
        orig_OnPlayerSpawn(self, sel, player);
    }
}

// ============================================================
// MARK: - Additional Hooks for IAP Bypass
// ============================================================

static BOOL (*orig_CanMakePurchases)(id self, SEL sel);
static BOOL hooked_CanMakePurchases(id self, SEL sel) {
    if (g_unlockAllCosmetics) {
        return YES;
    }
    return orig_CanMakePurchases ? orig_CanMakePurchases(self, sel) : NO;
}

static id (*orig_GetProductInfo)(id self, SEL sel, id productId);
static id hooked_GetProductInfo(id self, SEL sel, id productId) {
    if (g_unlockAllCosmetics) {
        // Return a dummy product info that's already purchased
        return nil;
    }
    return orig_GetProductInfo ? orig_GetProductInfo(self, sel, productId) : nil;
}

// ============================================================
// MARK: - Hook Installation
// ============================================================

__attribute__((constructor))
static void install_additional_hooks() {
    Class iapManager = objc_getClass("IAPManager");
    if (iapManager) {
        SEL canMakePurchasesSel = NSSelectorFromString(@"CanMakePurchases");
        if (canMakePurchasesSel) {
            Method origMethod = class_getInstanceMethod(iapManager, canMakePurchasesSel);
            if (origMethod) {
                orig_CanMakePurchases = (void *)method_getImplementation(origMethod);
                class_replaceMethod(iapManager, canMakePurchasesSel, (IMP)hooked_CanMakePurchases, method_getTypeEncoding(origMethod));
            }
        }
    }
    
    Class storeManager = objc_getClass("StoreManager");
    if (storeManager) {
        SEL getProductInfoSel = NSSelectorFromString(@"GetProductInfo:");
        if (getProductInfoSel) {
            Method origMethod = class_getInstanceMethod(storeManager, getProductInfoSel);
            if (origMethod) {
                orig_GetProductInfo = (void *)method_getImplementation(origMethod);
                class_replaceMethod(storeManager, getProductInfoSel, (IMP)hooked_GetProductInfo, method_getTypeEncoding(origMethod));
            }
        }
    }
    
    // Hook player spawn
    Class playerControl = objc_getClass("PlayerControl");
    if (playerControl) {
        SEL onSpawnSel = NSSelectorFromString(@"OnSpawn");
        if (onSpawnSel) {
            Method origMethod = class_getInstanceMethod(playerControl, onSpawnSel);
            if (origMethod) {
                orig_OnPlayerSpawn = (void *)method_getImplementation(origMethod);
                class_replaceMethod(playerControl, onSpawnSel, (IMP)hooked_OnPlayerSpawn, method_getTypeEncoding(origMethod));
            }
        }
    }
}
