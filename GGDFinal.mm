#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <stdlib.h>
#include <vector>

// GGD Final Safe Build
// Target profile: com.seayoo.ggd / 1.1.13 / arm64 / iOS 18+
// Design priorities: never touch IL2CPP during dylib constructor, delayed runtime discovery,
// bounded metadata scanning, touch-through overlay, and no guessed native offsets.

// ----------------------------- IL2CPP ABI ---------------------------------
struct Il2CppDomain;
struct Il2CppThread;
struct Il2CppAssembly;
struct Il2CppImage;
struct Il2CppClass;
struct FieldInfo;
struct MethodInfo;
struct Il2CppObject;
struct Il2CppType;
struct Il2CppString;

struct Il2CppArray {
    Il2CppObject *klass;
    void *monitor;
    void *bounds;
    uintptr_t max_length;
    uintptr_t vector[1];
};

struct GGDVector3 { float x, y, z; };

using t_domain_get                = Il2CppDomain* (*)();
using t_thread_attach             = Il2CppThread* (*)(Il2CppDomain*);
using t_domain_get_assemblies     = const Il2CppAssembly** (*)(Il2CppDomain*, size_t*);
using t_assembly_get_image        = const Il2CppImage* (*)(const Il2CppAssembly*);
using t_image_get_name            = const char* (*)(const Il2CppImage*);
using t_image_get_class_count     = size_t (*)(const Il2CppImage*);
using t_image_get_class           = Il2CppClass* (*)(const Il2CppImage*, size_t);
using t_class_from_name           = Il2CppClass* (*)(const Il2CppImage*, const char*, const char*);
using t_class_get_name            = const char* (*)(Il2CppClass*);
using t_class_get_namespace       = const char* (*)(Il2CppClass*);
using t_class_get_parent          = Il2CppClass* (*)(Il2CppClass*);
using t_class_get_fields          = FieldInfo* (*)(Il2CppClass*, void**);
using t_class_get_field_from_name = FieldInfo* (*)(Il2CppClass*, const char*);
using t_class_get_method          = const MethodInfo* (*)(Il2CppClass*, const char*, int);
using t_class_is_assignable       = bool (*)(Il2CppClass*, Il2CppClass*);
using t_class_from_type           = Il2CppClass* (*)(const Il2CppType*);
using t_field_get_flags            = uint32_t (*)(FieldInfo*);
using t_field_get_name             = const char* (*)(FieldInfo*);
using t_field_get_type             = const Il2CppType* (*)(FieldInfo*);
using t_field_static_get_value     = void (*)(FieldInfo*, void*);
using t_field_get_value             = void (*)(Il2CppObject*, FieldInfo*, void*);
using t_type_get_name               = const char* (*)(const Il2CppType*);
using t_object_get_class            = Il2CppClass* (*)(Il2CppObject*);
using t_object_unbox                = void* (*)(Il2CppObject*);
using t_runtime_invoke              = Il2CppObject* (*)(const MethodInfo*, void*, void**, Il2CppObject**);
using t_string_length               = int32_t (*)(Il2CppString*);
using t_string_chars                = const uint16_t* (*)(Il2CppString*);

static constexpr uint32_t FIELD_ATTRIBUTE_STATIC = 0x0010;
static constexpr uint32_t FIELD_ATTRIBUTE_LITERAL = 0x0040;

struct GGDIl2CppAPI {
    void *handle = nullptr;
    t_domain_get domain_get = nullptr;
    t_thread_attach thread_attach = nullptr;
    t_domain_get_assemblies domain_get_assemblies = nullptr;
    t_assembly_get_image assembly_get_image = nullptr;
    t_image_get_name image_get_name = nullptr;
    t_image_get_class_count image_get_class_count = nullptr;
    t_image_get_class image_get_class = nullptr;
    t_class_from_name class_from_name = nullptr;
    t_class_get_name class_get_name = nullptr;
    t_class_get_namespace class_get_namespace = nullptr;
    t_class_get_parent class_get_parent = nullptr;
    t_class_get_fields class_get_fields = nullptr;
    t_class_get_field_from_name class_get_field_from_name = nullptr;
    t_class_get_method class_get_method = nullptr;
    t_class_is_assignable class_is_assignable = nullptr;
    t_class_from_type class_from_type = nullptr;
    t_field_get_flags field_get_flags = nullptr;
    t_field_get_name field_get_name = nullptr;
    t_field_get_type field_get_type = nullptr;
    t_field_static_get_value field_static_get_value = nullptr;
    t_field_get_value field_get_value = nullptr;
    t_type_get_name type_get_name = nullptr;
    t_object_get_class object_get_class = nullptr;
    t_object_unbox object_unbox = nullptr;
    t_runtime_invoke runtime_invoke = nullptr;
    t_string_length string_length = nullptr;
    t_string_chars string_chars = nullptr;

    static void *sym(void *h, const char *name) {
        if (h) {
            void *p = dlsym(h, name);
            if (p) return p;
        }
        return dlsym(RTLD_DEFAULT, name);
    }

