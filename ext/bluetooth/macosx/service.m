#import "ruby_bluetooth.h"

extern VALUE rbt_cBluetoothServiceUUID;

VALUE rbt_service_data_element_to_ruby(IOBluetoothSDPDataElement *elem) {
    VALUE attr;

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
            attr = rb_str_new((char *)[[elem getUUIDValue] bytes], 16);
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
                    ID2SYM(rb_intern("sequence")),
                    [elem getArrayValue]);
            break;
        case 7: // Data element alternative
            attr = rbt_service_data_elements_to_ruby(
                    ID2SYM(rb_intern("alternative")),
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

VALUE rbt_service_data_elements_to_ruby(VALUE type, NSArray *data_elements) {
    VALUE attrs = rb_ary_new();

    for (IOBluetoothSDPDataElement *element in data_elements) {
        rb_ary_push(attrs, rbt_service_data_element_to_ruby(element));
    }

    rb_iv_set(attrs, "@type", type); // HACK make a real object

    return attrs;
}

