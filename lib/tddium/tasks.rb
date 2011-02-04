=begin
Copyright (c) 2010 tddium.com All Rights Reserved
=end
Dir["#{Gem.searcher.find('tddium').full_gem_path}/tasks/*.rake"].each { |ext| load ext }
