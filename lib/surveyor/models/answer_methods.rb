require 'surveyor/common'

module Surveyor
  module Models
    module AnswerMethods
      def self.included(base)
        # Associations
        base.send :belongs_to, :question
        base.send :has_many, :responses
        base.send :has_many, :validations, :dependent => :destroy

        # Scopes
        base.send :default_scope, -> { base.order("display_order ASC") }

        @@validations_already_included ||= nil
        unless @@validations_already_included
          # Validations
          base.send :validates_presence_of, :text
          # this causes issues with building and saving
          # base.send :validates_numericality_of, :question_id, :allow_nil => false, :only_integer => true
          @@validations_already_included = true
        end

        # Whitelisting attributes
        #base.send :attr_accessible, :question, :question_id, :text, :short_text, :help_text, :weight, :response_class, :reference_identifier, :data_export_identifier, :common_namespace, :common_identifier, :display_order, :is_exclusive, :display_length, :custom_class, :custom_renderer, :default_value, :display_type, :size, :maxlength, :html_answer_options, :data_attributes, :ext_reference_identifier
      end

      include RenderText

      # Instance Methods
      def initialize(*args)
        super(*args)
        default_args
      end

      def default_args
        self.is_exclusive ||= false
        self.display_type ||= "default"
        self.response_class ||= "answer"
        self.short_text ||= text
        self.data_export_identifier ||= Surveyor::Common.normalize(text)
        self.api_id ||= Surveyor::Common.generate_api_id
      end

      def css_class
        [(is_exclusive ? "exclusive" : nil), custom_class].compact.join(" ")
      end

      def split_or_hidden_text(part = nil, context = nil)
        return "" if display_type == "hidden_label"
        part == :pre ? self.render_answer_text(text.split("|",2)[0], context) : (part == :post ? self.render_answer_text(text.split("|",2)[1], context) : self.render_answer_text(text, context))
      end
    end
  end
end
