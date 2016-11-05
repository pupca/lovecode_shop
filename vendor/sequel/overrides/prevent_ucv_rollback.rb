module Sequel
  class Database
    def prevent_ucv_rollback
      executor = proc do
        begin
          yield
        rescue Sequel::UniqueConstraintViolation
          raise Sequel::Rollback if in_transaction?
        end
      end

      if in_transaction?
        transaction(savepoint: true, &executor)
      else
        executor.call
      end
    end
  end
end
