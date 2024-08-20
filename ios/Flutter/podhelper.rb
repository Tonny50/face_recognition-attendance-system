require 'cocoapods'

def flutter_application_path
  File.expand_path(File.join('..', '..'))
end

def load_flutter_application
  flutter_application_path = flutter_application_path()
  podfile_path = File.join(flutter_application_path, '.ios', 'Flutter', 'Podfile')
  if File.exist?(podfile_path)
    pod 'Flutter', :path => File.join(flutter_application_path, '.ios', 'Flutter')
    load podfile_path
  end
end

load_flutter_application
