require 'surveyor/common'
require 'rabl'

module Surveyor
  module Models
    module SurveyMethods
      def self.included(base)
        # Associations
        base.send :has_many, :sections, :class_name => "SurveySection", :order => 'display_order', :dependent => :destroy
        base.send :has_many, :sections_with_questions, :include => :questions, :class_name => "SurveySection", :order => 'display_order'
        base.send :has_many, :response_sets

        # Scopes
        base.send :scope, :with_sections, {:include => :sections}
        
        @@validations_already_included ||= nil
        unless @@validations_already_included
          # Validations
          base.send :validates_presence_of, :title
          base.send :validates_uniqueness_of, :survey_version, :scope => :access_code, :message => "survey with matching access code and version already exists"
          
          @@validations_already_included = true
        end
        
        # Whitelisting attributes
        base.send :attr_accessible, :title, :description, :reference_identifier, :data_export_identifier, :common_namespace, :common_identifier, :css_url, :custom_class, :display_order, :access_code

        # Class methods
        base.instance_eval do
          def to_normalized_string(value)
            # replace non-alphanumeric with "-". remove repeat "-"s. don't start or end with "-"
            value.to_s.downcase.gsub(/[^a-z0-9]/,"-").gsub(/-+/,"-").gsub(/-$|^-/,"")
          end
        end
      end

      # Instance methods
      def initialize(*args)
        super(*args)

        if(args.present? && (args[0][:access_code] || args[0][:title]) )
          if(args[0][:access_code])
            surveys = Survey.where(:access_code => args[0][:access_code]).order("survey_version DESC").limit(1)           
          else
            surveys = Survey.where(:access_code => Survey.to_normalized_string(args[0][:title])).order("survey_version DESC").limit(1)
          end
          self.access_code = (args[0][:access_code]) ? args[0][:access_code] : Survey.to_normalized_string(args[0][:title])
          self.survey_version     = surveys.first.survey_version.to_i + 1 if surveys.any?
        end

        default_args
      end

      def default_args
        self.api_id ||= Surveyor::Common.generate_api_id
        self.display_order ||= Survey.count
      end

      def title=(value)
        return if value == self.title
        super(value)
      end

      def active?
        self.active_as_of?(DateTime.now)
      end
      def active_as_of?(date)
        (active_at && active_at < date && (!inactive_at || inactive_at > date)) ? true : false
      end
      def activate!
        self.active_at = DateTime.now
        self.inactive_at = nil
      end
      def deactivate!
        self.inactive_at = DateTime.now
        self.active_at = nil
      end
      def as_json(options = nil)
        template_paths = ActionController::Base.view_paths.collect(&:to_path)
        Rabl.render(self, 'surveyor/export.json', :view_path => template_paths, :format => "hash")
      end      
    end
  end
end
