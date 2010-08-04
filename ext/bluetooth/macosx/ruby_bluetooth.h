#import <Cocoa/Cocoa.h>

#import <IOBluetooth/IOBluetoothUserLib.h>
#import <IOBluetooth/objc/IOBluetoothDevice.h>
#import <IOBluetooth/objc/IOBluetoothDeviceInquiry.h>
#import <IOBluetooth/objc/IOBluetoothHostController.h>
#import <IOBluetooth/objc/IOBluetoothOBEXSession.h>
#import <IOBluetooth/objc/IOBluetoothSDPDataElement.h>
#import <IOBluetooth/objc/IOBluetoothSDPServiceRecord.h>
#import <IOBluetooth/objc/IOBluetoothSDPUUID.h>

#import <ruby.h>

void init_rbt_error();

void rbt_check_status(IOReturn status, NSAutoreleasePool *pool);

VALUE rbt_device_link_quality(VALUE);
VALUE rbt_device_open_connection(VALUE);
VALUE rbt_device_pair(VALUE);
VALUE rbt_device_request_name(VALUE);
VALUE rbt_device_rssi(VALUE);
VALUE rbt_device_get_service(VALUE, VALUE);
IOBluetoothSDPServiceRecord *rbt_device_get_service_record(VALUE, VALUE);

VALUE rbt_device_services(VALUE);

VALUE rbt_scan(VALUE);

void rbt_obex_session_free(IOBluetoothOBEXSession *);
VALUE rbt_obex_session_open_transport(VALUE);

VALUE rbt_service_data_element_to_ruby(IOBluetoothSDPDataElement *);
VALUE rbt_service_data_elements_to_ruby(VALUE, NSArray *);
VALUE rbt_service_from_record(VALUE, IOBluetoothSDPServiceRecord *);
VALUE rbt_service_obex_session(VALUE);

@interface BluetoothDeviceScanner : NSObject {
	IOBluetoothDeviceInquiry *      _inquiry;
	BOOL                            _busy;
	VALUE                           _devices;
}

- (void) stopSearch;
- (IOReturn) startSearch;
- (VALUE) devices;
@end

@interface HCIDelegate : NSObject {
    VALUE device;
}

- (VALUE) device;
- (void) setDevice: (VALUE)input;

- (void) controllerClassOfDeviceReverted: (id)sender;
- (void) readLinkQualityForDeviceComplete: (id)controller
                                   device: (IOBluetoothDevice*)bt_device
                                     info: (BluetoothHCILinkQualityInfo*)info
                                    error: (IOReturn)error;
- (void) readRSSIForDeviceComplete: (id)controller
                            device: (IOBluetoothDevice*)bt_device
                              info: (BluetoothHCIRSSIInfo*)info
                             error: (IOReturn)error;
@end

@interface PairingDelegate : NSObject {
	VALUE device;
}

- (VALUE) device;
- (void) setDevice: (VALUE)input;

- (void) devicePairingConnecting: (id)sender;
- (void) devicePairingStarted: (id)sender;
- (void) devicePairingFinished: (id)sender
			 error: (IOReturn)error;

- (void) devicePairingPasskeyNotification: (id)sender
                                  passkey: (BluetoothPasskey)passkey;
- (void) devicePairingPINCodeRequest: (id)sender;
- (void) devicePairingUserConfirmationRequest: (id)sender
                                 numericValue: (BluetoothNumericValue)numericValue;
@end

@interface SDPQueryResult : NSObject {
    VALUE device;
}

- (VALUE) device;
- (void) setDevice: (VALUE)input;

- (void) sdpQueryComplete: (IOBluetoothDevice *)bt_device
                   status: (IOReturn)status;

@end

