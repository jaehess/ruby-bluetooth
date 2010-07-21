require 'bluetooth'

address = ARGV.shift || abort("#{$0} address uuid # look up a device with scan.rb")
uuid = ARGV.shift || abort("#{$0} address uuid # See Bluetooth::Service::SERVICE_CLASSES")
uuid = Bluetooth::Service::UUID.from_integer uuid

device = Bluetooth::Device.new address

service = device.service uuid

service.obex_session do |session|
  p session
end

