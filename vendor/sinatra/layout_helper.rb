require 'uri'
require 'cgi'

module Sinatra
  module LayoutHelper
    # Render ERB partial
    #
    # @param [Symbol] template
    # @param [Hash] locals
    def partial_erb(template, locals = {})
      erb(template, layout: false, locals: locals)
    end

    # Set a title / heading of the page
    #
    #   title t('something')
    #   title 'My precious'
    #
    # @param [String] title
    def title(*args)
      @title = args[0] if args.present?
      @title
    end

    # Get a complete page title with app suffix
    #
    # layout_title
    # layout_title suffix: t('something')
    # layout_title suffix: 'My precious'
    #
    # @param [Hash] options
    #   (String) suffix, text after dash
    #
    # @return [String]
    def layout_title(options = {})
      suffix = options.delete(:suffix)

      if suffix.present? && title.present? && title != suffix
        "#{title} - #{suffix}"
      elsif title.present?
        title
      elsif suffix.present?
        suffix
      end
    end

    # Attempts to pluralize the `singular` word unless `count` is 1 otherwise use `plural`
    #
    # @param [Fixnum] count
    # @param [String] singular
    # @param [String] plural
    #
    # @return [String]
    def pluralize(count, singular, plural)
      word = count == 1 ? singular : plural
      "#{count || 0} #{word}"
    end

    # Generates a param for `sorted` plugin:
    #
    #   <a href="<%== sort_param :name_asc %>">
    #   <a href="?sort=name_asc">
    #
    #   <a href="<%== sort_param :created_at_asc %>">
    #   <a href="?sort=created_at_asc">
    #
    # @param [Symbol|String] field_order '<model_field>_<order>', e.g. :name_asc, :created_at_asc
    # @param [String]        params_key where to look in params
    #
    # @return [String]
    def sort_param(field_order, params_key = 'sort')
      params_key         = params_key.to_s
      params_field_order = params[params_key]
      order_hash         = {}

      if params_field_order.present?
        *fields,        order        = field_order.to_s.split('_')
        *params_fields, params_order = params_field_order.to_s.split('_')

        field        = fields.join('_')
        params_field = params_fields.join('_')

        if field == params_field && order == params_order
          if order == 'asc'
            new_order = "#{field}_desc"
          else
            new_order = "#{field}_asc"
          end

          order_hash = { params_key => new_order }
        end
      end

      order_hash = { params_key => field_order } if order_hash.empty?
      new_params = params.deep_merge(order_hash)
      url = "?#{new_params.to_query}"
      url
    end

    # Look into params for current sorting and display a caret or not.
    # Automatically handles asc/desc and absence of sort.
    # Default sort must be marked by the `default` param.
    #
    #   <%= sort_caret :name %>              <-- will handle asc/desc automatically
    #   <%= sort_caret :created_at, :desc %> <-- default sort caret (no sort in params)
    #
    # @param [Symbol|String] field      `<model_field>_<order>`, e.g. `:name_asc`, `:created_at_asc`
    # @param [Symbol]        default    Fallback/default sorting. One of `:desc` or `:asc`
    # @param [String]        params_key where to look in params for the sorting
    #
    # @return [String]
    def sort_caret(field, default = nil, params_key = 'sort')
      caret_asc  = '<span class="caret caret-reverse"></span>'
      caret_desc = '<span class="caret"></span>'

      params_key         = params_key.to_s
      params_field_order = params[params_key]

      if params_field_order.blank?
        case default
        when :asc
          return caret_asc
        when :desc
          return caret_desc
        else
          return
        end
      end

      *params_fields, params_order = params_field_order.to_s.split('_')
      params_field = params_fields.join('_')

      return unless field.to_s == params_field

      case params_order
      when 'asc'
        return caret_asc
      when 'desc'
        return caret_desc
      end
    end

    # Generate list of hidden fields for given params keys
    #
    # @param [*Array] keys
    #
    # @return [String]
    def params_to_hidden(*keys)
      required = params.symbolize_keys
      required = required.slice(*keys) unless keys.empty?

      return '' if required.empty?

      hash_to_hidden(required)
    end

    # Generate list of hidden fields from hash
    #
    # @param [Hash] hash
    # @param [String] namespace
    #
    # @return [String]
    def hash_to_hidden(hash, namespace = nil)
      hash.map do |key, value|
        ns = namespace ? "#{namespace}[#{key}]" : key
        if value.is_a?(Hash)
          hash_to_hidden(value, ns)
        else
          %(<input type="hidden" name="#{ns}" value="#{value}">)
        end
      end.join("\n")
    end
  end
end
