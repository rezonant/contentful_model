module ContentfulModel
  class Query
    def initialize(referenced_class, parameters=nil)
      @parameters = parameters || {}
      @referenced_class = referenced_class
      @mutable = false
    end

    attr_accessor :mutable 

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
      if @mutable 
        @parameters = @parameters.merge(options)
        self
      else 
        self.class.new(@referenced_class, @parameters.merge(options))
      end 
    end 

    def first
      self.params(limit: 1).load.first
    end

    ##
    # Advance the offset by N
    def advance(n)
      offset = self.parameters[:skip] || 0
      self.offset(offset + n)
    end 

    def second 
      self.advance(1).first
    end

    def third
      self.advance(2).first
    end 

    def fourth
      self.advance(3).first
    end 

    def fifth
      self.advance(4).first
    end 

    def last
      self.reverse.first
    end
    
    def forty_two 
      self.advance(41).first
    end

    def reverse 
      order = self.parameters[:order]

      if order 
        self.params(order: order.split(',').map {|x| x.start_with?('-') ? x[1..-1] : "-#{x}"}.join(','))
      else 

        if @mutable 
          @result = self.load.reverse 
          self 
        else 
          q = self.class.new @referenced_class, @parameters
          q.result = self.load.reverse 
          q
        end

      end 
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

    def where(hash)
      parms = {}

      hash.each do |k, v|
        if v.is_a?(Array) 
          # we need to do an 'in' query
          parms["fields.#{k.to_s.camelize(:lower)}[in]"] = v.join(",")
        elsif v.is_a?(String) || v.is_a?(Numeric) || [TrueClass,FalseClass].member?(v.class)
          # literal match
          parms["fields.#{k.to_s.camelize(:lower)}"] = v
        elsif v.is_a?(Hash)
          # if the search is a hash, use the key to specify the search field operator
          # For example
          # Model.where(start_date: {gte: DateTime.now}) => "fields.start_date[gte]" => DateTime.now
          v.each do |search_predicate, search_value|
            parms["fields.#{k.to_s.camelize(:lower)}[#{search_predicate}]"] = search_value
          end
        end
      end

      self.params(parms)
    end

    def length 
      self.load.length
    end 

    def each
      self.load.each do |i|
        yield i 
      end 
    end 

    def map 
      self.load.map do |i|
        yield i
      end 
    end 

    def select 
      self.load.select do |i|
        yield i
      end 
    end 

    def reject
      self.load.reject do |i|
        yield i
      end 
    end 

    def to_a
      self.load.to_a
    end

    def load 
      return @result if defined?(@result)
      @result = self.execute
    end 

    def [](index)
      self.load[index]
    end

    def client
      @client ||= @referenced_class.send(:client)
    end

    protected 

    def result=(value)
      @result = value 
    end 
  end
end
