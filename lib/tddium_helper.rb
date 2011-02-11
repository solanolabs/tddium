# Copyright (c) 2010 Sauce Labs Inc
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
module SpecStorm
  def self.set_db_prefix(prefix)
    ActiveRecord::Base.prefix_and_reset_all_table_names_to prefix
    ActiveRecord::Base.show_all_subclasses
  end

  def self.db_prefix_for(file)
    #puts "Calculating for #{file}"
    dummy = File.join(File.expand_path(File.dirname(file)), (file).split('/').last)
    prefix = Digest::SHA1.hexdigest( dummy )
    prefix = prefix[0,15]
    "ss_#{prefix}_"
  end

  def self.patch_selenium_driver(file)
    db_prefix = self.db_prefix_for(file)

    # Monkey-patch like there's no tomorrow
    Selenium::Client::Driver.class_eval do
      attr_accessor :db_prefix
    end
    
    Selenium::Client::Driver.class_eval do
      # Make sure we don't define this twice
      unless self.instance_methods.include? "original_open"
        alias :original_open :open
        
        def open(url)
          # TODO: Regex stuff to append query properly
          new_url = url.include?("db_prefix=") ? url :"#{url}?db_prefix=#{db_prefix}"
          puts "Patching url, opening #{new_url}"
          original_open( new_url )
        end
      end
    end
  end

  def self.find_tests(root)
    Dir["#{root}**/**/*_spec.rb"]
  end
end
