module ContentfulModel
  module Queries
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      def query 
        Query.new self
      end

      def params(options)
        q = self.query
        q.parameters = options
        q
      end

      def load
        self.query.load
      end

      def find(id)
        self.params('sys.id' => id).load.first
      end

      def where(*args)
        q = self.query 

        args.each do |query|
          #query is a hash
          if query.values.first.is_a?(Array) #we need to do an 'in' query
            q = q.params("fields.#{query.keys.first.to_s.camelize(:lower)}[in]" => query.values.first.join(","))
          elsif query.values.first.is_a?(String) || query.values.first.is_a?(Numeric) || [TrueClass,FalseClass].member?(query.values.first.class)
            q = q.params("fields.#{query.keys.first.to_s.camelize(:lower)}" => query.values.first)
          elsif query.values.first.is_a?(Hash)
            # if the search is a hash, use the key to specify the search field operator
            # For example
            # Model.search(start_date: {gte: DateTime.now}) => "fields.start_date[gte]" => DateTime.now
            parts = {}
            query.each do |field, condition|
              search_predicate, search_value = *condition.flatten
              parts["fields.#{field.to_s.camelize(:lower)}[#{search_predicate}]"] = search_value
            end

            q = q.params(parts)
          end
        end

        q
      end

      def find_by(*args)
        self.where(*args).limit(1).first 
      end 

      def all
        raise ArgumentError, 'You need to set self.content_type in your model class' if @content_type_id.nil?
        self
      end

      def first
        self.query.first
      end

      def offset(n)
        self.query.offset(n)
      end

      def limit(n)
        self.query.limit(n)
      end

      def locale(locale_code)
        self.query.locale(locale_code)
      end

      def load_children(n)
        self.query.load_children(n)
      end

      def order(args)
        self.query.order(args)
      end

      alias_method :skip, :offset

      def search(parameters)
        self.query.search(parameters)
      end
    end
  end
end
