#!/usr/bin/env ruby
require 'yaml'
require 'erb'
require 'fileutils'

config_file = '.build.yml'
if File.exists?(config_file)
  CONFIG = YAML.load( ERB.new( File.read(config_file) ).result )
else
  puts "No #{config_file} provided, skipping"
end

def install_ruby
  system "rvm install #{CONFIG['ruby']}"
end

def install_packages
  puts "Installing package dependencies"
  packages = CONFIG['pkg'].join(' ')
  %x[apt-get update -qq && apt-get install -y -qq #{packages}]
end

def install_gems
  %x[rvm #{ruby_version} do bundle install]
end

def install_app
  install_packages
  install_ruby
  install_gems
end

def command_for(app_module)
  @start_cmds ||= CONFIG['start_cmds']
  @start_cmds.fetch(app_module)
end

def start_app_module(app_module='app')
  @start_cmds ||= CONFIG['start_cmds']

  exec("rvm #{ruby_version} do #{command_for(app_module)}")
end

def build_runit_config(mod)
  cmd = command_for(mod)
  conf = <<-EOF
#!/bin/bash
cd #{Dir.pwd}
exec rvm #{ruby_version} do #{cmd}
EOF

  FileUtils.mkdir_p("sv/#{mod}")
  File.open("sv/#{mod}/run", "w+") { |f| f.write(conf) }
  FileUtils.chmod('+x', "sv/#{mod}/run")
end

def start_multi(*mods)
  if mods.any?
    mods.each { |m| build_runit_config(m) }
  else
    CONFIG['start_cmds'].each {|mod, cmd| build_runit_config(mod) }
  end
  exec('/usr/bin/runsvdir ./sv')
end

def start_app
  if ARGV.count > 1 || ARGV.count == 0
    start_multi(*ARGV)
  else
    start_app_module(ARGV[0])
  end
end

def before_start
  CONFIG['before_start_cmds'] || []
end

def ruby_version
  CONFIG['ruby']
end

def run_before_start
  before_start.each {|cmd| system(cmd)}
end

if ARGV[0] == 'install'
  install_packages
  install_ruby
  install_gems
else
  run_before_start if before_start.any?
  start_app
end
