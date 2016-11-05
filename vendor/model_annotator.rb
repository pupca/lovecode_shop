class ModelAnnotator
  class << self
    def annotate(*models)
      annotations = models.map do |model|
        columns = model.db_schema.map do |column, spec|
          type = spec[:primary_key] ? 'primary_key' : 'column'

          attr = {}
          unless spec[:primary_key]
            attr[:default] = spec[:default] if spec[:default]
            attr[:null] = spec[:allow_null] unless spec[:allow_null]
          end

          attr_str = attr.map { |k, v| "#{k}: #{v}" }.join(', ')

          "#{type} :#{column}, '#{spec[:db_type]}'#{", #{attr_str}" if attr_str.present?}"
        end

        <<-END.heredoc
          |# Basic #{model} model table annotation to give you an idea of its structure
          |# Unfurtunately without foreign keys and indexes as Model#db_schema is not providing them
          |#
          |#   create_table(:#{model.table_name}) do
          |#     #{columns.join("\n#     ")}
          |#   end
          |#
        END
      end

      puts annotations.join("\n\n")
    end
  end
end
