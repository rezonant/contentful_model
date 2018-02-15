module ContentfulModel
  class Query
    def initialize(referenced_class, parameters=nil)
      @parameters = parameters || {}
      @referenced_class = referenced_class
    end

    def parameters=(value)
      @parameters = value
    end 

    def parameters 
      @parameters.with_indifferent_access
    end 

    def default_parameters
      { 'content_type' => @referenced_class.send(:content_type_id) }
    end

    def execute
      query = @parameters.merge(default_parameters)
      result = client.entries query
      result.items.reject! { |e| e.invalid? }
      result
    end

    def params(options)
      self.class.new(@referenced_class, @parameters.merge(options))
    end 

    def first
      self.params(limit: 1).load.first
    end

    def offset(n)
      self.params(skip: n)
    end

    def limit(n)
      self.params(limit: n)
    end

    def load_children(n)
      self.params(include: n)
    end

    def locale(locale_code)
      self.params(locale: locale_code)
    end

    def order(args)
      args = { args.to_sym => :asc } if args.is_a?(Symbol) || args.is_a?(String)
      raise "Parameter for order() must be a Hash, a symbol, or a string" unless args.is_a?(Hash)

      fields = [] 
      args.each do |k, v|

        column = k.to_s
        prefix = v == :desc ? '-' : ''

        property_name = column.camelize(:lower).to_sym
        sys_properties = ['type', 'id', 'space', 'contentType', 'linkType', 'revision', 'createdAt', 'updatedAt', 'locale']
        property_type = sys_properties.include?(property_name.to_s) ? 'sys' : 'fields'
        fields << "#{prefix}#{property_type}.#{property_name}"
      end 

      self.params(order: fields.join(','))
    end

    alias_method :skip, :offset

    def search(parameters)
      if parameters.is_a?(Hash)
        fields = {}
        parameters.each do |field, search|
          # if the search is a hash, use the key to specify the search field operator
          # For example
          # Model.search(start_date: {gte: DateTime.now}) => "fields.start_date[gte]" => DateTime.now
          if search.is_a?(Hash)
            search_key, search_value = *search.flatten
            fields["fields.#{field.to_s.camelize(:lower)}[#{search_key}]"] = search_value
          else
            fields["fields.#{field.to_s.camelize(:lower)}[match]"] = search
          end
        end
        self.params(fields)
      elsif parameters.is_a?(String)
        self.params("query" => parameters)
      end
    end

    def length 
      self.load.length
    end 

    def load 
      return @result if defined?(@result)
      @result = self.execute
    end 

    def client
      @client ||= @referenced_class.send(:client)
    end
  end
end
