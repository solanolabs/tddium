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
 
ActionView::Helpers::UrlHelper.class_eval do
  unless self.const_defined?("SpecStormLoaded")
    puts "Patching ActiveView::Base"
    SpecStormLoaded = true
    
    alias_method :original_url_to, :url_for

    def url_for(options = {})
      # TODO: Regex stuff to only append this when necessary
      case options
      when String
        return "#{original_url_to( options )}?db_prefix=#{ActiveRecord::Base.table_name_prefix}" unless options.include? "db_prefix="
      end
      
      original_url_to options
    end
    
    alias_method :original_link_to, :link_to
    
    def link_to(*args, &block)
      logger.debug "link_to:\t#{args.inspect}"
      
      arguments = args.join(",")
      if block_given?
        return eval("original_link_to( #{arguments}")
      end
      
      original_link_to *args
    end
  end
end