    bool resolveLoadedImage(const char *path) {
        if (!path || !*path) return false;
        void *h = dlopen(path, RTLD_NOW | RTLD_NOLOAD);
        if (!h) return false;

#define RESOLVE(member, symbol) member = reinterpret_cast<decltype(member)>(sym(h, symbol))
        RESOLVE(domain_get, "il2cpp_domain_get");
        RESOLVE(thread_attach, "il2cpp_thread_attach");
        RESOLVE(domain_get_assemblies, "il2cpp_domain_get_assemblies");
        RESOLVE(assembly_get_image, "il2cpp_assembly_get_image");
        RESOLVE(image_get_name, "il2cpp_image_get_name");
        RESOLVE(image_get_class_count, "il2cpp_image_get_class_count");
        RESOLVE(image_get_class, "il2cpp_image_get_class");
        RESOLVE(class_from_name, "il2cpp_class_from_name");
        RESOLVE(class_get_name, "il2cpp_class_get_name");
        RESOLVE(class_get_namespace, "il2cpp_class_get_namespace");
        RESOLVE(class_get_parent, "il2cpp_class_get_parent");
        RESOLVE(class_get_fields, "il2cpp_class_get_fields");
        RESOLVE(class_get_field_from_name, "il2cpp_class_get_field_from_name");
        RESOLVE(class_get_method, "il2cpp_class_get_method_from_name");
        RESOLVE(class_is_assignable, "il2cpp_class_is_assignable_from");
        RESOLVE(class_from_type, "il2cpp_class_from_type");
        RESOLVE(field_get_flags, "il2cpp_field_get_flags");
        RESOLVE(field_get_name, "il2cpp_field_get_name");
        RESOLVE(field_get_type, "il2cpp_field_get_type");
        RESOLVE(field_static_get_value, "il2cpp_field_static_get_value");
        RESOLVE(field_get_value, "il2cpp_field_get_value");
        RESOLVE(type_get_name, "il2cpp_type_get_name");
        RESOLVE(object_get_class, "il2cpp_object_get_class");
        RESOLVE(object_unbox, "il2cpp_object_unbox");
        RESOLVE(runtime_invoke, "il2cpp_runtime_invoke");
        RESOLVE(string_length, "il2cpp_string_length");
        RESOLVE(string_chars, "il2cpp_string_chars");
#undef RESOLVE

        handle = h;
        return domain_get && thread_attach && domain_get_assemblies && assembly_get_image &&
               class_from_name && class_get_fields && class_get_field_from_name &&
               field_get_flags && field_get_name && field_get_type && field_static_get_value &&
               field_get_value && type_get_name && object_get_class && runtime_invoke;
    }

    bool attach() {
        if (!domain_get || !thread_attach) return false;
        Il2CppDomain *domain = domain_get();
        if (!domain) return false;
        return thread_attach(domain) != nullptr;
    }

    std::vector<const Il2CppImage*> images() const {
        std::vector<const Il2CppImage*> out;
        if (!domain_get || !domain_get_assemblies || !assembly_get_image) return out;
        Il2CppDomain *domain = domain_get();
        if (!domain) return out;
        size_t count = 0;
        const Il2CppAssembly **list = domain_get_assemblies(domain, &count);
        if (!list) return out;
        out.reserve(count);
        for (size_t i = 0; i < count; ++i) {
            const Il2CppImage *img = assembly_get_image(list[i]);
            if (img) out.push_back(img);
        }
        return out;
    }

    Il2CppClass *findClass(const char *name, const char *ns = nullptr) const {
        if (!name || !class_from_name) return nullptr;
        std::vector<const Il2CppImage*> imgs = images();
        static const char *namespaces[] = { "", "Goose", "UnityEngine", "UnityEngine.UI", nullptr };
        for (const Il2CppImage *img : imgs) {
            if (!ns || !*ns) {
                for (int i = 0; namespaces[i]; ++i) {
                    Il2CppClass *c = class_from_name(img, namespaces[i], name);
                    if (c) return c;
                }
            } else {
                Il2CppClass *c = class_from_name(img, ns, name);
                if (c) return c;
            }
        }
        return nullptr;
    }

    NSString *stringToNSString(Il2CppString *s) const {
        if (!s || !string_length || !string_chars) return nil;
        int32_t len = string_length(s);
        if (len <= 0 || len > 2048) return nil;
        const uint16_t *chars = string_chars(s);
        if (!chars) return nil;
        return [[NSString alloc] initWithCharacters:(const unichar *)chars length:(NSUInteger)len];
    }
};

// ----------------------------- Utility ------------------------------------
static bool ggLowerContains(const char *s, const char *needle) {
    if (!s || !needle) return false;
    size_t n = strlen(s), m = strlen(needle);
    if (m == 0 || n < m) return false;
    for (size_t i = 0; i + m <= n; ++i) {
        bool same = true;
        for (size_t j = 0; j < m; ++j) {
            char a = s[i + j], b = needle[j];
            if (a >= 'A' && a <= 'Z') a = char(a - 'A' + 'a');
            if (b >= 'A' && b <= 'Z') b = char(b - 'A' + 'a');
            if (a != b) { same = false; break; }
        }
        if (same) return true;
    }
    return false;
}

static bool isStringType(GGDIl2CppAPI &api, FieldInfo *field) {
    if (!field || !api.field_get_type || !api.type_get_name) return false;
    const Il2CppType *t = api.field_get_type(field);
    const char *tn = t ? api.type_get_name(t) : nullptr;
    return tn && (strcmp(tn, "System.String") == 0 || strcmp(tn, "string") == 0);
}

static bool isCollectionType(GGDIl2CppAPI &api, FieldInfo *field) {
    if (!field || !api.field_get_type || !api.type_get_name) return false;
    const Il2CppType *t = api.field_get_type(field);
    const char *tn = t ? api.type_get_name(t) : nullptr;
    if (!tn) return false;
    if (strstr(tn, "System.Collections.Generic.List`1") != nullptr) return true;
    size_t n = strlen(tn);
    return n >= 2 && tn[n - 2] == '[' && tn[n - 1] == ']';
}

static FieldInfo *fieldByNames(GGDIl2CppAPI &api, Il2CppClass *klass, const char *const *names, bool instanceOnly) {
    if (!klass || !api.class_get_field_from_name || !api.field_get_flags) return nullptr;
    for (int depth = 0; klass && depth < 8; ++depth) {
        for (int i = 0; names[i]; ++i) {
            FieldInfo *f = api.class_get_field_from_name(klass, names[i]);
            if (!f) continue;
            uint32_t flags = api.field_get_flags(f);
            if (instanceOnly && (flags & FIELD_ATTRIBUTE_STATIC)) continue;
            if (!instanceOnly && !(flags & FIELD_ATTRIBUTE_STATIC)) continue;
            return f;
        }
        klass = api.class_get_parent ? api.class_get_parent(klass) : nullptr;
    }
    return nullptr;
}

