#import "ruby_bluetooth.h"

extern VALUE rbt_cBluetoothOBEXSession;

void rbt_obex_session_free(IOBluetoothOBEXSession *session) {
    if (session)
        [session release];
}

VALUE rbt_obex_session_open_transport(VALUE self) {
    IOBluetoothOBEXSession *obex_session;
    NSAutoreleasePool *pool;

    [[NSAutoreleasePool alloc] init];

    [pool release];

    return Qnil;
}

