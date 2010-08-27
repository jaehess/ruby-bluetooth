require 'delegate'

class Bluetooth::Service::Sequence < DelegateClass(Array)

  def initialize items
    @items = items

    super @items
  end

  def inspect
    super.sub('[', '[seq: ')
  end

end

