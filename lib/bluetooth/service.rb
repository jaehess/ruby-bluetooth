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

  PROTOCOLS = {
    0x0001 => :SDP,
    0x0002 => :UDP,
    0x0003 => :RFCOMM,
    0x0004 => :TCP,
    0x0005 => :TCS_BIN,
    0x0006 => :TCS_AT,
    0x0008 => :OBEX,
    0x0009 => :IP,
    0x000A => :FTP,
    0x000C => :HTTP,
    0x000E => :WSP,
    0x000F => :BNEP,
    0x0010 => :UPNP,
    0x0011 => :HIDP,
    0x0012 => :HardcopyControlChannel,
    0x0014 => :HardcopyDataChannel,
    0x0016 => :HardcopyNotification,
    0x0017 => :AVCTP,
    0x0019 => :AVDTP,
    0x001B => :CMTP,
    0x001D => :UDI_C_Plane,
    0x001E => :MCAPControlChannel,
    0x001F => :MCAPDataChannel,
    0x0100 => :L2CAP,
  }

  SERVICE_CLASSES = {
    0x1000 => :ServiceDiscoveryServerServiceClassID,
    0x1001 => :BrowseGroupDescriptorServiceClassID,
    0x1002 => :PublicBrowseGroup,
    0x1101 => :SerialPort,
    0x1102 => :LANAccessUsingPPP,
    0x1103 => :DialupNetworking,
    0x1104 => :IrMCSync,
    0x1105 => :OBEXObjectPush,
    0x1106 => :OBEXFileTransfer,
    0x1107 => :IrMCSyncCommand,
    0x1108 => :HSP,
    0x1109 => :CordlessTelephony,
    0x110A => :AudioSource,
    0x110B => :AudioSink,
    0x110C => :A_V_RemoteControlTarget,
    0x110D => :AdvancedAudioDistribution,
    0x110E => :A_V_RemoteControl,
    0x110F => :A_V_RemoteControlController,
    0x1110 => :Intercom,
    0x1111 => :Fax,
    0x1112 => :Headset_AG,
    0x1113 => :WAP,
    0x1114 => :WAP_CLIENT,
    0x1115 => :PANU,
    0x1116 => :NAP,
    0x1117 => :GN,
    0x1118 => :DirectPrinting,
    0x1119 => :ReferencePrinting,
    0x111A => :Imaging,
    0x111B => :ImagingResponder,
    0x111C => :ImagingAutomaticArchive,
    0x111D => :ImagingReferencedObjects,
    0x111E => :Handsfree,
    0x111F => :HandsfreeAudioGateway,
    0x1120 => :DirectPrintingReferenceObjectsService,
    0x1121 => :ReflectedUI,
    0x1122 => :BasicPrinting,
    0x1123 => :PrintingStatus,
    0x1124 => :HumanInterfaceDeviceService,
    0x1125 => :HardcopyCableReplacement,
    0x1126 => :HCR_Print,
    0x1127 => :HCR_Scan,
    0x1128 => :Common_ISDN_Access,
    0x1129 => :VideoConferencingGW,
    0x112A => :UDI_MT,
    0x112B => :UDI_TA,
    0x112C => :Audio_Video,
    0x112D => :SIM_Access,
    0x112E => :Phonebook_Access_PCE,
    0x112F => :Phonebook_Access_PSE,
    0x1130 => :Phonebook_Access,
    0x1131 => :Headset_HS,
    0x1132 => :Message_Access_Server,
    0x1133 => :Message_Notification_Server,
    0x1134 => :Message_Access_Profile,
    0x1200 => :PnPInformation,
    0x1201 => :GenericNetworking,
    0x1202 => :GenericFileTransfer,
    0x1203 => :GenericAudio,
    0x1204 => :GenericTelephony,
    0x1205 => :UPNP_Service,
    0x1206 => :UPNP_IP_Service,
    0x1300 => :ESDP_UPNP_IP_PAN,
    0x1301 => :ESDP_UPNP_IP_LAP,
    0x1302 => :ESDP_UPNP_L2CAP,
    0x1303 => :VideoSource,
    0x1304 => :VideoSink,
    0x1305 => :VideoDistribution,
    0x1400 => :HDP,
    0x1401 => :HDP_Source,
    0x1402 => :HDP_Sink,
  }

  ATTRIBUTES.each do |name, attr_id|
    define_method name do @attributes[attr_id] end
  end

  attr_reader :attributes
  attr_reader :device
  attr_reader :name

  def initialize name, attributes, device
    @name = name
    @attributes = attributes
    @device = device
  end

  alias to_s name # :nodoc:

  def inspect
    id2attr = ATTRIBUTES.invert

    attrs = @attributes.sort.map do |attr_id, value|
      attr_name = id2attr[attr_id] || ("0x%04x" % attr_id)
      value = case attr_name
              when :service_class_id_list then
                value.map { |val| SERVICE_CLASSES[val.to_i] || val }
              when :protocol_descriptor_list then
                value.map { |(val, *rest)|
                  [(PROTOCOLS[val.to_i] || val), *rest]
                }
              else
                value
              end

      [attr_name, value.inspect].join ': '
    end.join ', '

    "#<%s:0x%x %s - %s>" % [self.class, object_id, name, attrs]
  end

  autoload :Alternative, 'bluetooth/service/alternative'
  autoload :Sequence,    'bluetooth/service/sequence'
  autoload :UUID,        'bluetooth/service/uuid'

end

