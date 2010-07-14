require 'uri'

class Bluetooth::Service

  ATTRIBUTES = {
    :service_record_handle               => 0x0000,
    :service_class_id_list               => 0x0001,
    :service_record_state                => 0x0002,
    :service_id                          => 0x0003,
    :protocol_descriptor_list            => 0x0004,
    :browse_group_list                   => 0x0005,
    :language_base_attribute_id_list     => 0x0006,
    :service_info_time_to_live           => 0x0007,
    :service_availability                => 0x0008,
    :bluetooth_profile_descriptor_list   => 0x0009,
    :documentation_url                   => 0x000a,
    :client_executable_url               => 0x000b,
    :icon_url                            => 0x000c,
    :additional_protocol_descriptor_list => 0x000d,
  }

  ATTRIBUTES.each do |name, attr_id|
    define_method name do @attributes[attr_id] end
  end

  attr_reader :name
  attr_reader :attributes

  def initialize name, attributes
    @name = name
    @attributes = attributes
  end

  alias to_s name # :nodoc:

  def inspect
    id2attr = ATTRIBUTES.invert

    attrs = @attributes.sort.map do |attr_id, value|
      [(id2attr[attr_id] || ("0x%04x" % attr_id)), value.inspect].join ': '
    end.join ', '

    "#<%s:0x%x %s - %s>" % [self.class, object_id, name, attrs]
  end

end

