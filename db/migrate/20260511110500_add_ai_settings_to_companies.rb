class AddAiSettingsToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :ai_provider, :string, null: false, default: "openai"
    add_column :companies, :ai_model, :string, null: false, default: "gpt-5"
    add_column :companies, :ai_api_key_ciphertext, :text
  end
end
