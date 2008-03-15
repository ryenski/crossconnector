# Schema as of Fri Oct 06 12:31:46 CDT 2006 (schema version 37)
#
#  id                  :integer       not null
#  subscription_id     :integer       
#  total               :integer       default(0), not null
#  created_at          :datetime      
#  comment             :text          
#  billing_name        :string(255)   
#  billing_address     :string(255)   
#  billing_city        :string(255)   
#  billing_state       :string(255)   
#  billing_zip         :string(255)   
#  billing_country     :string(255)   
#  payment_last_four   :string(255)   
#  snapshot            :text          
#  billing_date        :datetime      
#  period_start        :datetime      
#  period_end          :datetime      
#  payment_method      :string(255)   
#  pending             :integer       
#

  # Schema as of Sun Apr 09 18:08:46 PDT 2006 (schema version 31)
#
#  id                  :integer       not null
#  subscription_id     :integer       
#  created_at          :datetime      
#  comment             :text          
#  billing_name        :string(255)   
#  billing_address     :string(255)   
#  billing_city        :string(255)   
#  billing_state       :string(255)   
#  billing_zip         :string(255)   
#  billing_country     :string(255)   
#  payment_last_four   :string(255)   
#  snapshot            :text          
#  total               :integer       
#  billing_date        :datetime      
#  period_start        :datetime      
#  period_end          :datetime      
#  payment_method      :string(255)   
#  pending             :integer       
#

class Invoice < ActiveRecord::Base
  belongs_to :subscription
  has_many :items, :class_name => "InvoiceItem"
  
  # composed_of :total, :class_name => "Money", :mapping => [%w(cents total)]
  
  attr_accessor :email_from
  attr_accessor :email_body
  attr_accessor :email
  attr_accessor :email_subject
  attr_accessor :email_id
  attr_accessor :email_identifier
  
  after_save :update_subscription
  
  validate :belongs_to_subscription
  #validate :email_from_gateway, :on => :create
  validate :name_matches
  validate :address_matches 
  validate :city_matches
  validate :state_matches
  validate :zip_matches
  validate :country_matches
  validate :total_matches
  
  #validate :expected_billing_date
  
  #validates_presence_of :total, :on => :save
  #validates_presence_of :period_start, :on => :save
  #validates_presence_of :period_end, :on => :save
  validates_presence_of :billing_date, :on => :save
  #validates_presence_of :payment_method, :on => :save
  #validates_presence_of :payment_last_four, :on => :save
  
  #
  # Only create a new invoice if we can find a valid subscription based 
  # on the info passed in from the mailer. Invoices are triggered by the 
  # receipt of an email from the payment gateway. As a security measure, 
  # no information is actually stored from the email (except the raw 
  # source of the email is kept). Instead, the information in the email 
  # is used to validate against values expected in the subscription record: 
  #    
  #    Invoice amount
  #    Date (30 days since the last invoice)
  #    Name and address
  #    Invoice number
  #    Invoice identifier
  #
  # If everything looks ok, then the system creates an invoice email to send to the customer. 
  #
  # If any of these values are not matched, an exception is thrown and the 
  # administrator is notified by email to check out the anomoly. 
  # 
  def initialize(*args)
    super *args
    
    begin
      subscription = Subscription.find_by_id_and_identifier(email_id, email_identifier)
      self.subscription = subscription if self.subscription.nil?
      
      # Validation values: 
      self.billing_name       = email_body.match(/Customer:\s*(.+$)/)[1].strip rescue nil if self.billing_name.nil?
      self.billing_address    = email_body.match(/Address:\s*([\w\d\s]+)$/)[1].strip rescue nil if self.billing_address.nil?
      self.billing_city       = email_body.match(/City:\s*([\w\s]+)$/)[1].strip rescue nil if self.billing_city.nil?
      self.billing_state      = email_body.match(/State:\s*([\w]+)$/)[1].strip rescue nil if self.billing_state.nil?
      self.billing_country    = email_body.match(/Country:\s*([\w]+)$/)[1].strip rescue nil if self.billing_country.nil?
      self.billing_zip        = email_body.match(/Zip:\s*([\w]+)$/)[1].strip rescue nil if self.billing_zip.nil?
                            
      # Real values         
      self.total              = email_body.match(/(Amount:\s*\$)(\d+.\d+)/)[2].to_f * 100 rescue nil if self.total.nil?
      self.period_start       = self.billing_date if self.period_start.nil?
      self.period_end         = self.billing_date + 1.month if self.period_end.nil?
      self.comment            = email_body if self.comment.nil?
      self.payment_method     = subscription.card_type if self.payment_method.nil?
      self.payment_last_four  = subscription.last_four if self.payment_last_four.nil?
      
    rescue Exception => e
      nil
    end
    
  end

  def create_item
    i = self.generate_item
    i.save
  end
  
  def generate_item
    InvoiceItem.new(:invoice_id => self.id,
                      :name => self.subscription.plan.name,
                      :period => self.subscription.periodicity.to_s.slice(0,(self.subscription.periodicity.to_s.length - 2)),
                      :price => self.subscription.price,
                      :quantity => 1,
                      :description => self.subscription.plan.description)
  end
  
  def deliver
    InvoiceMailer.deliver_invoice(self)
  end
  
  # After saving, we want to change some things about the subscription.
  def update_subscription
    self.subscription.update_attribute(:pending, 0)
  end
  
  def money
    Money.new(self.total)
  end
  
  def decrypted_last_four
    ActiveRecord::PasswordSystem.decrypt(self.payment_last_four, self.subscription.salt) rescue nil
  end
  
  def belongs_to_subscription
    errors.add_to_base("Could not find a matching subscription.") unless self.subscription
  end
  
  def total_matches
    errors.add(:total, "does not match") unless self.subscription and self.total == self.subscription.price
  end
  
  def expected_billing_date
    billing_date = Time.mktime(self.billing_date.year, self.billing_date.month, 1)
    expected_date = Time.mktime(self.subscription.next_billing_date.year, self.subscription.next_billing_date.month, 1)
    errors.add(:billing_date, "is not the expected date. (Expected #{expected_date} but was #{billing_date})") unless billing_date == expected_date
  end
  
  # 
  # Change this validation method to use
  # Time.next_month
  # 
  def billing_date_within_range
    last = self.subscription.invoices.empty? ? self.subscription.created_at : self.subscription.invoices.last.billing_date rescue 0
    diff = (self.billing_date - last)/60/60/24 rescue 0
    unless diff > 27 and diff < 32
      errors.add(:billing_date, "is not within the expected range.")
    end    
  end

  def email_from_gateway
    errors.add_to_base("Email from invalid sender (#{self.email_from}).") unless self.email_from == App::CONFIG[:gateway_email]
  end
  
  def name_matches
    errors.add(:billing_name, "does not match") unless self.subscription and self.billing_name == self.subscription.name
  end
  
  def address_matches
    errors.add(:billing_address, "does not match") unless self.subscription and self.billing_address == self.subscription.address
  end
  
  def city_matches
    errors.add(:billing_city, "does not match") unless self.subscription and self.billing_city == self.subscription.city
  end
  
  def state_matches
    errors.add(:billing_state, "does not match") unless self.subscription and self.billing_state == self.subscription.state
  end
  
  def zip_matches
    errors.add(:billing_zip, "does not match") unless self.subscription and self.billing_zip == self.subscription.zip
  end
  
  def country_matches
    errors.add(:billing_country, "does not match") unless self.subscription and self.billing_country == self.subscription.country 
  end
  

  
end
