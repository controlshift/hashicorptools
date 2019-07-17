module Hashicorptools
  module Variables

    def variables(settings_overrides = {})
      settings_overrides.collect{|key,value| format_variable(key, value)}.join(' ')
    end

    protected

    def format_variable(key, value)
      "-var '#{key}=\"#{value}\"'"
    end
  end
end
