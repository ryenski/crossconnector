require 'rexml/document'

module ActiveMerchant
  module Billing

    class MonerisGateway < Base
     
      # URL
      attr_reader :url 
      attr_reader :response
      attr_reader :options

      def initialize(options = {})
        requires!(options, :login, :password)
      
        # these are the defaults for the moneris test server
        @options = {
          :login      => "store1",
          :password   => "yesguy",          
          :strict_ssl => true,
          :crypt_type => 7
        }.update(options)
                                           
        super      
      end      
    
      def authorize(money, creditcard, options = {})
        requires!(options, :order_id)
      
        parameters = {
          :order_id => options[:order_id],
          :cust_id => options[:customer],
          :amount => amount(money),
          :pan => creditcard.number,
          :expdate => expdate(creditcard),
          :crypt_type => options[:crypt_type] || @options[:crypt_type]
        }                                                             
      
        commit('preauth', parameters)      
      end
      
      def purchase(money, creditcard, options = {})
        requires!(options, :order_id)
      
        parameters = {
          :order_id => options[:order_id],
          :cust_id => options[:customer],
          :amount => amount(money),
          :pan => creditcard.number,
          :expdate => expdate(creditcard),
          :crypt_type => options[:crypt_type] || @options[:crypt_type]
        }                                                             
      
        commit('purchase', parameters)      
      end
      

      def capture(money, ident, options = {})
        requires!(options, :order_id)
                
        raise NotImplementedError, 'We dont implement capture yet'
      end
    
      # We support visa and master card
      def self.supported_cardtypes
        [:visa, :master]
      end
         
      private                       
    
      def amount(money)
        cents = money.respond_to?(:cents) ? money.cents : money 
        
        if money.is_a?(String) or cents.to_i <= 0
          raise ArgumentError, 'money amount must be either a Money object or a positive integer in cents.' 
        end
        
        sprintf("%.2f", cents.to_f/100)
      end             
    
      def expdate(creditcard)
        year  = sprintf("%.4i", creditcard.year)
        month = sprintf("%.2i", creditcard.month)

        "#{year[-2..-1]}#{month}"
      end
  
      def commit(action, parameters)                                 
        if result = test_result_from_cc_number(parameters[:pan])
          return result
        end

        data = ssl_post 'https://esqa.moneris.com:43924/gateway2/servlet/MpgRequest', post_data(action, parameters)
      
        @response = parse(data)

        success = (response[:responsecode] and response[:complete] and (0..49).include?(response[:responsecode].to_i) )
        message = message_form(response[:message])
      
        Response.new(success, message, @response)
      end
                                               
      # Parse moneris response xml into a convinient hash
      def parse(xml)
        #  "<?xml version=\"1.0\"?><response><receipt>".
        #  "<ReceiptId>Global Error Receipt</ReceiptId>".
        #  "<ReferenceNum>null</ReferenceNum>
        #  <ResponseCode>null</ResponseCode>".
        #  "<ISO>null</ISO> 
        #  <AuthCode>null</AuthCode>
        #  <TransTime>null</TransTime>".
        #  "<TransDate>null</TransDate>
        #  <TransType>null</TransType>
        #  <Complete>false</Complete>".
        #  "<Message>null</Message>
        #  <TransAmount>null</TransAmount>".
        #  "<CardType>null</CardType>".
        #  "<TransID>null</TransID>
        #  <TimedOut>null</TimedOut>".
        #  "</receipt></response>      

        response = {:message => "Global Error Receipt", :complete => false}

        xml = REXML::Document.new(xml)          
        xml.elements.each('//receipt/*') do |node|

          response[node.name.downcase.to_sym] = normalize(node.text)

        end unless xml.root.nil?

        response
      end     

      def post_data(action, parameters = {})
        xml   = REXML::Document.new
        root  = xml.add_element("request")
        root.add_element("store_id").text = options[:login]
        root.add_element("api_token").text = options[:password]
        transaction = root.add_element(action)

        for key, value in parameters
          transaction.add_element(key.to_s).text = value if value
        end    

        xml.to_s
      end
    
      def message_form(message)
        return 'Unspecified error' if message.blank?
        message.gsub(/[^\w]/, ' ').split.join(" ").capitalize
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
    
      ACTIONS = {
           "purchase"        => [:order_id, :cust_id, :amount, :pan, :expdate, :crypt_type],
           "preauth"         => [:order_id, :cust_id, :amount, :pan, :expdate, :crypt_type],
           "command"         => [:order_id],
           "refund"          => [:order_id, :amount, :txn_number, :crypt_type],
           "indrefund"       => [:order_id, :cust_id, :amount, :pan, :expdate, :crypt_type],
           "completion"      => [:order_id, :comp_amount, :txn_number, :crypt_type],
           "purchaseco"      => [:order_id, :txn_number, :crypt_typer],
           "cavvpurcha"      => [:order_id, :cust_id, :amount, :pan, :expdate, :cav],
           "cavvpreaut"      => [:order_id, :cust_id, :amount, :pan, :expdate, :cavv],
           "transact"        => [:order_id, :cust_id, :amount, :pan, :expdate, :crypt_type],
           "Batchcloseall"   => [],
           "opentotals"      => [:ecr_number],
           "batchclose"      => [:ecr_number],
      }    
    end
  end
end