Dir["#{Gem.searcher.find('tddium').full_gem_path}/tasks/*.rake"].each { |ext| load ext }