static NSString *readStringField(GGDIl2CppAPI &api, Il2CppObject *obj, Il2CppClass *klass,
                                 const char *const *names) {
    if (!obj || !klass || !api.field_get_value) return nil;
    FieldInfo *f = fieldByNames(api, klass, names, true);
    if (!f || !isStringType(api, f)) return nil;
    Il2CppString *s = nullptr;
    api.field_get_value(obj, f, &s);
    return api.stringToNSString(s);
}

static bool readIntegerField(GGDIl2CppAPI &api, Il2CppObject *obj, FieldInfo *f, int64_t &out) {
    if (!obj || !f || !api.field_get_value) return false;
    out = 0;
    // Most IL2CPP enum/role ids in managed games use Int32. The zeroed 64-bit slot
    // also safely handles smaller integer backing types for this read-only probe.
    api.field_get_value(obj, f, &out);
    return true;
}

static NSString *enumNameForValue(GGDIl2CppAPI &api, const Il2CppType *type, int64_t value) {
    if (!type || !api.class_from_type || !api.class_get_fields || !api.field_get_flags ||
        !api.field_get_name || !api.field_static_get_value) return nil;
    Il2CppClass *enumClass = api.class_from_type(type);
    if (!enumClass) return nil;
    void *iter = nullptr;
    while (FieldInfo *f = api.class_get_fields(enumClass, &iter)) {
        uint32_t flags = api.field_get_flags(f);
        if (!(flags & FIELD_ATTRIBUTE_LITERAL)) continue;
        int64_t v = 0;
        api.field_static_get_value(f, &v);
        if (v == value) {
            const char *n = api.field_get_name(f);
            if (n && *n) return [NSString stringWithUTF8String:n];
        }
    }
    return nil;
}

static NSString *readRoleField(GGDIl2CppAPI &api, Il2CppObject *obj, Il2CppClass *klass) {
    static const char *const names[] = {
        "RoleName", "roleName", "Role", "role", "CurrentRole", "currentRole",
        "RoleType", "roleType", "RoleId", "roleId", "Camp", "camp", "Faction", "faction",
        "Team", "team", "Identity", "identity", nullptr
    };

    if (!obj || !klass || !api.class_get_field_from_name || !api.field_get_flags) return nil;
    for (int depth = 0; klass && depth < 8; ++depth) {
        for (int i = 0; names[i]; ++i) {
            FieldInfo *f = api.class_get_field_from_name(klass, names[i]);
            if (!f) continue;
            uint32_t flags = api.field_get_flags(f);
            if (flags & FIELD_ATTRIBUTE_STATIC) continue;
            if (isStringType(api, f)) {
                Il2CppString *s = nullptr;
                api.field_get_value(obj, f, &s);
                NSString *v = api.stringToNSString(s);
                if (v.length) return v;
            } else {
                const Il2CppType *type = api.field_get_type ? api.field_get_type(f) : nullptr;
                int64_t raw = 0;
                if (readIntegerField(api, obj, f, raw)) {
                    NSString *en = enumNameForValue(api, type, raw);
                    if (en.length) return en;
                    if (api.type_get_name && type) {
                        const char *tn = api.type_get_name(type);
                        if (tn && (ggLowerContains(tn, "role") || ggLowerContains(tn, "team") ||
                                   ggLowerContains(tn, "camp") || ggLowerContains(tn, "faction"))) {
                            return [NSString stringWithFormat:@"RoleId=%lld", (long long)raw];
                        }
                    }
                }
            }
        }
        klass = api.class_get_parent ? api.class_get_parent(klass) : nullptr;
    }
    return nil;
}

static NSString *fallbackStringField(GGDIl2CppAPI &api, Il2CppObject *obj, Il2CppClass *klass,
                                     const char *const *keywords) {
    if (!klass || !obj || !api.class_get_fields || !api.field_get_flags || !api.field_get_name) return nil;
    for (int depth = 0; klass && depth < 8; ++depth) {
        void *iter = nullptr;
        while (FieldInfo *f = api.class_get_fields(klass, &iter)) {
            uint32_t flags = api.field_get_flags(f);
            if (flags & FIELD_ATTRIBUTE_STATIC) continue;
            const char *fn = api.field_get_name(f);
            if (!fn) continue;
            bool hit = false;
            for (int k = 0; keywords[k]; ++k) {
                if (ggLowerContains(fn, keywords[k])) { hit = true; break; }
            }
            if (!hit || !isStringType(api, f)) continue;
            Il2CppString *s = nullptr;
            api.field_get_value(obj, f, &s);
            NSString *v = api.stringToNSString(s);
            if (v.length) return v;
        }
        klass = api.class_get_parent ? api.class_get_parent(klass) : nullptr;
    }
    return nil;
}

static Il2CppObject *readObjectFieldByKeywords(GGDIl2CppAPI &api, Il2CppObject *obj, Il2CppClass *klass,
                                               const char *const *keywords) {
    if (!klass || !obj || !api.class_get_fields || !api.field_get_flags || !api.field_get_name || !api.field_get_value) return nullptr;
    for (int depth = 0; klass && depth < 6; ++depth) {
        void *iter = nullptr;
        while (FieldInfo *f = api.class_get_fields(klass, &iter)) {
            uint32_t flags = api.field_get_flags(f);
            if (flags & FIELD_ATTRIBUTE_STATIC) continue;
            const char *fn = api.field_get_name(f);
            if (!fn) continue;
            bool hit = false;
            for (int k = 0; keywords[k]; ++k) {
                if (ggLowerContains(fn, keywords[k])) { hit = true; break; }
            }
            if (!hit) continue;
            const Il2CppType *t = api.field_get_type ? api.field_get_type(f) : nullptr;
            const char *tn = (t && api.type_get_name) ? api.type_get_name(t) : nullptr;
            if (!tn || isStringType(api, f)) continue;
            Il2CppObject *value = nullptr;
            api.field_get_value(obj, f, &value);
            if (value) return value;
        }
        klass = api.class_get_parent ? api.class_get_parent(klass) : nullptr;
    }
    return nullptr;
}

