# SPDX-FileCopyrightText: Copyright 2010-present Greg Hurrell. All rights reserved.
# SPDX-License-Identifier: BSD-2-Clause

require 'pathname'

begin
  require 'mkmf'
rescue LoadError
  puts <<-DOC.gsub(/^\s+/, '')
    Unable to require "mkmf"; you may need to install Ruby development tools
    (depending on your system, a "ruby-dev"/"ruby-devel" package or similar).
    [exiting]
  DOC
  exit 1
end

def header(item)
  unless find_header(item)
    puts "couldn't find #{item} (required)"
    exit 1
  end
end

# mandatory headers
header('float.h')
header('ruby.h')
header('stdlib.h')
header('string.h')

# optional headers (for CommandT::Watchman::Utils)
if have_header('fcntl.h') &&
  have_header('stdint.h') &&
  have_header('sys/errno.h') &&
  have_header('sys/socket.h')
  RbConfig::MAKEFILE_CONFIG['DEFS'] ||= ''
  RbConfig::MAKEFILE_CONFIG['DEFS'] += ' -DWATCHMAN_BUILD'

  have_header('ruby/st.h') # >= 1.9; sets HAVE_RUBY_ST_H
  have_header('st.h')      # 1.8; sets HAVE_ST_H
end

# optional
if RbConfig::CONFIG['THREAD_MODEL'] == 'pthread'
  have_library('pthread', 'pthread_create') # sets HAVE_PTHREAD_H if found
end

RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']

create_makefile('ext')

# Create `metadata.rb`, which is used to diagnose installation problems.
basedir = Pathname.new(__FILE__).dirname
(basedir + 'metadata.rb').open('w') do |f|
  f.puts <<-END.gsub(/^    /, '')
    # This file was generated by #{(basedir + 'extconf.rb').to_s}
    module CommandT
      module Metadata
        EXPECTED_RUBY_VERSION = #{RUBY_VERSION.inspect}
        EXPECTED_RUBY_PATCHLEVEL = #{
          defined?(RUBY_PATCHLEVEL) ? RUBY_PATCHLEVEL.inspect : nil.inspect
        }
        UNKNOWN = false
      end
    end
  END
end
