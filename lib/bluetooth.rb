$: << File.join(File.dirname(__FILE__))

module Bluetooth

  VERSION = '1.0'

  ERRORS = {}

  OBEX_ERRORS = {}

  class Error < RuntimeError
    def self.raise status
      err = Bluetooth::ERRORS[status]
      super(*err) if err

      super self, "unknown error (#{status})"
    end
  end

  class OBEXError < RuntimeError
    def self.raise status
      err = Bluetooth::OBEX_ERRORS[status]
      super(*err) if err

      super self, "unknown error (#{status})"
    end
  end

  autoload :Device,      'ruby-bluetooth/device'
  autoload :OBEXSession, 'ruby-bluetooth/obex_session'
  autoload :Service,     'ruby-bluetooth/service'

end

require 'bluetooth'
