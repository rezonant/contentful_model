module ContentfulModel
  module ChainableQueries
    def self.included(base)
      base.include ContentfulModel::Queries
      base.extend ClassMethods
    end

    module ClassMethods
    end

  end
end
