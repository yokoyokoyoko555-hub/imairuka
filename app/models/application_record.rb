class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  before_validation :assign_default_company, if: :needs_default_company?

  private

  def needs_default_company?
    has_attribute?(:company_id) && company_id.blank? && self.class.reflect_on_association(:company)
  end

  def assign_default_company
    self.company ||= Current.company || Company.first
  end
end