// ---------------------------- Runtime core --------------------------------
struct GGDPlayerSnapshot {
    void *object = nullptr;
    Il2CppClass *klass = nullptr;
    NSString *name = nil;
    NSString *role = nil;
    CGPoint screen = CGPointMake(0, 0);
    BOOL hasPosition = NO;
};

@interface GGDCore : NSObject
@property(nonatomic, readonly) BOOL il2cppReady;
@property(nonatomic, readonly) BOOL gameReady;
@property(nonatomic, readonly) NSUInteger playerCount;
@property(nonatomic, readonly) NSArray<NSDictionary*> *snapshots;
@property(nonatomic, readonly) NSString *statusLine;
+ (instancetype)shared;
- (void)start;
- (void)tick;
@end

@interface GGDCore () {
    GGDIl2CppAPI _api;
    BOOL _started;
    BOOL _attached;
    BOOL _runtimeReady;
    BOOL _profileOK;
    BOOL _sourceFound;
    BOOL _positionReady;
    BOOL _fullScan;
    NSUInteger _imageIndex;
    NSUInteger _classIndex;
    NSUInteger _currentImageClassCount;
    Il2CppClass *_sourceOwnerClass;
    FieldInfo *_sourceField;
    NSString *_sourceDescription;
    Il2CppClass *_componentClass;
    Il2CppClass *_gameObjectClass;
    Il2CppClass *_transformClass;
    Il2CppClass *_cameraClass;
    const MethodInfo *_componentGetTransform;
    const MethodInfo *_gameObjectGetTransform;
    const MethodInfo *_transformGetPosition;
    const MethodInfo *_cameraGetMain;
    const MethodInfo *_cameraWorldToScreenPoint;
    NSMutableArray<NSDictionary*> *_snapshots;
    NSString *_statusLine;
}
@end

@implementation GGDCore

+ (instancetype)shared {
    static GGDCore *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [GGDCore new]; });
    return s;
}

- (instancetype)init {
    if ((self = [super init])) {
        _profileOK = NO;
        _statusLine = @"插件已加载 · 等待安全初始化";
        _snapshots = [NSMutableArray array];
    }
    return self;
}

- (BOOL)il2cppReady { return _runtimeReady; }
- (BOOL)gameReady { return _sourceFound && _snapshots.count > 0; }
- (NSUInteger)playerCount { return _snapshots.count; }
- (NSArray<NSDictionary*>*)snapshots { return [_snapshots copy]; }
- (NSString*)statusLine { return _statusLine ?: @""; }

- (BOOL)checkProfile {
    NSString *bundle = NSBundle.mainBundle.bundleIdentifier ?: @"";
    NSString *version = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"] ?: @"";
    if (![bundle isEqualToString:@"com.seayoo.ggd"]) {
        _statusLine = [NSString stringWithFormat:@"版本保护：Bundle ID=%@", bundle];
        return NO;
    }
    if (![version hasPrefix:@"1.1.13"]) {
        _statusLine = [NSString stringWithFormat:@"版本保护：游戏版本=%@，目标=1.1.13", version];
        return NO;
    }
    return YES;
}

- (BOOL)findAndResolveUnityFramework {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; ++i) {
        const char *path = _dyld_get_image_name(i);
        if (!path) continue;
        const char *base = strrchr(path, '/');
        base = base ? base + 1 : path;
        if (strcmp(base, "UnityFramework") != 0) continue;
        if (_api.resolveLoadedImage(path)) return YES;
    }
    return NO;
}

- (BOOL)prepareUnityMethods {
    if (!_runtimeReady) return NO;
    if (_componentClass && _transformClass && _cameraClass) return YES;

    _componentClass = _api.findClass("Component", "UnityEngine");
    _gameObjectClass = _api.findClass("GameObject", "UnityEngine");
    _transformClass = _api.findClass("Transform", "UnityEngine");
    _cameraClass = _api.findClass("Camera", "UnityEngine");
    if (!_componentClass || !_transformClass || !_cameraClass) return NO;

    _componentGetTransform = _api.class_get_method ? _api.class_get_method(_componentClass, "get_transform", 0) : nullptr;
    _gameObjectGetTransform = _api.class_get_method && _gameObjectClass ? _api.class_get_method(_gameObjectClass, "get_transform", 0) : nullptr;
    _transformGetPosition = _api.class_get_method ? _api.class_get_method(_transformClass, "get_position", 0) : nullptr;
    _cameraGetMain = _api.class_get_method ? _api.class_get_method(_cameraClass, "get_main", 0) : nullptr;
    _cameraWorldToScreenPoint = _api.class_get_method ? _api.class_get_method(_cameraClass, "WorldToScreenPoint", 1) : nullptr;

    _positionReady = _transformGetPosition && _cameraGetMain && _cameraWorldToScreenPoint &&
                     (_componentGetTransform || _gameObjectGetTransform);
    return _positionReady;
}

- (BOOL)runManagedCall:(Il2CppObject*)target method:(const MethodInfo*)method args:(void**)args outObject:(Il2CppObject**)outObject {
    if (!_api.runtime_invoke || !method) return NO;
    Il2CppObject *exception = nullptr;
    Il2CppObject *result = _api.runtime_invoke(method, target, args, &exception);
    if (exception) return NO;
    if (outObject) *outObject = result;
    return YES;
}

