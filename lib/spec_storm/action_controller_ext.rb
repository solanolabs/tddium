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

ActionController::Base.class_eval do
  puts "Not Patching ActionController" if self.const_defined?("SpecStormLoaded")
  unless self.const_defined?("SpecStormLoaded")
    puts "Patching ActionController::Base"
    SpecStormLoaded = true

    alias_method :original_url_for, :url_for
    
    def url_for(options = {})
      options.merge!( {:db_prefix => ActiveRecord::Base.table_name_prefix} ) unless options.class != Hash
      original_url_for options
    end
    
    alias_method :original_process, :process
    
    def process(request, response, method = :perform_action, *arguments) #:nodoc:
      raise StandardError.new("db_prefix cannot be nil in SpecStorm mode!") if request.params[:db_prefix].nil?
      ActiveRecord::Base.table_name_prefix = request.params[:db_prefix]
      ActiveRecord::Base.reset_all_table_names
      
      original_process(request, response, method, *arguments)
    end
    
    alias_method :original_redirect_to, :redirect_to
    
    def redirect_to(options = {}, response_status = {}) #:doc:
      raise ActionControllerError.new("Cannot redirect to nil!") if options.nil?
      
      case options
      when String
        options += "?db_prefix=#{ActiveRecord::Base.table_name_prefix}" unless options.include? "db_prefix="
      end
      
      original_redirect_to( options, response_status )
    end
  end
end

ActionController::UrlRewriter.class_eval do
  alias_method :original_rewrite_path, :rewrite_path

  def rewrite_path(options)
      options.merge!( {:db_prefix => ActiveRecord::Base.table_name_prefix} ) unless options.class != Hash or options.has_key?(:db_prefix)

    original_rewrite_path(options)
  end
end
