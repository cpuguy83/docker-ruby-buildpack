#!/usr/bin/env ruby
require 'yaml'
require 'erb'
require 'fileutils'
require 'digest/sha1'

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

def run_install_cmds
  install_cmds.each {|cmd| system("rvm #{ruby_version} do #{cmd}") }
end

def install_app
  install_packages
  install_ruby
  run_install_cmds
end

def command_for(app_module)
  startup_modules.fetch(app_module) { false }
end

def start_app_module(app_module='app')
  exec("rvm #{ruby_version} do #{command_for(app_module)}")
end

def build_startup_config(mod, cmd)
  conf = <<-EOF
#!/bin/bash
cd #{Dir.pwd}
exec rvm #{ruby_version} do #{cmd}
EOF

  FileUtils.mkdir_p("sv/#{mod}")
  File.open("sv/#{mod}/run", "w+") { |f| f.write(conf) }
  FileUtils.chmod('+x', "sv/#{mod}/run")
end

def build_stop_config(mod, cmd)
  conf = <<-EOF
#!/bin/bash
cd #{Dir.pwd}
exec rvm #{ruby_version} do #{cmd}
EOF

  FileUtils.mkdir_p("sv/#{mod}")
  File.open("sv/#{mod}/finish", "w+") { |f| f.write(conf) }
  FileUtis.chmod('+x', "sv/#{mod}/finish")
end

def startup_modules
  @start_modules ||= cmds.fetch('start') { {} }
end

def start_multi(*mods)
  if mods.any?
    mods.each { |m| build_startup_config(m, command_for(m)) }
  else
    startup_modules.each {|mod, cmd| build_startup_config(mod, cmd) }
    stop_cmds.each {|mod, cmd| build_stop_config(mod, cmd) }
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
  cmds.fetch('pre'){ [] }
end

def install_cmds
  cmds.fetch('install'){ [] }
end

def ruby_version
  CONFIG.fetch('ruby') { 'ruby' }
end

def once_cmds
  cmds.fetch('once'){ [] }
end

def run_before_start
  before_start.each {|cmd| system(cmd)}
end

def run_once_cmds
  once_cmds.each do |cmd|
    cmd_hash = generate_hash(cmd)
    unless File.exists?("tmp/run_conce_cmds/#{cmd_hash}")
      system("rvm #{ruby_version} do #{cmd}")
      if $?.success?
        FileUtils.mkdir_p('tmp/run_once_cmds')
        File.open("tmp/run_once_cmds/#{cmd_hash}", 'w+') {|f| f.write(cmd_hash) }
      end
    end
  end
end

def cmds
  CONFIG.fetch('cmds') { {} }
end

def stop_cmds
  cmds.fetch('stop') { {} }
end

def generate_hash(payload)
  Digest::SHA1.hexdigest(payload)
end

def run_custom_cmd(cmd)
  exec("rvm #{ruby_version} do #{cmd}")
end

case
  when ARGV[0] == 'install' then install_app
  when ARGV[0] && !command_for(ARGV[0]) then run_custom_cmd(ARGV.join(' '))
else
  run_once_cmds
  run_before_start
  start_app
end
