#import "ruby_bluetooth.h"

#import <IOBluetooth/objc/IOBluetoothDevicePair.h>

extern VALUE rbt_cBluetoothService;

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

VALUE rbt_device_get_service(VALUE self, VALUE uuid) {
    IOBluetoothDevice *device;
    IOBluetoothSDPServiceRecord *service_record;
    IOBluetoothSDPUUID *service_uuid;
    NSAutoreleasePool *pool;
    VALUE service = Qnil;

    pool = [[NSAutoreleasePool alloc] init];

    uuid = rb_funcall(uuid, rb_intern("to_uuid_bytes"), 0);

    service_uuid = [IOBluetoothSDPUUID alloc];
    [service_uuid initWithBytes: (void *)StringValuePtr(uuid)
                         length: RSTRING_LEN(uuid)];

    device = rbt_device_get(self);

    service_record = [device getServiceRecordForUUID: service_uuid];

    if (service_record != nil)
        service = rbt_service_from_record(service_record);

    [pool release];

    return service;
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

    rbt_check_status(status, nil);

    return rb_iv_get(self, "@link_quality");
}

VALUE rbt_device_open_connection(VALUE self) {
    IOBluetoothDevice *device;
    IOReturn status;
    NSAutoreleasePool *pool;
    VALUE result;

    pool = [[NSAutoreleasePool alloc] init];

    device = rbt_device_get(self);

    if (![device isConnected]) {
        status = [device openConnection];

        rbt_check_status(status, pool);
    }

    result = rb_yield(Qundef);

    status = [device closeConnection];

    [pool release];

    rbt_check_status(status, nil);

    return result;
}

VALUE rbt_device_pair(VALUE self) {
    PairingDelegate *delegate;
    IOBluetoothDevice *device;
    IOBluetoothDevicePair *device_pair;
    IOReturn status;
    NSAutoreleasePool *pool;

    pool = [[NSAutoreleasePool alloc] init];

    device = rbt_device_get(self);

    delegate = [[PairingDelegate alloc] init];
    delegate.device = self;

    device_pair = [IOBluetoothDevicePair pairWithDevice: device];
    [device_pair setDelegate: delegate];

    status = [device_pair start];

    rbt_check_status(status, pool);

    CFRunLoopRun();

    [pool release];

    status = (IOReturn)NUM2INT(rb_iv_get(self, "@pair_error"));

    rbt_check_status(status, nil);

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

    rbt_check_status(status, pool);

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

    rbt_check_status(status, nil);

    return rb_iv_get(self, "@rssi");
}

VALUE rbt_device_services(VALUE self) {
    IOBluetoothDevice *device;
    IOReturn status;
    NSArray *service_records;
    NSAutoreleasePool *pool;
    SDPQueryResult *result;
    VALUE services;

    pool = [[NSAutoreleasePool alloc] init];

    device = rbt_device_get(self);

    service_records = [device getServices];

    if (service_records == nil) {
        result = [[SDPQueryResult alloc] init];
        result.device = self;

        [device performSDPQuery: result];

        CFRunLoopRun();

        status = (IOReturn)NUM2INT(rb_iv_get(self, "@sdp_query_error"));
        rbt_check_status(status, pool);

        service_records = [device getServices];
    }

    if (service_records == nil)
        return Qnil;

    services = rb_ary_new();

    for (IOBluetoothSDPServiceRecord *service_record in service_records) {
        rb_ary_push(services, rbt_service_from_record(service_record));
    }

    [pool release];

    return services;
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

@implementation SDPQueryResult

- (VALUE) device {
    return device;
}

- (void) setDevice: (VALUE)input {
    device = input;
}

- (void) sdpQueryComplete: (IOBluetoothDevice*) bt_device
                   status: (IOReturn) status {
    CFRunLoopStop(CFRunLoopGetCurrent());

    rb_iv_set(device, "@sdp_query_error", INT2NUM(status));
}

@end


