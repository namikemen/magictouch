#ifndef MultitouchBridge_h
#define MultitouchBridge_h

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

typedef struct {
    float x;
    float y;
} MTPoint;

typedef struct {
    MTPoint position;
    MTPoint velocity;
} MTVector;

typedef enum {
    MTTouchStateNotTracking = 0,
    MTTouchStateStartInRange = 1,
    MTTouchStateHoverInRange = 2,
    MTTouchStateMakeTouch = 3,
    MTTouchStateTouching = 4,
    MTTouchStateBreakTouch = 5,
    MTTouchStateLingerInRange = 6,
    MTTouchStateOutOfRange = 7
} MTTouchState;

typedef struct {
    int frame;
    double timestamp;
    int identifier;
    MTTouchState state;
    int fingerId;
    int handId;
    MTVector normalizedPosition;
    float totalSize;
    float pressure;
    float angle;
    float majorAxis;
    float minorAxis;
    MTVector absolutePosition;
    int unknown1;
    int unknown2;
    float density;
} MTTouch;

typedef void *MTDeviceRef;

typedef int (*MTContactCallbackFunction)(MTDeviceRef device, MTTouch *touches, int numTouches, double timestamp, int frame);

#ifdef __cplusplus
extern "C" {
#endif

CFMutableArrayRef MTDeviceCreateList(void);
void MTRegisterContactFrameCallback(MTDeviceRef device, MTContactCallbackFunction callback);
void MTUnregisterContactFrameCallback(MTDeviceRef device, MTContactCallbackFunction callback);
void MTDeviceStart(MTDeviceRef device, int mode);
void MTDeviceStop(MTDeviceRef device);
bool MTDeviceIsAvailable(void);
bool MTDeviceIsBuiltIn(MTDeviceRef device);
int MTDeviceGetFamilyID(MTDeviceRef device);

// Robust Swift helper functions
CFIndex MTBridgeGetDeviceCount(void);
MTDeviceRef MTBridgeGetDeviceAtIndex(CFIndex index);
bool MTBridgeDeviceIsBuiltIn(MTDeviceRef device);
void MTBridgeStartDevice(MTDeviceRef device, MTContactCallbackFunction callback);
void MTBridgeStopDevice(MTDeviceRef device, MTContactCallbackFunction callback);
void MTBridgeRefreshDevices(void);

#ifdef __cplusplus
}
#endif

#endif /* MultitouchBridge_h */
