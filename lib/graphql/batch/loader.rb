module GraphQL::Batch
  class Loader < GraphQL::Dataloader::Source
    def self.for(*group_args, **group_kwargs)
      current_executor.with(self, *group_args, **group_kwargs)
    end

    def self.batch_key_for(...)
      loader_key_for(...)
    end

    def self.loader_key_for(*group_args, **group_kwargs)
      [self, group_kwargs, group_args]
    end

    def self.load(key)
      self.for.load(key)
    end

    def self.load_all(...)
      load_many(...)
    end

    def self.load_many(keys)
      self.for.load_many(keys)
    end

    class << self
      private

      def current_executor
        executor = Executor.current

        unless executor
          raise GraphQL::Batch::NoExecutorError, 'Cannot create loader without'\
            ' an Executor. Wrap the call to `for` with `GraphQL::Batch.batch`'\
            ' or use `GraphQL::Batch::Setup` as a query instrumenter if'\
            ' using with `graphql-ruby`'
        end

        executor
      end
    end

    def load(...)
      super(...)
    end

    alias_method :load_many, :load_all

    def fetch(keys)
      future = Concurrent::Promises.future(self, keys) do |loader, keys|
        results = loader.perform(keys) && keys.map do |key|
          loader.fulfillments[key]
        end
        results
      end
      dataloader.yield
      future.value!
    end

    protected

    # Fulfill the key with provided value, for use in #perform
    def fulfill(key, value)
      fulfillments[key] = value
    end

    def fulfilled?(key)
      fulfillments.key?(key)
    end

    # We don't track rejections, so we ignore #reject
    def reject(key, reason)
      reason
    end

    # Must override to load the keys and call #fulfill for each key
    def perform(keys)
      raise NotImplementedError
    end

    def fulfillments
      @fulfillments ||= {}
    end
  end
end
