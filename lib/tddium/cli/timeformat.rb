module Tddium
  module TimeFormat
    extend Tddium::TextHelper

    def self.seconds_to_human_time(seconds)
      return '-' if seconds.nil?
      seconds = seconds.to_time if seconds.respond_to?(:to_time)
      seconds = seconds.abs.round
      return "0 secs" if seconds == 0
      [[60, :sec], [60, :min], [24, :hr], [10000, :day]].map{ |count, name|
        if seconds > 0
          seconds, n = seconds.divmod(count)
          pluralize(n.to_i, name.to_s)
        end
      }.compact.reverse[0..1].join(' ')
    end
  end
end

