$: << File.join(File.dirname(__FILE__), '..', 'lib')
require 'bluetooth.rb'

devices = Bluetooth.scan

devices.each do |device|
  puts device
end

