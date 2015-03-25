module Surveyor
  module Models
    module DependencyMethods
      def self.included(base)
        # Associations
        base.send :belongs_to, :question
        base.send :belongs_to, :question_group
        base.send :belongs_to, :survey_section
        base.send :has_many, :dependency_conditions, :dependent => :destroy

        @@validations_already_included ||= nil
        unless @@validations_already_included
          # Validations
          base.send :validates_presence_of, :rule
          base.send :validates_each, :question_id, :question_group_id, :survey_section_id do |record, attr, value|
            unless [record.question_id, record.question_group_id, record.survey_section_id].any?{|val| val.present?}
              record.errors.add('Question_id, Question_group_id, or Survey_section_id must be present for a valid dependency')
            end
          end
          @@validations_already_included = true
        end

        # Whitelisting attributes
        #base.send :attr_accessible, :question, :question_group, :question_id, :question_group_id, :rule,:survey_section,:survey_section_id

        # Attribute aliases
        base.send :alias_attribute, :dependent_question_id, :question_id
      end

      # Instance Methods
      def question_group_id=(i)
        write_attribute(:question_id, nil) unless i.nil?
        write_attribute(:question_group_id, i)
      end

      def question_id=(i)
        write_attribute(:question_group_id, nil) unless i.nil?
        write_attribute(:question_id, i)
      end

      # Has this dependency has been met in the context of response_set?
      # Substitutes the conditions hash into the rule and evaluates it
      def is_met?(response_set)
        ch = conditions_hash(response_set)
        return false if ch.blank?
        # logger.debug "rule: #{self.rule.inspect}"
        # logger.debug "rexp: #{rgx.inspect}"
        # logger.debug "keyp: #{ch.inspect}"
        # logger.debug "subd: #{self.rule.gsub(rgx){|m| ch[m.to_sym]}}"
        rgx = Regexp.new(self.dependency_conditions.map{|dc| ["a","o"].include?(dc.rule_key) ? "\\b#{dc.rule_key}(?!nd|r)\\b" : "\\b#{dc.rule_key}\\b"}.join("|")) # exclude and, or
        eval(self.rule.gsub(rgx){|m| ch[m.to_sym]})
      end

      # A hash of the conditions (keyed by rule_key) and their evaluation (boolean) in the context of response_set
      def conditions_hash(response_set)
        hash = {}
        self.dependency_conditions.each{|dc| hash.merge!(dc.to_hash(response_set))}
        return hash
      end
    end
  end
end
