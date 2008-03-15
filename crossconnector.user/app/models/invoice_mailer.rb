class InvoiceMailer < ActionMailer::Base
    
  def receive(email)
    # 
    # First off, save the email in the database...
    # (discards attachments)
    #
    Email.create(:from => email.from, #.join(", "), 
                   :to => email.to, #.join(", "),
                   :cc => email.cc, #.join(", "),
                   :bcc => email.bcc, #.join(", "),
                   :charset => email.charset,
                   :subject => email.subject,
                   :body => email.body,
                   :raw => email.to_s)
    
    begin
      # 
      # See if subject contains an invoice ID
      #
      order_id = email.subject.match(/^Periodic (Bill for|Billing) Order (.+) (Approved|Submitted)$/)[2] 
      
      begin
        #
        # Subject contains a subscription ID, so try to make the invoice...
        #
        re = /(CC-[\w\d]{16})-(\d+)/
        email_id         = order_id.match(re)[2] rescue nil
        email_identifier = order_id.match(re)[1] rescue nil
        
        Invoice.transaction do
          begin
            subscription = Subscription.find_by_identifier(email_identifier)
            
            invoice = subscription.invoices.create(
                              :email_id         => email_id,
                              :email_identifier => email_identifier,
                              :email_from       => email.from[0],
                              :email_body       => email.body,
                              :email_subject    => email.subject,
                              :billing_date     => email.date,
                              :snapshot         => email.to_s,
                              :total            => email.body.match(/(Amount: \$)(\d*.\d*)/)[2].to_f * 100)
                              
            invoice_item = invoice.items.create(:invoice_id => invoice.id,
                              :name => invoice.subscription.plan.name,
                              :period => invoice.subscription.periodicity.to_s.slice(0,(invoice.subscription.periodicity.to_s.length - 2)),
                              :price => invoice.subscription.price,
                              :quantity => 1,
                              :description => invoice.subscription.plan.description)
                      
            # save and return invoice
            # This should send an invoice to the customer, or an email to the admin if there is an error
                        
            return InvoiceMailer.deliver_invoice(invoice)
          rescue
            raise "Invoice error: #{invoice.errors.full_messages.join(", ")}"
          end
          
        end
        
      rescue Exception => e
        #
        # Could not successfully create the invoice
        # Send notification to administrator
        #
        return InvoiceMailer.deliver_failed_invoice(email)
      end

    rescue Exception => e
      #
      # Message was not an invoice, so forward it to System Default email
      #
      return InvoiceMailer.deliver_forward(email)
    end
  end
  
  def invoice(invoice, sent_at = Time.now)
    @subject    = "CrossConnector Subscription (Invoice ##{invoice.id})"
    @recipients = invoice.subscription.email
    @bcc        = "support@crossconnector.com"
    @from       = App::CONFIG[:admin_email]
    @sent_on    = sent_at
    @headers    = {}
    @body["invoice"] = invoice
  end
  
  def confirmation(subscription, action, sent_at = Time.now)
    @subject    = "Your subscription has been #{action}d"
    @recipients = subscription.email
    @from       = App::CONFIG[:admin_email]
    @sent_on    = sent_at
    @headers    = {}
    @body["subscription"] = subscription
    @body["action"] = action
  end
  
  def failed_invoice(email, sent_at = Time.now)
    @subject    = "Failed Invoice: #{email.subject}"
    @recipients = App::CONFIG[:admin_email]
    @from       = email.from || App::CONFIG[:admin_email]
    @sent_on    = sent_at
    @headers    = {}
    @body["email"] = email
  end
  
  def forward(email, sent_at = Time.now)
    @subject    = "Forward from Billing: #{email.subject}"
    @recipients = App::CONFIG[:admin_email]
    @from       = email.from
    @sent_on    = sent_at
    @headers    = {}
    @body["email"] = email
  end
  
  def notification_of_transaction(subscription, sent_at = Time.now)
    @subject    = "Notification of Transaction"
    @recipients = App::CONFIG[:admin_email]
    @from       = App::CONFIG[:admin_email]
    @sent_on    = sent_at
    @headers    = {}
    @body["subscription"] = subscription
  end
  
  def notification_of_failed_transaction(subscription, transaction, sent_at = Time.now)
    @subject    = "Notification of Failed Transaction"
    @recipients = App::CONFIG[:admin_email]
    @from       = App::CONFIG[:admin_email]
    @sent_on    = sent_at
    @headers    = {}
    @body["subscription"] = subscription
    @body["transaction"] = transaction
  end
  
  def notification_of_billing_cancellation(homebase, sent_at = Time.now)
    @subject    = "Cancel Billing Notice"
    @recipients = App::CONFIG[:admin_email]
    @from       = App::CONFIG[:admin_email]
    @sent_on    = sent_at
    @headers    = {}
    @body["homebase"] = homebase
  end
end