- (Il2CppObject*)transformForPlayer:(Il2CppObject*)player class:(Il2CppClass*)klass {
    if (!player || !klass) return nullptr;

    if (_componentClass && _api.class_is_assignable && _api.class_is_assignable(_componentClass, klass) && _componentGetTransform) {
        Il2CppObject *out = nullptr;
        if ([self runManagedCall:player method:_componentGetTransform args:nullptr outObject:&out]) return out;
    }

    static const char *const transformKeywords[] = { "transform", "playerTransform", "avatar", "model", "gameObject", nullptr };
    if (_api.class_get_fields && _api.field_get_flags && _api.field_get_name && _api.field_get_value) {
        for (int depth = 0; klass && depth < 6; ++depth) {
            void *iter = nullptr;
            while (FieldInfo *f = _api.class_get_fields(klass, &iter)) {
                uint32_t flags = _api.field_get_flags(f);
                if (flags & FIELD_ATTRIBUTE_STATIC) continue;
                const char *fn = _api.field_get_name(f);
                if (!fn) continue;
                bool hit = false;
                for (int k = 0; transformKeywords[k]; ++k) {
                    if (ggLowerContains(fn, transformKeywords[k])) { hit = true; break; }
                }
                if (!hit) continue;
                const Il2CppType *t = _api.field_get_type ? _api.field_get_type(f) : nullptr;
                const char *tn = (t && _api.type_get_name) ? _api.type_get_name(t) : nullptr;
                Il2CppObject *value = nullptr;
                _api.field_get_value(player, f, &value);
                if (!value) continue;
                if (tn && strstr(tn, "UnityEngine.Transform") && _transformGetPosition) return value;
                if (tn && strstr(tn, "UnityEngine.GameObject") && _gameObjectGetTransform) {
                    Il2CppObject *out = nullptr;
                    if ([self runManagedCall:value method:_gameObjectGetTransform args:nullptr outObject:&out]) return out;
                }
            }
            klass = _api.class_get_parent ? _api.class_get_parent(klass) : nullptr;
        }
    }
    return nullptr;
}

- (BOOL)screenPointForPlayer:(Il2CppObject*)player class:(Il2CppClass*)klass out:(CGPoint*)point {
    if (!player || !klass || !point || !_positionReady) return NO;
    Il2CppObject *transform = [self transformForPlayer:player class:klass];
    if (!transform) return NO;

    Il2CppObject *boxedPosition = nullptr;
    if (![self runManagedCall:transform method:_transformGetPosition args:nullptr outObject:&boxedPosition] || !boxedPosition || !_api.object_unbox) return NO;
    void *raw = _api.object_unbox(boxedPosition);
    if (!raw) return NO;
    GGDVector3 world = *(GGDVector3*)raw;

    Il2CppObject *camera = nullptr;
    if (![self runManagedCall:nullptr method:_cameraGetMain args:nullptr outObject:&camera] || !camera) return NO;

    void *argv[1] = { &world };
    Il2CppObject *boxedScreen = nullptr;
    if (![self runManagedCall:camera method:_cameraWorldToScreenPoint args:argv outObject:&boxedScreen] || !boxedScreen) return NO;
    void *screenRaw = _api.object_unbox ? _api.object_unbox(boxedScreen) : nullptr;
    if (!screenRaw) return NO;
    GGDVector3 screen = *(GGDVector3*)screenRaw;
    CGSize size = UIScreen.mainScreen.bounds.size;
    if (screen.z <= 0.05f) return NO;
    CGFloat x = screen.x;
    CGFloat y = size.height - screen.y;
    if (x < -80 || y < -80 || x > size.width + 80 || y > size.height + 80) return NO;
    point->x = x;
    point->y = y;
    return YES;
}

- (BOOL)discoverStaticPlayerSourceInClass:(Il2CppClass*)klass {
    if (!klass || !_api.class_get_fields || !_api.field_get_flags || !_api.field_get_name || !_api.field_get_type) return NO;

    static const char *const collectionNames[] = {
        "players", "Players", "playerList", "PlayerList", "playersList", "allPlayers",
        "playerInfos", "PlayerInfos", "playerInfoList", "m_players", "m_playerList", "_players", nullptr
    };

    void *iter = nullptr;
    while (FieldInfo *f = _api.class_get_fields(klass, &iter)) {
        uint32_t flags = _api.field_get_flags(f);
        if (!(flags & FIELD_ATTRIBUTE_STATIC) || (flags & FIELD_ATTRIBUTE_LITERAL)) continue;
        if (!isCollectionType(_api, f)) continue;

        const char *fn = _api.field_get_name(f);
        const Il2CppType *ft = _api.field_get_type(f);
        const char *tn = (ft && _api.type_get_name) ? _api.type_get_name(ft) : nullptr;
        bool nameHit = false;
        if (fn) {
            for (int i = 0; collectionNames[i]; ++i) {
                if (strcmp(fn, collectionNames[i]) == 0) { nameHit = true; break; }
            }
            if (!nameHit && ggLowerContains(fn, "player") && (ggLowerContains(fn, "list") || ggLowerContains(fn, "players") || ggLowerContains(fn, "infos"))) {
                nameHit = true;
            }
        }
        bool typeHit = tn && (ggLowerContains(tn, "player") || ggLowerContains(tn, "goose"));
        if (nameHit || typeHit) {
            _sourceOwnerClass = klass;
            _sourceField = f;
            NSString *owner = _api.class_get_name ? [NSString stringWithUTF8String:_api.class_get_name(klass) ?: "?"] : @"?";
            _sourceDescription = [NSString stringWithFormat:@"%@.%s", owner, fn ?: "?"];
            _sourceFound = YES;
            _statusLine = [NSString stringWithFormat:@"玩家集合已定位：%@", _sourceDescription];
            return YES;
        }
    }
    return NO;
}

