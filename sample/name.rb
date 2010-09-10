$: << File.join(File.dirname(__FILE__), '..', 'lib')
require 'bluetooth.rb'

address = ARGV.shift || abort("#{$0} address # look up a device with scan.rb")

device = Bluetooth::Device.new address

puts device

