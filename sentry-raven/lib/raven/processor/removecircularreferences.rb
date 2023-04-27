module Raven
  class Processor::RemoveCircularReferences < Processor
    ELISION_STRING = '(...)'.freeze
    def process(value, visited = [])
      return ELISION_STRING if visited.include?(value.__id__)

      visited << value.__id__ if value.is_a?(Array) || value.is_a?(Hash)

      case value
      when Hash
        if !value.frozen?
          value.merge!(value) { |_, v| process v, visited }
        else
          value.merge(value) do |_, v|
            process v, visited
          end
        end
      when Array
        !value.frozen? ? value.map! { |v| process v, visited } : value.map { |v| process v, visited }
      else
        value
      end
    end
  end
end