- (BOOL)scanForPlayerSourceBatch:(NSUInteger)budget {
    if (_sourceFound || !_runtimeReady || !_api.image_get_class_count || !_api.image_get_class) return _sourceFound;
    std::vector<const Il2CppImage*> imgs = _api.images();
    if (_imageIndex >= imgs.size()) {
        if (!_fullScan) {
            _fullScan = YES;
            _imageIndex = 0;
            _classIndex = 0;
            _currentImageClassCount = 0;
        } else {
            _statusLine = @"已扫描运行时类型，暂未找到玩家集合";
            return NO;
        }
    }

    NSUInteger done = 0;
    while (_imageIndex < imgs.size() && done < budget) {
        const Il2CppImage *img = imgs[_imageIndex];
        const char *imageName = _api.image_get_name ? _api.image_get_name(img) : "";
        bool preferred = imageName && (strstr(imageName, "Assembly-CSharp") || strstr(imageName, "HotUpdate") ||
                                       strstr(imageName, "Hotfix") || strstr(imageName, "Game") || strstr(imageName, "Goose"));
        if (!_fullScan && !preferred) {
            _imageIndex++;
            _classIndex = 0;
            _currentImageClassCount = 0;
            continue;
        }

        if (_currentImageClassCount == 0) {
            _currentImageClassCount = _api.image_get_class_count(img);
        }
        if (_classIndex >= _currentImageClassCount) {
            _imageIndex++;
            _classIndex = 0;
            _currentImageClassCount = 0;
            continue;
        }

        Il2CppClass *klass = _api.image_get_class(img, _classIndex++);
        ++done;
        if (!klass) continue;
        const char *cn = _api.class_get_name ? _api.class_get_name(klass) : "";
        if (!_fullScan && cn) {
            bool likely = ggLowerContains(cn, "player") || ggLowerContains(cn, "goose") || ggLowerContains(cn, "game") ||
                          ggLowerContains(cn, "manager") || ggLowerContains(cn, "system") || ggLowerContains(cn, "room") ||
                          ggLowerContains(cn, "meeting") || ggLowerContains(cn, "network");
            if (!likely) continue;
        }
        if ([self discoverStaticPlayerSourceInClass:klass]) return YES;
    }
    _statusLine = [NSString stringWithFormat:@"正在扫描游戏类型… %@", _fullScan ? @"全量" : @"优先集合"];
    return _sourceFound;
}

- (BOOL)readPlayerCollection:(std::vector<Il2CppObject*> &)objects {
    objects.clear();
    if (!_sourceFound || !_sourceField || !_api.field_static_get_value) return NO;

    Il2CppObject *collection = nullptr;
    _api.field_static_get_value(_sourceField, &collection);
    if (!collection || !_api.object_get_class) return NO;

    Il2CppClass *cc = _api.object_get_class(collection);
    const Il2CppType *sourceType = _api.field_get_type ? _api.field_get_type(_sourceField) : nullptr;
    const char *typeName = (sourceType && _api.type_get_name) ? _api.type_get_name(sourceType) : "";
    bool arrayType = typeName && strlen(typeName) >= 2 && typeName[strlen(typeName)-2] == '[';

    if (arrayType) {
        Il2CppArray *arr = reinterpret_cast<Il2CppArray*>(collection);
        uintptr_t count = arr->max_length;
        if (count > 64) count = 64;
        for (uintptr_t i = 0; i < count; ++i) {
            Il2CppObject *p = reinterpret_cast<Il2CppObject**>(arr->vector)[i];
            if (p) objects.push_back(p);
        }
        return !objects.empty();
    }

    static const char *const itemNames[] = { "_items", "items", nullptr };
    static const char *const sizeNames[] = { "_size", "size", nullptr };
    FieldInfo *itemsField = fieldByNames(_api, cc, itemNames, true);
    FieldInfo *sizeField = fieldByNames(_api, cc, sizeNames, true);
    if (!itemsField || !sizeField) return NO;

    Il2CppArray *items = nullptr;
    int32_t size = 0;
    _api.field_get_value(collection, itemsField, &items);
    _api.field_get_value(collection, sizeField, &size);
    if (!items) return NO;
    if (size < 0) size = 0;
    if (size > 64) size = 64;
    uintptr_t actual = items->max_length;
    if (actual < (uintptr_t)size) size = (int32_t)actual;

    for (int32_t i = 0; i < size; ++i) {
        Il2CppObject *p = reinterpret_cast<Il2CppObject**>(items->vector)[i];
        if (p) objects.push_back(p);
    }
    return !objects.empty();
}

