module Sequel
  module Plugins
    # Retry a create/save n times. The optional block will be executed
    # before retry.
    #
    # @example
    #
    #   plugin :create_retry
    #   plugin :create_retry, num_retries: 2
    #
    #   plugin :create_retry do |order|
    #     order.generate_random_external_id
    #   end
    #
    #   plugin :create_retry, num_retries: 2 do |order|
    #     order.generate_random_external_id
    #   end
    module CreateRetry
      def self.apply(model, _opts = OPTS)
        model.plugin :instance_hooks
      end

      def self.configure(model, opts = OPTS, &block)
        model.instance_eval do
          @num_retries = opts[:num_retries] || 2
          @retry_block = block
        end
      end

      module ClassMethods
        attr_reader :num_retries
        attr_reader :retry_block

        # Create an instance, run the block on it and try saving it for
        # @num_retries times.
        #
        # @example
        #
        #   User.create_retry(email: 'user@example.org')
        def create_retry(values = {})
          transaction_opts = {
            retry_on:    Sequel::UniqueConstraintViolation,
            num_retries: num_retries,
            savepoint:   true
          }

          new(values).save_retry(transaction_opts)
        end
      end

      module InstanceMethods
        # Save an instance, run the block on it and try saving it for
        # @num_retries times.
        #
        # @example
        #
        #   user = User.new(email: 'user@example.org')
        #   user.save_retry
        def save_retry(opts = OPTS)
          transaction_opts = opts.merge(
            retry_on:    Sequel::UniqueConstraintViolation,
            num_retries: self.class.num_retries,
            savepoint:   true
          )

          before_save_hook do
            @try_count ||= 0
            @try_count += 1
            self.class.retry_block.call(self) if self.class.retry_block && retrying?
          end

          save(transaction_opts)
        end

        # Are we currently retrying a failed save?
        #
        # @return [Bool]
        def retrying?
          @try_count > 1
        end
      end
    end
  end
end
