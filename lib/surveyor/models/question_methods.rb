require 'surveyor/common'

module Surveyor
  module Models
    module QuestionMethods
      def self.included(base)
        # Associations
        base.send :belongs_to, :survey_section
        base.send :belongs_to, :question_group, :dependent => :destroy
        base.send :has_many, :answers, :order => "display_order ASC", :dependent => :destroy # it might not always have answers
        base.send :has_one, :dependency, :dependent => :destroy
        base.send :belongs_to, :correct_answer, :class_name => "Answer", :dependent => :destroy

        # Scopes
        base.send :default_scope, :order => "display_order ASC"

        @@validations_already_included ||= nil
        unless @@validations_already_included
          # Validations
          base.send :validates_presence_of, :text, :display_order
          # this causes issues with building and saving
          #, :survey_section_id
          base.send :validates_inclusion_of, :is_mandatory, :in => [true, false]

          @@validations_already_included = true

        end

        # Whitelisting attributes
        #base.send :attr_accessible, :data_attributes, :question_number, :survey_section, :question_group, :survey_section_id, :question_group_id, :text, :short_text, :help_text, :pick, :reference_identifier, :data_export_identifier, :common_namespace, :common_identifier, :display_order, :display_type, :is_mandatory, :display_width, :custom_class, :custom_renderer, :correct_answer_id, :rights, :edit_only_if, :beforesave_macro_ruby_module, :aftersave_macro_ruby_module, :beforesave_macro_ruby_inline, :aftersave_macro_ruby_inline, :aftercreate_macro_ruby_module, :linked_repeater, :data_attributes, :access_level, :afterupdate_macro_ruby_module, :options, :grid_display, :answer_generator, :master_data_export_identifier, :help_link, :question_number, :do_not_copy
      end

      include RenderText

      # Instance Methods
      def initialize(*args)
        super(*args)
        default_args
      end

      def default_args
        self.is_mandatory ||= false
        self.display_type ||= "default"
        self.pick ||= "none"
        self.data_export_identifier ||= Surveyor::Common.normalize(text)
        self.short_text ||= text
        self.api_id ||= Surveyor::Common.generate_api_id
      end

      def pick=(val)
        write_attribute(:pick, val.nil? ? nil : val.to_s)
      end
      def display_type=(val)
        write_attribute(:display_type, val.nil? ? nil : val.to_s)
      end

      def mandatory?
        self.is_mandatory == true
      end

      def dependent?
        self.dependency != nil
      end
      def triggered?(response_set)
        dependent? ? self.dependency.is_met?(response_set) : true
      end
      def css_class(response_set)
        [(dependent? ? "q_dependent" : nil), (triggered?(response_set) ? nil : "q_hidden"), custom_class].compact.join(" ")
      end

      def part_of_group?
        !self.question_group.nil?
      end
      def solo?
        self.question_group.nil?
      end

      def split_text(part = nil)
        (part == :pre ? text.split("|",2)[0] : (part == :post ? text.split("|",2)[1] : text)).to_s
      end

      def renderer(g = question_group)
        r = [g ? g.renderer.to_s : nil, display_type].compact.join("_")
        r.blank? ? :default : r.to_sym
      end
    end
  end
end
