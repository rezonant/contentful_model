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
        q.parameters = (q.parameters || {}).merge(options)
        q
      end

      def load
        self.query.load
      end

      def find(id)
        self.params('sys.id' => id).load.first
      end

      def where(hash)
        self.query.where(hash)
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
