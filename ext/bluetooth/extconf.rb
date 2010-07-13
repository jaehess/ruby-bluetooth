require 'mkmf'

dir_config 'bluetooth'

if RUBY_PLATFORM =~ /darwin/ then
  $LDFLAGS << ' -framework IOBluetooth'

  create_makefile 'bluetooth', 'macosx'

  open 'Makefile', 'a' do |io|
    io.write "\n.m.o:\n\t#{COMPILE_C}\n\n"
  end
end

