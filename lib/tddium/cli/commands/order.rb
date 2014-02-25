module Tddium
  class TddiumCli < Thor
    desc "order", "Find failing ordering by binary searching a failing test run"
    desc "order files+ failing_file", "Find out which file causes pollution / makes the failing file fail"
    def order(files)
      failing = files.pop
      if !files.include?(failing)
        exit_failure "Files have to include the failing file, use the copy helper"
      elsif files.size < 2
        exit_failure "Files have to be more than 2, use the copy helper"
      elsif !success?([failing])
        exit_failure "#{failing} fails when run on it's own"
      elsif success?(files)
        exit_failure "tests pass locally"
      else
        loop do
          a = remove_from(files, files.size / 2, :not => failing)
          b = files - (a - [failing])
          status, files = find_failing_set([a, b], failing)
          if status == :finished
            say "Fails when #{files.join(", ")} are run together"
            break
          elsif status == :continue
            next
          else
            exit_failure "unable to isolate failure to 2 files"
          end
        end
      end
    end

    private

    def find_failing_set(sets, failing)
      sets.each do |set|
        next if set == [failing]
        if !success?(set)
          if set.size == 2
            return [:finished, set]
          else
            return [:continue, set]
          end
        end
      end
      return [:failure, []]
    end

    def remove_from(set, x, options)
      set.dup.delete_if { |f| f != options[:not] && (x -= 1) >= 0 }
    end

    def success?(files)
      command = "bundle exec ruby #{files.map { |f| "-r./#{f.sub(/\.rb$/, "")}" }.join(" ")} -e ''"
      say "Running: #{command}"
      status = system(command)
      say "Status: #{status ? "Success" : "Failure"}"
      status
    end
  end
end
