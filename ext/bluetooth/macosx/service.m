#import "ruby_bluetooth.h"

extern VALUE rbt_cBluetoothOBEXSession;
extern VALUE rbt_cBluetoothService;
extern VALUE rbt_cBluetoothServiceAlternative;
extern VALUE rbt_cBluetoothServiceSequence;
extern VALUE rbt_cBluetoothServiceUUID;

VALUE rbt_service_data_element_to_ruby(IOBluetoothSDPDataElement *elem) {
    VALUE attr;
    IOBluetoothSDPUUID *uuid = nil;

    switch ([elem getTypeDescriptor]) {
        case 0: // Nil
            attr = Qnil;
            break;
        case 1: // Unsigned integer
            attr = ULONG2NUM([[elem getNumberValue] unsignedLongValue]);
            break;
        case 2: // Signed twos-complement integer
            attr = LONG2NUM([[elem getNumberValue] longValue]);
            break;
        case 3: // UUID
            uuid = [elem getUUIDValue];
            attr = rb_str_new((char *)[uuid bytes], [uuid length]);

            attr = rb_class_new_instance(1, &attr, rbt_cBluetoothServiceUUID);
            break;
        case 4: // String
            attr = rb_str_new2([[elem getStringValue] UTF8String]);
            break;
        case 5: // Boolean
            attr = ([elem getNumberValue] == 0) ? Qfalse : Qtrue;
            break;
        case 6: // Data element sequence
            attr = rbt_service_data_elements_to_ruby(
                    rbt_cBluetoothServiceSequence,
                    [elem getArrayValue]);
            break;
        case 7: // Data element alternative
            attr = rbt_service_data_elements_to_ruby(
                    rbt_cBluetoothServiceAlternative,
                    [elem getArrayValue]);
            break;
        case 8: // URL
            attr = rb_str_new2([[elem getStringValue] UTF8String]);
            attr = rb_funcall(rb_const_get(rb_cObject,
                        rb_intern("URI")),
                    rb_intern("parse"), 1, attr);
            break;
        default:
            attr = ID2SYM(rb_intern("unknown_data_element"));
    }

    return attr;
}

VALUE rbt_service_data_elements_to_ruby(VALUE klass, NSArray *data_elements) {
    VALUE attrs = rb_ary_new();

    for (IOBluetoothSDPDataElement *element in data_elements) {
        rb_ary_push(attrs, rbt_service_data_element_to_ruby(element));
    }
    attrs = rb_class_new_instance(1, &attrs, klass);

    return attrs;
}

VALUE rbt_service_from_record(VALUE device, IOBluetoothSDPServiceRecord *service_record) {
    VALUE args, attrs, name;
    NSString *str = [service_record getServiceName];

    if (str) {
        name = rb_str_new2([str UTF8String]);
    } else {
        name = rb_str_new2("[unknown]");
    }

    attrs = rb_hash_new();

    for (id key in [service_record attributes]) {
        VALUE attr_id = LONG2NUM([key longValue]);
        IOBluetoothSDPDataElement *elem =
            [[service_record attributes] objectForKey: key];

        VALUE attr = rbt_service_data_element_to_ruby(elem);

        rb_hash_aset(attrs, attr_id, attr);
    }

    args = rb_ary_new3(3, name, attrs, device);

    return rb_class_new_instance(3, RARRAY_PTR(args), rbt_cBluetoothService);
}

static VALUE session_cleanup(VALUE data) {
    IOBluetoothOBEXSession *obex_session;
    NSAutoreleasePool *pool;
    VALUE session;

    session      = RARRAY_PTR(data)[0];
    obex_session = (IOBluetoothOBEXSession *)RARRAY_PTR(data)[1];
    pool         = (NSAutoreleasePool *)RARRAY_PTR(data)[2];

    [obex_session release];
    [pool release];

    DATA_PTR(session) = NULL;

    return Qnil;
}

VALUE rbt_service_obex_session(VALUE self) {
    IOBluetoothOBEXSession *obex_session;
    IOBluetoothSDPServiceRecord *service_record;
    NSAutoreleasePool *pool;
    VALUE device, session, uuid, uuids;

    uuids = rb_funcall(self, rb_intern("service_class_id_list"), 0);
    uuids = rb_ary_to_ary(uuids);

    if (RARRAY_LEN(uuids) == 0)
        rb_raise(rb_eRuntimeError, "not properly initialized?");

    uuid = RARRAY_PTR(uuids)[0];

    device = rb_funcall(self, rb_intern("device"), 0);

    pool = [[NSAutoreleasePool alloc] init];

    service_record = rbt_device_get_service_record(device, uuid);

    obex_session = [IOBluetoothOBEXSession withSDPServiceRecord:
        service_record];

    [obex_session retain];

    session = Data_Wrap_Struct(rbt_cBluetoothOBEXSession, NULL,
            rbt_obex_session_free, obex_session);

    if (rb_block_given_p()) {
        VALUE data;

        data = rb_ary_new2(2); // It's just a big truck!
        RARRAY_PTR(data)[0] = session;
        RARRAY_PTR(data)[1] = (VALUE)obex_session;
        RARRAY_PTR(data)[2] = (VALUE)pool;

        rb_ensure(rb_yield, session, session_cleanup, data);

        return Qnil;
    } else {
        [pool release];

        return session;
    }
}

