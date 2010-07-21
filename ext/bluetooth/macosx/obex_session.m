#import "ruby_bluetooth.h"

extern VALUE rbt_cBluetoothOBEXSession;

void rbt_obex_session_free(IOBluetoothOBEXSession *session) {
    if (session)
        [session release];
}

