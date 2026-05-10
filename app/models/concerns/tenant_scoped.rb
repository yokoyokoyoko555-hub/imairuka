module TenantScoped
  extend ActiveSupport::Concern

  included do
    default_scope { Current.company ? where(company_id: Current.company.id) : all }
  end
end
