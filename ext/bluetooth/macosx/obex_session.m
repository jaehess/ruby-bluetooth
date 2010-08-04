#import "ruby_bluetooth.h"

extern VALUE rbt_cBluetoothError;
extern VALUE rbt_cBluetoothOBEXSession;

void rbt_obex_session_free(IOBluetoothOBEXSession *session) {
    if (session)
        [session release];
}

VALUE rbt_obex_session_open_transport(VALUE self) {
    IOBluetoothOBEXSession *obex_session;
    NSAutoreleasePool *pool;
    IOReturn error;
    OBEXStatus *status;

    pool = [[NSAutoreleasePool alloc] init];

    Data_Get_Struct(self, IOBluetoothOBEXSession, obex_session);

    if (!obex_session) {
        [pool release];
        rb_raise(rbt_cBluetoothError, "session terminated");
    }

    if ([obex_session hasOpenTransportConnection]) {
        [pool release];
        return Qtrue;
    }

    status = [[OBEXStatus alloc] init];

    error = [obex_session
        openTransportConnection: @selector(transportConnectionSelector:status:)
                 selectorTarget: status
                         refCon: (void *)self];

    CFRunLoopRun();

    error = (IOReturn)NUM2LONG(rb_iv_get(self,
                "@open_transport_connection_status"));

    rbt_check_obex_status(error, pool);

    [pool release];

    return Qtrue;
}

@implementation OBEXStatus

- (void) transportConnectionSelector: (id)refCon
                              status: (OBEXError)error {
    VALUE session = (VALUE)refCon;

    CFRunLoopStop(CFRunLoopGetCurrent());

    rb_iv_set(session, "@open_transport_connection_status", LONG2NUM(error));
}
@end

