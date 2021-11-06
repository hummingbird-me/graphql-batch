require "graphql"
require "promise.rb"

module GraphQL
  module Batch
    BrokenPromiseError = ::Promise::BrokenError
    class NoExecutorError < StandardError; end

    def self.batch(executor_class: GraphQL::Batch::Executor)
      begin
        GraphQL::Batch::Executor.start_batch(executor_class)
        ::Promise.sync(yield)
      ensure
        GraphQL::Batch::Executor.end_batch
      end
    end

    def self.use(schema_defn)
      schema_defn.use(GraphQL::Dataloader)
      schema_defn.instrument(:query, GraphQL::Batch::Executor)
    end
  end
end

require_relative "batch/version"
require_relative "batch/loader"
require_relative "batch/executor"
