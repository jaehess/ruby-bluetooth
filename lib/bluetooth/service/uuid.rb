class Bluetooth::Service::UUID

  attr_accessor :uuid

  def initialize raw
    @uuid = raw
  end

  def to_s
    "%04x%04x-%04x-%04x-%04x-%04x%04x%04x" % uuid.unpack('n8')
  end

  alias inspect to_s

end

