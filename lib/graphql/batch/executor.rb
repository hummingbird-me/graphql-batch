module GraphQL::Batch
  module Executor
    THREAD_KEY = :"#{name}.batched_queries"
    private_constant :THREAD_KEY
    module_function

    def current
      Thread.current[THREAD_KEY]
    end

    def before_query(query)
      Thread.current[THREAD_KEY] = query.context.dataloader
    end

    def after_query(query)
      Thread.current[THREAD_KEY] = nil
    end

    def with_dataloader(dataloader)
      Thread.current[THREAD_KEY] = dataloader
      yield
      Thread.current[THREAD_KEY] = nil
    end
  end
end
