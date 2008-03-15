# Schema as of Fri Oct 06 12:31:46 CDT 2006 (schema version 37)
#
#  id                  :integer       not null
#  invoice_id          :integer       
#  price               :integer       default(0), not null
#  period              :string(255)   
#  quantity            :integer       
#  comment             :text          
#  name                :string(255)   
#  description         :text          
#

# 
# This model is mostly so that I can assess discounts and credits in the future
# 
class InvoiceItem < ActiveRecord::Base
  belongs_to :invoice
  
  def money
    Money.new(self.price)
  end
end
