#import "MultitouchBridge.h"

static CFMutableArrayRef sDeviceList = NULL;

static void ensureDeviceList(void) {
    if (sDeviceList) {
        CFRelease(sDeviceList);
        sDeviceList = NULL;
    }
    sDeviceList = MTDeviceCreateList();
}

CFIndex MTBridgeGetDeviceCount(void) {
    ensureDeviceList();
    if (!sDeviceList) return 0;
    return CFArrayGetCount(sDeviceList);
}

MTDeviceRef MTBridgeGetDeviceAtIndex(CFIndex index) {
    if (!sDeviceList) {
        ensureDeviceList();
    }
    if (!sDeviceList) return NULL;
    if (index < 0 || index >= CFArrayGetCount(sDeviceList)) return NULL;
    return (MTDeviceRef)CFArrayGetValueAtIndex(sDeviceList, index);
}

bool MTBridgeDeviceIsBuiltIn(MTDeviceRef device) {
    if (!device) return false;
    return MTDeviceIsBuiltIn(device);
}

void MTBridgeStartDevice(MTDeviceRef device, MTContactCallbackFunction callback) {
    if (!device || !callback) return;
    MTRegisterContactFrameCallback(device, callback);
    MTDeviceStart(device, 0);
}

void MTBridgeStopDevice(MTDeviceRef device, MTContactCallbackFunction callback) {
    if (!device) return;
    if (callback) {
        MTUnregisterContactFrameCallback(device, callback);
    }
    MTDeviceStop(device);
}
