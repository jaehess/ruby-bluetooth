require 'rubygems'
require 'hoe'
#require 'rake/extensiontask'

hoe = Hoe.spec 'ruby-bluetooth' do
  developer 'Eric Hodel', 'drbrain@segment7.net'
  developer 'Jeremie Castagna', ''
  developer 'Esteve Fernandez', ''

  extra_dev_deps << ['rake-compiler', '>= 0.4.1']

  self.clean_globs = %w[
    ext/Makefile
    ext/mkmf.log
    ext/bluetooth.bundle
    ext/bluetooth.o
  ]

  self.spec_extras[:extensions] = 'ext/bluetooth/extconf.rb'
end

#Rake::ExtensionTask.new 'bluetooth' do |ext|
#  ext.source_pattern = '*/*.{c,cpp,h,m}'
#  ext.gem_spec = hoe.spec
#end
#
#task :test => :compile
