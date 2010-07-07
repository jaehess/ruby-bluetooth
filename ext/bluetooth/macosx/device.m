#import "ruby_bluetooth.h"

#import <IOBluetooth/objc/IOBluetoothDevicePair.h>
#import <IOBluetooth/objc/IOBluetoothSDPDataElement.h>
#import <IOBluetooth/objc/IOBluetoothSDPServiceRecord.h>

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
        VALUE args, attrs, name, service;
        NSString *str = [service_record getServiceName];

        if (str) {
            name = rb_str_new2([str UTF8String]);
        } else {
            name = rb_str_new2("[unknown]");
        }

        attrs = rb_hash_new();

        for (id key in [service_record attributes]) {
            VALUE attr;
            VALUE attr_id = LONG2NUM([key longValue]);
            IOBluetoothSDPDataElement *elem =
                [[service_record attributes] objectForKey: key];

            switch ([elem getTypeDescriptor]) {
                case 0:
                    attr = Qnil;
                    break;
                case 1:
                    attr = ULONG2NUM([[elem getNumberValue] unsignedLongValue]);
                    break;
                case 2:
                    attr = LONG2NUM([[elem getNumberValue] longValue]);
                    break;
                case 3: // UUID
                    attr = rb_str_new((char *)[[elem getUUIDValue] bytes], 16);
                    break;
                case 4:
                    attr = rb_str_new2([[elem getStringValue] UTF8String]);
                    break;
                case 5:
                    attr = ([elem getNumberValue] == 0) ? Qfalse : Qtrue;
                    break;
                case 6:
                    attr = ID2SYM(rb_intern("unhandled_sequence"));
                    break;
                case 7:
                    attr = ID2SYM(rb_intern("unhandled_alternative"));
                    break;
                case 8:
                    attr = rb_str_new2([[elem getStringValue] UTF8String]);
                    attr = rb_funcall(rb_const_get(rb_cObject,
                                rb_intern("URI")),
                            rb_intern("parse"), 1, attr);
                    break;
                default:
                    continue;
            }

            rb_hash_aset(attrs, attr_id, attr);
        }

        args = rb_ary_new3(2, name, attrs);

        service = rb_class_new_instance(2, RARRAY_PTR(args),
                rbt_cBluetoothService);

        rb_ary_push(services, service);
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


