require 'delegate'

class Bluetooth::Service::Alternative < DelegateClass(Array)

  def initialize items
    @items = items

    super @items
  end

  def inspect
    super.sub('[', '[alt:')
  end

end

