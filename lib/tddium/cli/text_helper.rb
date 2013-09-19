module Tddium
  module TextHelper
    # borrowed from rails/ActionView::Helpers
    def pluralize(count, singular, plural = nil)
      word = if (count == 1 || count =~ /^1(\.0+)?$/)
               singular
             else
               plural || "#{singular}s"
             end

      "#{count || 0} #{word}"
    end
  end
end
