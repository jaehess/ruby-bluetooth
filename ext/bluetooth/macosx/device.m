#import "ruby_bluetooth.h"

#import <IOBluetooth/objc/IOBluetoothDevicePair.h>

static IOBluetoothDevice *rbt_device_get(VALUE self) {
    BluetoothDeviceAddress address;
    IOBluetoothDevice *device;
    VALUE address_bytes;
    char * tmp = NULL;

    address_bytes = rb_funcall(self, rb_intern("address_bytes"), 0);

    if (RSTRING_LEN(address_bytes) != 6) {
        VALUE inspect = rb_inspect(address_bytes);
        rb_raise(rb_eArgError, "%s doesn't look like a bluetooth address",
                 StringValueCStr(inspect));
    }

    tmp = StringValuePtr(address_bytes);

    memcpy(address.data, tmp, 6);

    device = [IOBluetoothDevice withAddress: &address];

    return device;
}

VALUE rbt_device_link_quality(VALUE self) {
    HCIDelegate *delegate;
    IOBluetoothDevice *device;
    IOBluetoothHostController *controller;
    IOReturn status;
    NSAutoreleasePool *pool;

    pool = [[NSAutoreleasePool alloc] init];

    device = rbt_device_get(self);

    delegate = [[HCIDelegate alloc] init];
    delegate.device = self;

    controller = [IOBluetoothHostController defaultController];
    [controller setDelegate: delegate];

    status = [controller readLinkQualityForDevice: device];

    if (status != noErr) {
        [pool release];
        return Qfalse;
    }

    CFRunLoopRun();

    [pool release];

    status = (IOReturn)NUM2INT(rb_iv_get(self, "@link_quality_error"));

    if (status != kIOReturnSuccess)
        return Qfalse;

    return rb_iv_get(self, "@link_quality");
}

VALUE rbt_device_open_connection(VALUE self) {
    IOBluetoothDevice *device;
    IOReturn status;
    NSAutoreleasePool *pool;
    VALUE result;

    pool = [[NSAutoreleasePool alloc] init];

    device = rbt_device_get(self);

    status = [device openConnection];

    if (status != kIOReturnSuccess)
        return Qnil;

    result = rb_yield(Qundef);

    status = [device closeConnection];

    [pool release];

    if (status != kIOReturnSuccess)
        return Qnil;

    return result;
}

VALUE rbt_device_pair(VALUE self) {
    PairingDelegate *delegate;
    IOBluetoothDevice *device;
    IOBluetoothDevicePair *device_pair;
    IOReturn status;
    NSAutoreleasePool *pool;
    char * tmp = NULL;

    pool = [[NSAutoreleasePool alloc] init];

    device = rbt_device_get(self);

    delegate = [[PairingDelegate alloc] init];
    delegate.device = self;

    device_pair = [IOBluetoothDevicePair pairWithDevice: device];
    [device_pair setDelegate: delegate];

    status = [device_pair start];

    if (status != kIOReturnSuccess) {
        [pool release];
        return Qfalse;
    }

    CFRunLoopRun();

    [pool release];

    status = (IOReturn)NUM2INT(rb_iv_get(self, "@pair_error"));

    if (status != kIOReturnSuccess)
        return Qfalse;

    return Qtrue;
}

VALUE rbt_device_request_name(VALUE self) {
    IOBluetoothDevice *device;
    IOReturn status;
    VALUE name;
    NSAutoreleasePool *pool;

    pool = [[NSAutoreleasePool alloc] init];

    device = rbt_device_get(self);

    status = [device remoteNameRequest: nil];

    if (status != kIOReturnSuccess)
        return Qnil;

    name = rb_str_new2([[device name] UTF8String]);

    [pool release];

    return name;
}

VALUE rbt_device_rssi(VALUE self) {
    HCIDelegate *delegate;
    IOBluetoothDevice *device;
    IOBluetoothHostController *controller;
    IOReturn status;
    NSAutoreleasePool *pool;

    pool = [[NSAutoreleasePool alloc] init];

    device = rbt_device_get(self);

    delegate = [[HCIDelegate alloc] init];
    delegate.device = self;

    controller = [IOBluetoothHostController defaultController];
    [controller setDelegate: delegate];

    status = [controller readRSSIForDevice: device];

    if (status != noErr) {
        [pool release];
        return Qfalse;
    }

    CFRunLoopRun();

    [pool release];

    status = (IOReturn)NUM2INT(rb_iv_get(self, "@rssi_error"));

    if (status != kIOReturnSuccess)
        return Qfalse;

    return rb_iv_get(self, "@rssi");
}

@implementation PairingDelegate

- (VALUE) device {
    return device;
}

- (void) setDevice: (VALUE)input {
    device = input;
}

- (void) devicePairingConnecting: (id)sender {
}

- (void) devicePairingStarted: (id)sender {
}

- (void) devicePairingFinished: (id)sender
                         error: (IOReturn)error {
    CFRunLoopStop(CFRunLoopGetCurrent());

    rb_iv_set(device, "@pair_error", INT2NUM(error));
}

- (void) devicePairingPasskeyNotification: (id)sender
				  passkey: (BluetoothPasskey)passkey {
    printf("passkey %ld!  I don't know what to do!", (unsigned long)passkey);
}

- (void) devicePairingPINCodeRequest: (id)sender {
    puts("PIN code! I don't know what to do!");
}

- (void) devicePairingUserConfirmationRequest: (id)sender
				 numericValue: (BluetoothNumericValue)numericValue {
    BOOL confirm;
    VALUE result = Qtrue;
    VALUE numeric_value = ULONG2NUM((unsigned long)numericValue);
    VALUE callback = rb_iv_get(device, "@pair_confirmation_callback");

    if (RTEST(callback))
        result = rb_funcall(callback, rb_intern("call"), 1, numeric_value);

    if (RTEST(result)) {
        confirm = YES;
    } else {
        confirm = NO;
    }

    [sender replyUserConfirmation: confirm];
}

@end

