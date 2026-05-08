class ReceiptHistory < ApplicationRecord
  include Discard::Model
  
  belongs_to :receipt
  
  validates :action, presence: true
end
