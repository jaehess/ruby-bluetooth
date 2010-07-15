#import "ruby_bluetooth.h"

extern VALUE rbt_cBluetoothService;
extern VALUE rbt_cBluetoothServiceAlternative;
extern VALUE rbt_cBluetoothServiceSequence;
extern VALUE rbt_cBluetoothServiceUUID;

VALUE rbt_service_data_element_to_ruby(IOBluetoothSDPDataElement *elem) {
    VALUE attr, tmp;
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

VALUE rbt_service_from_record(IOBluetoothSDPServiceRecord *service_record) {
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

    args = rb_ary_new3(2, name, attrs);

    return rb_class_new_instance(2, RARRAY_PTR(args), rbt_cBluetoothService);
}

