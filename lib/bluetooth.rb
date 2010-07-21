module Bluetooth

  VERSION = '1.0'

  ERRORS = {}

  class Error < RuntimeError
    def self.raise status
      err = Bluetooth::ERRORS[status]
      super(*err) if err

      super self, "unknown error (#{status})"
    end
  end

  autoload :Device,      'bluetooth/device'
  autoload :OBEXSession, 'bluetooth/obex_session'
  autoload :Service,     'bluetooth/service'

end

require 'bluetooth/bluetooth'