- (void)refreshSnapshots {
    std::vector<Il2CppObject*> players;
    if (![self readPlayerCollection:players]) {
        [_snapshots removeAllObjects];
        _statusLine = [NSString stringWithFormat:@"玩家集合已定位 · 当前没有可读玩家 (%@)", _sourceDescription ?: @"?"];
        return;
    }

    [_snapshots removeAllObjects];
    static const char *const nameNames[] = {
        "Name", "name", "PlayerName", "playerName", "Nickname", "nickname", "NickName", "nickName",
        "UserName", "username", "DisplayName", "displayName", "Uid", "uid", "UID", nullptr
    };
    static const char *const nestedNameKeys[] = { "info", "profile", "data", "playerInfo", "playerData", nullptr };

    for (Il2CppObject *player : players) {
        if (!player || !_api.object_get_class) continue;
        Il2CppClass *klass = _api.object_get_class(player);
        if (!klass) continue;

        NSString *name = readStringField(_api, player, klass, nameNames);
        if (!name.length) {
            static const char *const kw[] = { "name", "nick", "username", nullptr };
            name = fallbackStringField(_api, player, klass, kw);
        }
        if (!name.length) {
            Il2CppObject *nested = readObjectFieldByKeywords(_api, player, klass, nestedNameKeys);
            if (nested && _api.object_get_class) {
                Il2CppClass *nk = _api.object_get_class(nested);
                name = readStringField(_api, nested, nk, nameNames);
                if (!name.length) {
                    static const char *const kw[] = { "name", "nick", "username", nullptr };
                    name = fallbackStringField(_api, nested, nk, kw);
                }
            }
        }
        if (!name.length) name = @"玩家";

        NSString *role = readRoleField(_api, player, klass);
        if (!role.length) {
            static const char *const kw[] = { "role", "identity", "camp", "faction", "team", nullptr };
            role = fallbackStringField(_api, player, klass, kw);
        }
        if (!role.length) {
            static const char *const nestedRoleKeys[] = { "roleInfo", "roleData", "identity", "camp", "faction", "team", "info", "data", nullptr };
            Il2CppObject *nested = readObjectFieldByKeywords(_api, player, klass, nestedRoleKeys);
            if (nested && _api.object_get_class) role = readRoleField(_api, nested, _api.object_get_class(nested));
        }
        if (!role.length) role = @"未知";

        CGPoint point = CGPointMake(0, 0);
        BOOL hasPosition = [self screenPointForPlayer:player class:klass out:&point];

        NSDictionary *snap = @{
            @"object": [NSValue valueWithPointer:player],
            @"name": name,
            @"role": role,
            @"x": @(point.x),
            @"y": @(point.y),
            @"visible": @(hasPosition),
        };
        [_snapshots addObject:snap];
    }

    if (_positionReady) {
        _statusLine = [NSString stringWithFormat:@"玩家=%lu · 身份读取=%@ · 屏幕坐标=%@",
                        (unsigned long)_snapshots.count,
                        _snapshots.count ? @"就绪" : @"等待玩家",
                        _positionReady ? @"已启用" : @"未启用"];
    } else {
        _statusLine = [NSString stringWithFormat:@"玩家=%lu · 身份读取=%@ · 坐标模块未就绪",
                        (unsigned long)_snapshots.count, _snapshots.count ? @"就绪" : @"等待玩家"];
    }
}

- (void)start {
    if (_started) return;
    _started = YES;
    _profileOK = [self checkProfile];
    if (!_profileOK) return;

    // Delay IL2CPP access. The constructor only installs UI; all runtime work waits here.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self tick];
    });
}

- (void)tick {
    if (!_profileOK || ![NSThread isMainThread]) return;

    @autoreleasepool {
        if (!_api.handle) {
            if (![self findAndResolveUnityFramework]) {
                _statusLine = @"等待 UnityFramework";
                return;
            }
        }

        if (!_attached) {
            if (!_api.attach()) {
                _statusLine = @"UnityFramework 已加载 · 等待 IL2CPP Runtime";
                return;
            }
            _attached = YES;
            _runtimeReady = YES;
            _statusLine = @"IL2CPP Runtime 已连接 · 等待玩家数据";
            [self prepareUnityMethods];
        }

        if (!_sourceFound) {
            [self scanForPlayerSourceBatch:80];
            return;
        }

        [self refreshSnapshots];
    }
}

@end

// ------------------------------ UI ----------------------------------------
static UIColor *GGDRoleColor(NSString *role) {
    NSString *s = role.lowercaseString ?: @"";
    if ([s containsString:@"鸭"] || [s containsString:@"duck"] || [s containsString:@"killer"] || [s containsString:@"assassin"]) {
        return [UIColor systemRedColor];
    }
    if ([s containsString:@"鹅"] || [s containsString:@"goose"] || [s containsString:@"crewmate"] || [s containsString:@"crew"]) {
        return [UIColor systemGreenColor];
    }
    if ([s containsString:@"中立"] || [s containsString:@"neutral"] || [s containsString:@"vulture"] || [s containsString:@"falcon"]) {
        return [UIColor systemYellowColor];
    }
    if ([s containsString:@"unknown"] || [s containsString:@"未知"]) {
        return [UIColor systemGrayColor];
    }
    return [UIColor systemPurpleColor];
}

@interface GGDMarkerView : UIView
@property(nonatomic,strong) UIView *dot;
@property(nonatomic,strong) UILabel *roleLabel;
@property(nonatomic,strong) UILabel *nameLabel;
- (void)applyRole:(NSString*)role name:(NSString*)name;
@end

@implementation GGDMarkerView
- (instancetype)init {
    if ((self = [super initWithFrame:CGRectMake(0, 0, 110, 38)])) {
        self.userInteractionEnabled = NO;
        _dot = [[UIView alloc] initWithFrame:CGRectMake(0, 9, 20, 20)];
        _dot.layer.cornerRadius = 10;
        _dot.layer.borderWidth = 1;
        _dot.layer.borderColor = UIColor.whiteColor.CGColor;
        [self addSubview:_dot];

        _roleLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, 2, 80, 22)];
        _roleLabel.font = [UIFont boldSystemFontOfSize:12];
        _roleLabel.textColor = UIColor.whiteColor;
        _roleLabel.textAlignment = NSTextAlignmentLeft;
        [self addSubview:_roleLabel];

        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, 22, 80, 14)];
        _nameLabel.font = [UIFont systemFontOfSize:9];
        _nameLabel.textColor = [UIColor colorWithWhite:0.92 alpha:0.9];
        _nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self addSubview:_nameLabel];
    }
    return self;
}
- (void)applyRole:(NSString*)role name:(NSString*)name {
    UIColor *c = GGDRoleColor(role);
    _dot.backgroundColor = c;
    _roleLabel.text = role.length ? role : @"未知";
    _nameLabel.text = name.length ? name : @"";
}
@end

@interface GGDOverlayView : UIView
@property(nonatomic,strong) UIButton *toggle;
@property(nonatomic,strong) UIView *panel;
@property(nonatomic,strong) UILabel *detail;
@property(nonatomic,strong) UIView *markers;
@property(nonatomic,strong) NSMutableArray<GGDMarkerView*> *markerViews;
@property(nonatomic,strong) NSTimer *timer;
@end

