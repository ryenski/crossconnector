# Schema as of Fri Oct 06 12:31:46 CDT 2006 (schema version 37)
#
#  id                  :integer       not null
#  homebase_id         :integer       
#  created_at          :datetime      
#  updated_at          :datetime      
#  last_action         :string(255)   
#  installments        :integer       
#  start_date          :datetime      
#  periodicity         :string(255)   
#  comments            :text          
#  identifier          :string(255)   
#  name                :string(255)   
#  email               :string(255)   
#  address             :string(255)   
#  address2            :string(255)   
#  city                :string(255)   
#  state               :string(255)   
#  zip                 :string(255)   
#  country             :string(255)   
#  subscription_plan_id:integer       
#  last_four           :string(255)   
#  card_type           :string(255)   
#  price               :integer       
#  trial_ends_at       :datetime      
#  coupon_code         :string(255)   
#  pending             :integer       
#  salt                :string(255)   
#  last_billing_date   :datetime      
#  old_identifiers     :text          
#

class Subscription < ActiveRecord::Base
  belongs_to :homebase
  belongs_to :plan, :class_name => "SubscriptionPlan", :foreign_key => "subscription_plan_id"
  has_many :invoices, :order => "created_at ASC"
  
  attr_accessor :card_number
  attr_accessor :card_expiration_month
  attr_accessor :card_expiration_year
  attr_accessor :terms

  
  validates_presence_of :name
  validates_presence_of :email
  #validates_presence_of :card_number, :if=> Proc.new { |sub| sub.price > 0}
  #validates_presence_of :card_expiration_month, :if=> Proc.new { |sub| sub.price > 0}
  #validates_presence_of :card_expiration_year, :if=> Proc.new { |sub| sub.price > 0}
  #validates_presence_of :price
  validates_acceptance_of :terms
  
  # before_save  :save_price
  before_save  :encrypt_last_four
  after_create :generate_identifier
  
  
  def decrypted_last_four
    ActiveRecord::PasswordSystem.decrypt(self.last_four, self.salt) rescue nil
  end
  
  def create_invoice
    i = self.generate_invoice
    i.save
  end
  
  def generate_invoice
    i = Invoice.new(:subscription_id => self.id,
                   :billing_name => self.name,
                   :billing_address => self.address,
                   :billing_city => self.city,
                   :billing_state => self.state,
                   :billing_country => self.country,
                   :billing_zip => self.zip,
                   :total => self.price,
                   :payment_last_four => self.decrypted_last_four,
                  #:billing_date => self.next_billing_date,
                   :billing_date => Time.now,
                   :email_from => App::CONFIG[:gateway_email],
                   :period_start => Time.mktime(Time.now.year, Time.now.month, 1),
                   :period_end => Time.mktime(Time.now.year, Time.now.month, 1) + 1.month - 1.day)
  end
  
  # Action = SUBMIT if...
  #   new record
  #   no invoices
  #   last invoice older than 30 days...
  # 
  def action
    return "MODIFY" if self.paid? or self.pending?
    return "SUBMIT"
  end
  
  def next_billing_date
    now = Time.now
    case self.periodicity
    when "yearly"
      unless self.invoices.empty?
        return self.invoices.last.billing_date + 1.year
      else
        return first_of_next_month(now)
      end
    else
      
      case self.status
        when "paid"
          return first_of_next_month(self.invoices.last.billing_date)
        when "pending"
          return now if now.day == 1
          return first_of_next_month(now)
        when "free"
          return first_of_next_month(now)
        when "trial"
          return first_of_next_month(trial_ends_at)
      end
    end
    return first_of_next_month(now)
  end
  
  def money
    Money.new(self.price)
  end
  
  def free?
    self.plan.price == 0
  end
  
  def trial?
    !self.free? and (!self.trial_ends_at.nil? and (self.trial_ends_at > Time.now)) 
  end
  
  def paid?
    return false if self.invoices.empty?
    return false if self.lapsed? 
    case self.periodicity
    when "yearly"
      self.invoices.last.created_at > (Time.now - 1.year)
    else
      self.invoices.last.created_at > (Time.now - 1.month)
    end
  end
  
  def lapsed?
    return false if self.free? or self.pending? or self.trial?
    return true if self.invoices.empty?
    case self.periodicity
    when "yearly"
      self.invoices.last.created_at < (Time.now - 1.year)
    else
      self.invoices.last.created_at < (Time.now - 1.month)
    end
  end
  
  def status
    return "lapsed"    if self.lapsed?
    return "free"      if self.free?
    return "pending"   if self.pending?
    return "paid"      if self.paid?
    return "trial"     if self.trial?
    return "unknown"
  end  
  
  # Generate a subscription identifier
  # This is passed to the payment gateway as a prefix to the 
  # Order_ID in order to validate this subscription at a later date.
  # Important: save old identifier into a string. 
  #
  def generate_identifier
    old_ident = "#{self.identifier} #{self.old_identifiers}" 
    ident = "CC-" + (Array.new(12) { CHARS[rand(CHARS.length)] }.join).to_s
    self.update_attributes(:identifier => ident, :old_identifiers => old_ident)
  end
  
  protected
  
  def encrypt_last_four
    if self.card_number
      len = self.card_number.length
      num = self.card_number[(len - 4), len]
      
      self.salt = ActiveRecord::PasswordSystem.hashed("salt-#{Time.now}") 
      self.last_four = ActiveRecord::PasswordSystem.encrypt(num, self.salt)
    end
  end
    
  def first_of_next_month(time)
    Time.mktime(time.next_month.year, time.next_month.month, 1)
  end
  
  CHARS = ("a".."z").to_a + ("A".."Z").to_a + (0..9).to_a
  
  def save_price
    self.price = self.plan.price rescue nil
  end
    
end
