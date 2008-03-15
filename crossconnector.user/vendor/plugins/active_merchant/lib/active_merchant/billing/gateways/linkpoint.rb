# Portions of the LinkPoint Gateway by Ryan Heneise
#--
# Copyright (c) 2005 Tobias Luetke
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'rexml/document'

module ActiveMerchant
  module Billing
    
    # A valid store number is required. Unfortunately, with LinkPoint 
    # YOU CAN'T JUST USE ANY OLD STORE NUMBER. Also, you can't just 
    # generate your own PEM file. You'll need to use a special PEM file 
    # provided by LinkPoint. 
    #
    # Go to http://www.linkpoint.com/support/sup_teststore.asp to set up 
    # a test account and obtain your PEM file. 
    # 
    # 
    # Valid Options
    # :result => 
    #   LIVE                  Production mode
    #   GOOD                  Approved response in test mode
    #   DECLINE               Declined response in test mode
    #   DUPLICATE             Duplicate response in test mode
    #                     
    # :ponumber               Order number
    #
    # :transactionorigin =>   Source of the transaction
    #    ECI                  Email or Internet
    #    MAIL                 Mail order
    #    MOTO                 Mail order/Telephone
    #    TELEPHONE            Telephone
    #    RETAIL               Face-to-face
    #
    # :ordertype =>       
    #    SALE                 Real live sale
    #    PREAUTH              Authorize only
    #    POSTAUTH             Forced Ticket or Ticket Only transaction
    #    VOID             
    #    CREDIT           
    #    CALCSHIPPING         For shipping charges calculations
    #    CALCTAX              For sales tax calculations
    #                     
    # Recurring Options   
    # :action =>          
    #    SUBMIT           
    #    MODIFY           
    #    CANCEL           
    #                     
    # :installments           Identifies how many recurring payments to charge the customer
    # :startdate              Date to begin charging the recurring payments. Format: YYYYMMDD or "immediate"
    # :periodicity  =>    
    #     MONTHLY         
    #     BIMONTHLY       
    #     WEEKLY          
    #     BIWEEKLY        
    #     YEARLY          
    #     DAILY           
    # :threshold              Tells how many times to retry the transaction (if it fails) before contacting the merchant.
    # :comments               Uh... comments
    #
    #
    # For reference: 
    #
    # https://www.linkpointcentral.com/lpc/docs/Help/APIHelp/lpintguide.htm
    #
    #  Entities = {
    #    :payment => [:subtotal, :tax, :vattax, :shipping, :chargetotal],
    #    :billing => [:name, :address1, :address2, :city, :state, :zip, :country, :email, :phone, :fax, :addrnum],
    #    :shipping => [:name, :address1, :address2, :city, :state, :zip, :country, :weight, :items, :carrier, :total],
    #    :creditcard => [:cardnumber, :cardexpmonth, :cardexpyear, :cvmvalue, :track],
    #    :telecheck => [:routing, :account, :checknumber, :bankname, :bankstate, :dl, :dlstate, :void, :accounttype, :ssn],
    #    :transactiondetails => [:transactionorigin, :oid, :ponumber, :taxexempt, :terminaltype, :ip, :reference_number, :recurring, :tdate],
    #    :periodic => [:action, :installments, :threshold, :startdate, :periodicity, :comments],
    #    :notes => [:comments, :referred]
    #  }
    #
    #
    # IMPORTANT NOTICE: 
    # 
    # LinkPoint's Items entity is not yet supported in this module.
    # 
    class LinkpointGateway < Base     
      attr_reader :response
      attr_reader :options
      
      # Your global PEM file. This will be assigned to you by linkpoint
      # 
      # Example: 
      # 
      # ActiveMerchant::Billing::LinkpointGateway.pem_file = File.read( File.dirname(__FILE__) + '/../mycert.pem' )
      # 
      cattr_accessor :pem_file
      
      # We do this so that we can submit to LinkPoint's staging server 
      # instead of getting a bogus response in regular test mode: 
      cattr_accessor :gateway_mode
      @@gateway_mode = :staging
      
      cattr_accessor :options
      
      LIVE_URL     = 'https://secure.linkpt.net:1129/'
      STAGING_URL  = 'https://staging.linkpt.net:1129/'
      
              
      def initialize(options={})
        requires!(options, :store_number)
        
        @options = {
          :store_number => "123456",
          :result => test? ? "GOOD" : "LIVE"
        }.update(options)
        
        #@pem = @options[:pem] || LinkpointGateway.pem_file
        @pem = LinkpointGateway.pem_file
        
        raise ArgumentError, "You need to pass in your pem file using the :pem parameter or set it globally using ActiveMerchant::Billing::LinkpointGateway.pem_file = File.read( File.dirname(__FILE__) + '/../mycert.pem' ) or similar" if @pem.nil?
        
        @@options = @options
      end
      
      # Send a purchase request with periodic options
      # Recurring Options   
      # :action =>          
      #    SUBMIT           
      #    MODIFY           
      #    CANCEL           
      #                     
      # :installments           Identifies how many recurring payments to charge the customer
      # :startdate              Date to begin charging the recurring payments. Format: YYYYMMDD or "immediate"
      # :periodicity  =>    
      #     :monthly         
      #     :bimonthly       
      #     :weekly          
      #     :biweekly        
      #     :yearly          
      #     :daily           
      # :threshold              Tells how many times to retry the transaction (if it fails) before contacting the merchant.
      # :comments               Uh... comments
      #
      def recurring(money, creditcard, options={})
        requires!(options, [:periodicity, :bimonthly, :monthly, :biweekly, :weekly, :yearly, :daily], :installments, :order_id )
        
        options.update({:ordertype => "SALE",
                      :action => options[:action] || "SUBMIT",
                      :installments => options[:installments] || 12,
                      :startdate => options[:startdate].to_s || "immediate",
                      :periodicity => options[:periodicity].to_s || "monthly",
                      :comments => options[:comments] || nil,
                      :threshold => options[:threshold] || 3
                      })
        commit(money, creditcard, options)
      end
      
      #
      # Buy the thing
      #
      def purchase(money, creditcard, options={})
        requires!(options, :order_id)
        options.update({
                      :ordertype => "SALE"
                     })
        commit(money, creditcard, options)
      end
      
      #
      # Authorize a transaction
      # 
      # Reserves the funds on the customer's credit card, but does not charge the card.
      #
      def authorize(money, creditcard, options = {})
        requires!(options, :order_id)
        options.update({
                      :ordertype => "PREAUTH"
                     })
        commit(money, creditcard, options)
      end
      
      #
      # Post an authorization. 
      #
      # Captures the funds from an authorized transaction. 
      # Order_id must be a valid order id from a prior authorized transaction.
      # 
      def capture(money, creditcard, options = {})
        requires!(options, :order_id)
        options.update({
                      :ordertype => "POSTAUTH"
                     })
        commit(money, creditcard, options)  
      end
      
      # 
      # Refund an order
      # 
      # Order_id must be a valid order id previously submitted by SALE
      #
      def credit(money, creditcard, options = {})
        requires!(options, :order_id)
        options.update({
                      :ordertype => "CREDIT"
                     })
        commit(money, creditcard, options)
      end
      
      def self.supported_cardtypes
        [:visa, :master, :discover, :american_express]
      end      
      
      private
      
      # Commit the transaction by posting the XML file to the LinkPoint server
      def commit(money, creditcard, options = {})
        parameters = parameters(money, creditcard, options)

        if result = test_result_from_cc_number(parameters[:creditcard][:cardnumber])
          return result
        end
        
        # breakpoint("LinkpointGateway#Commit")
        
        data = ssl_post post_data(parameters)
        @response = parse(data)
        
        success = (@response[:r_approved] == "APPROVED")
        message = response[:r_message]
        
        Response.new(success, message, @response)
      end
      
      
      # Build the XML file
      def post_data(parameters = {})
        xml = REXML::Document.new
        order = xml.add_element("order")
        
        # Merchant Info
        merchantinfo = order.add_element("merchantinfo")
        merchantinfo.add_element("configfile").text = @options[:store_number]
        
        # Loop over the parameters hash to construct the XML string
        for key, value in parameters
          elem = order.add_element(key.to_s)
          for k, v in parameters[key]
            elem.add_element(k.to_s).text = parameters[key][k].to_s if parameters[key][k]
          end
          # Linkpoint doesn't understand empty elements: 
          order.delete(elem) if elem.size == 0
        end
        
        return xml.to_s
      end
      
      # Set up the parameters hash just once so we don't have to do it
      # for every action. 
      def parameters(money, creditcard, options = {})
        
        return {
          :payment => {
            :subtotal           => amount(options[:subtotal]),
            :tax                => amount(options[:tax]),
            :vattax             => amount(options[:vattax]),
            :shipping           => amount(options[:shipping]),
            :chargetotal        => amount(money)
          },
          :billing => {
            :name               => creditcard.name,
            :company            => creditcard.company,
            :address1           => creditcard.address1,
            :address2           => creditcard.address2,
            :city               => creditcard.city,
            :state              => creditcard.state,
            :zip                => creditcard.zip,
            :country            => creditcard.country,
            :phone              => creditcard.phone,
            :fax                => creditcard.fax,
            :email              => creditcard.email,
            :addrnum            => creditcard.addrnum
          },
          :creditcard => {
            :cardnumber         => creditcard.number,
            :cardexpmonth       => creditcard.month,
            :cardexpyear        => creditcard.year.to_s.length == 4 ? creditcard.year.to_s[2,3] : creditcard.year,
            :cvmvalue           => creditcard.cvmvalue,
            :cvmindicator       => creditcard.cvmindicator,
            :track              => creditcard.track
          },
          :transactiondetails => {
            :transactionorigin  => options[:transactionorigin] || "ECI",
            :oid                => options[:order_id],
            :ponumber           => options[:ponumber],
            :taxexempt          => options[:taxexempt] || "Y",
            :terminaltype       => options[:terminaltype],
            :ip                 => options[:ip],
            :reference_number   => options[:reference_number],
            :recurring          => options[:recurring] || "NO",  #DO NOT USE if you are using the periodic billing option. 
            :tdate              => options[:tdate]
          },
          :orderoptions => {
            :ordertype          => options[:ordertype],
            :result             => @options[:result]
          },              
          :periodic => {  
            :action             => options[:action],
            :installments       => options[:installments], 
            :threshold          => options[:threshold], 
            :startdate          => options[:startdate], 
            :periodicity        => options[:periodicity], 
            :comments           => options[:comments]
          },              
          :shipping => {  
            :name               => options[:shipping_name],
            :address1           => options[:shipping_address1],
            :address2           => options[:shipping_address2],
            :city               => options[:shipping_city],
            :state              => options[:shipping_state],
            :zip                => options[:shipping_zip],
            :country            => options[:shipping_country],
            :weight             => options[:shipping_weight],
            :items              => options[:shipping_items],
            :carrier            => options[:shipping_carrier],
            :total              => options[:shipping_total]
          },              
          :telecheck => { 
            :routing            => options[:telecheck_routing],
            :account            => options[:telecheck_account],
            :checknumber        => options[:telecheck_checknumber],
            :bankname           => options[:telecheck_bankname],
            :dl                 => options[:telecheck_dl],
            :dlstate            => options[:telecheck_dlstate],
            :void               => options[:telecheck_void],
            :accounttype        => options[:telecheck_accounttype],
            :ssn                => options[:telecheck_ssn],
          }
        }
        
      end
      
      # For reference, a typical response...
      # <r_csp></r_csp>
      # <r_time></r_time>
      # <r_ref></r_ref>
      # <r_error></r_error>
      # <r_ordernum></r_ordernum>
      # <r_message>This is a test transaction and will not show up in the Reports</r_message>
      # <r_code></r_code>
      # <r_tdate>Thu Feb 2 15:40:21 2006</r_tdate>
      # <r_score></r_score>
      # <r_authresponse></r_authresponse>
      # <r_approved>APPROVED</r_approved>
      # <r_avs></r_avs>
      def parse(xml)
        response = {:r_message => "Global Error Receipt", :r_complete => false}
        
        xml = "<response>#{xml}</response>"
        xml = REXML::Document.new(xml)
        xml.elements.each('//response/*') do |node|
          response[node.name.downcase.to_sym] = normalize(node.text)
        end unless xml.root.nil?
        
        response
      end
      
      # Return a string with the amount in the format 0.00
      def amount(money)
        return nil if money.nil?
        cents = money.respond_to?(:cents) ? money.cents : money 

        if money.is_a?(String) or cents.to_i < 0
          raise ArgumentError, 'money amount must be either a Money object or a positive integer in cents.' 
        end
        sprintf("%.2f", cents.to_f/100)
      end
      
      # Redefine ssl_post to use our PEM file
      def ssl_post(data)
        raise "PEM file invalid or missing!" unless @pem =~ %r{RSA.*CERTIFICATE}m
        
        #
        # This part is a little funny because in the development environment, 
        # we want to use the STAGING_URL, even though we set Base.gateway_mode 
        # to production. Otherwise, we would be submitting transactions 
        # to the LIVE_URL in our application's development environment, 
        # which in general would be a very BAD thing! 
        uri = URI.parse(test? ? STAGING_URL : LIVE_URL)
        
        http = Net::HTTP.new(uri.host, uri.port) 
        
        http.verify_mode    = OpenSSL::SSL::VERIFY_NONE unless @ssl_strict
        http.use_ssl        = true
        http.cert           = OpenSSL::X509::Certificate.new(@pem)
        http.key            = OpenSSL::PKey::RSA.new(@pem)
        
        http.post(uri.path, data).body      
      end
      
      # Make a ruby type out of the response string
      def normalize(field)
        case field
        when "true"   then true
        when "false"  then false
        when ""       then nil
        when "null"   then nil
        else field
        end        
      end
      
      def test?
        Base.gateway_mode == :test || LinkpointGateway.gateway_mode == :staging
      end

    end
  end
end