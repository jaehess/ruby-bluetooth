$: << File.join(File.dirname(__FILE__), '..', 'lib')
require 'bluetooth.rb'

address = ARGV.shift || abort("#{$0} address uuid # look up a device with scan.rb")
uuid = ARGV.shift || abort("#{$0} address uuid # See Bluetooth::Service::SERVICE_CLASSES")
uuid = Bluetooth::Service::UUID.from_integer uuid

device = Bluetooth::Device.new address

service = device.service uuid

puts "#{device.name} service at #{uuid.inspect}:"

p service