@implementation GGDOverlayView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = UIColor.clearColor;
        self.userInteractionEnabled = YES;
        _markerViews = [NSMutableArray array];

        _markers = [[UIView alloc] initWithFrame:self.bounds];
        _markers.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _markers.userInteractionEnabled = NO;
        [self addSubview:_markers];

        _toggle = [UIButton buttonWithType:UIButtonTypeSystem];
        _toggle.frame = CGRectMake(16, 90, 118, 34);
        _toggle.layer.cornerRadius = 17;
        _toggle.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.88];
        [_toggle setTitle:@"GGD 检测中" forState:UIControlStateNormal];
        [_toggle setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        _toggle.titleLabel.font = [UIFont boldSystemFontOfSize:12];
        [self addSubview:_toggle];
        [_toggle addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
        [_toggle addGestureRecognizer:pan];

        _panel = [[UIView alloc] initWithFrame:CGRectMake(16, 130, 320, 220)];
        _panel.backgroundColor = [UIColor colorWithWhite:0.035 alpha:0.95];
        _panel.layer.cornerRadius = 14;
        _panel.hidden = YES;
        _panel.userInteractionEnabled = YES;
        [self addSubview:_panel];

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(14, 10, 290, 24)];
        title.text = @"GGD Identity Overlay";
        title.textColor = UIColor.whiteColor;
        title.font = [UIFont boldSystemFontOfSize:15];
        [_panel addSubview:title];

        _detail = [[UILabel alloc] initWithFrame:CGRectMake(14, 38, 292, 170)];
        _detail.numberOfLines = 0;
        _detail.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
        _detail.textColor = [UIColor colorWithWhite:0.88 alpha:1];
        [_panel addSubview:_detail];

        _timer = [NSTimer timerWithTimeInterval:0.20 target:self selector:@selector(refresh) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    if (hit == self) return nil;
    if (hit && hit != _toggle && ![hit isDescendantOfView:_panel]) {
        return nil;
    }
    return hit;
}

- (void)togglePanel { _panel.hidden = !_panel.hidden; }

- (void)move:(UIPanGestureRecognizer*)g {
    CGPoint p = [g translationInView:self];
    CGRect r = _toggle.frame;
    CGFloat maxX = MAX(0.0, self.bounds.size.width - r.size.width);
    CGFloat maxY = MAX(40.0, self.bounds.size.height - r.size.height);
    r.origin.x = MIN(maxX, MAX(0.0, r.origin.x + p.x));
    r.origin.y = MIN(maxY, MAX(40.0, r.origin.y + p.y));
    _toggle.frame = r;
    _panel.frame = CGRectMake(r.origin.x, r.origin.y + r.size.height + 8, _panel.frame.size.width, _panel.frame.size.height);
    [g setTranslation:CGPointMake(0, 0) inView:self];
}

- (GGDMarkerView*)markerAtIndex:(NSUInteger)i {
    while (_markerViews.count <= i) {
        GGDMarkerView *m = [GGDMarkerView new];
        [_markers addSubview:m];
        [_markerViews addObject:m];
    }
    return _markerViews[i];
}

- (void)refreshMarkers:(NSArray<NSDictionary*>*)snapshots {
    NSUInteger visible = 0;
    for (NSDictionary *snap in snapshots) {
        if (![snap[@"visible"] boolValue]) continue;
        GGDMarkerView *m = [self markerAtIndex:visible++];
        NSString *role = snap[@"role"];
        NSString *name = snap[@"name"];
        [m applyRole:role name:name];
        CGPoint p = CGPointMake([snap[@"x"] doubleValue], [snap[@"y"] doubleValue]);
        m.center = CGPointMake(p.x, p.y);
        m.hidden = NO;
    }
    for (NSUInteger i = visible; i < _markerViews.count; ++i) _markerViews[i].hidden = YES;
}

- (void)refresh {
    GGDCore *c = GGDCore.shared;
    [c tick];
    BOOL ready = c.il2cppReady;
    [_toggle setTitle:(ready ? @"GGD 已加载" : @"GGD 检测中") forState:UIControlStateNormal];

    NSArray<NSDictionary*> *snaps = c.snapshots;
    NSMutableString *text = [NSMutableString stringWithFormat:
                              @"注入: YES\nIL2CPP: %@\n玩家集合: %@\n玩家数: %lu\n状态: %@",
                              ready ? @"OK" : @"WAIT",
                              c.gameReady ? @"OK" : @"WAIT",
                              (unsigned long)snaps.count,
                              c.statusLine];
    NSUInteger shown = 0;
    for (NSDictionary *snap in snaps) {
        if (shown++ >= 8) break;
        [text appendFormat:@"\n%@ | %@", snap[@"name"] ?: @"?", snap[@"role"] ?: @"未知"];
    }
    _detail.text = text;
    [self refreshMarkers:snaps];
}

- (void)dealloc {
    [_timer invalidate];
}
@end

// ------------------------- Overlay installation ---------------------------
static GGDOverlayView *gOverlay = nil;

static UIWindow *GGDFindGameWindow(void) {
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (scene.activationState == UISceneActivationStateUnattached) continue;
            if (![scene isKindOfClass:[UIWindowScene class]]) continue;
            UIWindowScene *ws = (UIWindowScene *)scene;
            for (UIWindow *window in ws.windows) {
                if (!window.hidden && window.alpha > 0.01 && window.rootViewController) return window;
            }
        }
    }
    return nil;
}

static void GGDInstallOverlay(void) {
    if (gOverlay) return;
    UIWindow *window = GGDFindGameWindow();
    if (!window) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            GGDInstallOverlay();
        });
        return;
    }

    gOverlay = [[GGDOverlayView alloc] initWithFrame:window.bounds];
    gOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [window addSubview:gOverlay];
    [GGDCore.shared start];
}

__attribute__((constructor))
static void GGDFinalConstructor(void) {
    // Constructor deliberately does not resolve IL2CPP, enumerate assemblies, or call Unity.
    dispatch_async(dispatch_get_main_queue(), ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            GGDInstallOverlay();
        });
    });
}
