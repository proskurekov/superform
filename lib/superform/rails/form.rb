module Superform
  module Rails
    # A Phlex::HTML view module that accepts a model and sets
    # a `Superform::Namespace` with the `Object#model_name` as the key and maps
    # the object to form fields and namespaces.
    #
    # The `Form::Field` is a class that's meant to be extended so you can
    # customize the `Form` inputs to your applications needs. Defaults for the
    # `input`, `button`, `label`, and `textarea` tags are provided.
    #
    # The `Form` component also handles Rails authenticity tokens via the
    # `authenticity_toklen_field` method and the HTTP verb via the
    # `_method_field`.
    class Form < Component
      attr_reader :model

      delegate \
          :field,
          :collection,
          :namespace,
          :assign,
          :serialize,
        to: :@namespace


      def initialize(model, action: nil, method: nil, **attributes)
        @model = model
        @action = action
        @method = method
        @attributes = attributes
        @namespace = Namespace.root(
          key,
          object: model,
          field_class: self.class::Field
        )
      end

      def around_template(&)
        form_tag do
          authenticity_token_field
          _method_field
          super
        end
      end

      def form_tag(&)
        form action: form_action, method: form_method, **@attributes, &
      end

      def template(&block)
        yield_content(&block)
      end

      def submit(value = submit_value, **attributes)
        input **attributes.merge(
          name: "commit",
          type: "submit",
          value: value
        )
      end

      def key
        @model.model_name.param_key
      end

      protected
        def authenticity_token_field
          input(
            name: "authenticity_token",
            type: "hidden",
            value: helpers.form_authenticity_token
          )
        end

        def _method_field
          input(
            name: "_method",
            type: "hidden",
            value: _method_field_value
          )
        end

        def _method_field_value
          @method || @model.persisted? ? "patch" : "post"
        end

        def submit_value
          "#{resource_action.to_s.capitalize} #{@model.model_name}"
        end

        def resource_action
          @model.persisted? ? :update : :create
        end

        def form_action
          @action ||= helpers.url_for(action: resource_action)
        end

        def form_method
          @method.to_s.downcase == "get" ? "get" : "post"
        end
    end
  end
end
