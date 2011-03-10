module Hippo::TransactionSets
  class Base
    class << self
      attr_accessor :components, :identifier

      def components
        @components ||= []
      end

      def loop_name(id)
        @identifier = id
      end

      def add_component(klass, options={})
        components << options.merge(:class => klass, :sequence => components.length)
      end
      alias segment add_component
      alias loop add_component
    end

    attr_accessor :values

    def values
      @values ||= {}
    end

    def to_s
      output = ''

      values.sort.each do |sequence, component|
        output += component.to_s
      end

      output
    end

    def get_component(identifier, sequence = nil)
      if sequence.nil?
        sequence = 0
      else
        sequence = sequence.to_i - 1
      end

      self.class.components.select do |c|
        c[:class].identifier == identifier
      end[sequence]
    end

    def method_missing(method_name, *args)
      component_name, component_sequence = method_name.to_s.split('_')
      component_entry = get_component(component_name, component_sequence)

      if values[component_entry[:sequence]].nil?
        component = component_entry[:class].new

        # iterate through the hash of defaults
        # and assign them to the component before
        # adding to @values
        component_entry.each do |key, value|
          next unless key.class == String

          component.send((key + '=').to_sym, value)
        end

        yield component if block_given?

        values[component_entry[:sequence]] = component
      else
        return values[component_entry[:sequence]]
      end
    end
  end
end
