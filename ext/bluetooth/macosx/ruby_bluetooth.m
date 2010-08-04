#import "ruby_bluetooth.h"

VALUE rbt_mBluetooth = Qnil;

VALUE rbt_cBluetoothDevice = Qnil;
VALUE rbt_cBluetoothERRORS = Qnil;
VALUE rbt_cBluetoothError = Qnil;
VALUE rbt_cBluetoothOBEXError = Qnil;
VALUE rbt_cBluetoothOBEXSession = Qnil;
VALUE rbt_cBluetoothService = Qnil;
VALUE rbt_cBluetoothServiceAlternative = Qnil;
VALUE rbt_cBluetoothServiceSequence = Qnil;
VALUE rbt_cBluetoothServiceUUID = Qnil;

void Init_bluetooth() {
    rbt_mBluetooth = rb_define_module("Bluetooth");

    rbt_cBluetoothError = rb_const_get(rbt_mBluetooth, rb_intern("Error"));
    rbt_cBluetoothOBEXError = rb_const_get(rbt_mBluetooth,
            rb_intern("OBEXError"));

    rb_define_singleton_method(rbt_mBluetooth, "scan", rbt_scan, 0);

    rbt_cBluetoothDevice = rb_const_get(rbt_mBluetooth, rb_intern("Device"));

    rb_define_method(rbt_cBluetoothDevice, "connect",
            rbt_device_open_connection, 0);
    rb_define_method(rbt_cBluetoothDevice, "pair", rbt_device_pair, 0);
    rb_define_method(rbt_cBluetoothDevice, "request_name",
            rbt_device_request_name, 0);
    rb_define_method(rbt_cBluetoothDevice, "services",
            rbt_device_services, 0);
    rb_define_method(rbt_cBluetoothDevice, "service",
            rbt_device_get_service, 1);

    rb_define_method(rbt_cBluetoothDevice, "_link_quality",
            rbt_device_link_quality, 0);
    rb_define_method(rbt_cBluetoothDevice, "_rssi", rbt_device_rssi, 0);

    rbt_cBluetoothOBEXSession = rb_const_get(rbt_mBluetooth,
            rb_intern("OBEXSession"));

    rb_define_method(rbt_cBluetoothOBEXSession, "open_transport",
            rbt_obex_session_open_transport, 0);

    rbt_cBluetoothService = rb_const_get(rbt_mBluetooth, rb_intern("Service"));

    rb_define_method(rbt_cBluetoothService, "obex_session",
            rbt_service_obex_session, 0);

    rbt_cBluetoothServiceAlternative = rb_const_get(rbt_cBluetoothService,
            rb_intern("Alternative"));
    rbt_cBluetoothServiceSequence = rb_const_get(rbt_cBluetoothService,
            rb_intern("Sequence"));
    rbt_cBluetoothServiceUUID = rb_const_get(rbt_cBluetoothService,
            rb_intern("UUID"));

    rbt_init_error();
    rbt_init_obex_error();
}

