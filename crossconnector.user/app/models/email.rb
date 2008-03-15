# Schema as of Fri Oct 06 12:31:46 CDT 2006 (schema version 37)
#
#  id                  :integer       not null
#  from                :string(255)   
#  to                  :string(255)   
#  cc                  :string(255)   
#  bcc                 :string(255)   
#  charset             :string(255)   
#  headers             :string(255)   
#  subject             :text          
#  body                :text          
#  raw                 :text          
#

class Email < ActiveRecord::Base
end
