module Surveyor
  module Models
    module SurveySectionMethods
      #def with_includes

        #base.send :scope, :with_includes, ->{{ :include => {:questions => [:answers, :question_group, {:dependency => :dependency_conditions}]}}}
      #end

      def self.included(base)
        # Associations
        base.send :has_many, :questions, ->{ base.order("display_order ASC") }, :dependent => :destroy
        base.send :has_many, :question_groups, ->{ base.order("display_order ASC") }, :dependent => :destroy
        base.send :has_many, :dependencies, ->{ base.order("display_order ASC") }, :dependent => :destroy
        base.send :belongs_to, :survey

        # Scopes
        base.send :default_scope, -> { base.order("display_order ASC") }
        #base.send :scope, :with_includes, { :include => {:questions => [:answers, :question_group, {:dependency => :dependency_conditions}]}} # original version
        base.send :scope, :with_includes, -> { base.includes(:questions => [:answers, :question_group, {:dependency => :dependency_conditions}]) }


        @@validations_already_included ||= nil
        unless @@validations_already_included
          # Validations
          base.send :validates_presence_of, :title, :display_order
          # this causes issues with building and saving
          #, :survey

          @@validations_already_included = true
        end

        # Whitelisting attributes
        #base.send :attr_accessible, :survey, :survey_id, :title, :description, :reference_identifier, :data_export_identifier, :common_namespace, :common_identifier, :display_order, :custom_class, :rights, :show_display
      end

      # Instance Methods
      def initialize(*args)
        super(*args)
        default_args
      end

      def default_args
        self.data_export_identifier ||= Surveyor::Common.normalize(title)
      end

      def questions_and_groups
        questions.each_with_index.map do |q,i|
          if q.part_of_group?
            if (i+1 >= questions.size) or (q.question_group_id != questions[i+1].question_group_id)
              q.question_group
            end
          else
            q
          end
        end.compact
      end
    end
  end
end
