require 'net/http'
require 'net/https'
require 'active_merchant/billing/response'

module ActiveMerchant
  module Billing
    class Base
      include PostsData
      include RequiresParameters
                                                                 
      # Set ActiveMerchant in test mode.
      # Default it production
      #
      #   ActiveMerchant::Base.gateway_mode = :test
      cattr_accessor :gateway_mode
      @@gateway_mode = :test
                                                                
      # Return the matching gateway for the provider
      # * <tt>bogus</tt>: BogusGateway - Does nothing ( for testing)
      # * <tt>moneris</tt>: MonerisGateway
      # * <tt>authorized_net</tt>: AuthorizedNetGateway
      # * <tt>trust_commerce</tt>: TrustCommerceGateway
      # 
      #   ActiveMerchant::Base.gateway('moneris').new
      def self.gateway(name)
        ActiveMerchant::Billing.const_get("#{name.to_s.downcase}_gateway".camelize)
      end                        
             
      # Does this gateway support credit cards of the passed type?
      def self.supports?(type)
        supported_cardtypes.include?(type.intern)
      end
                                                                  
      # Get a list of supported credit card types for this gateway
      def self.supported_cardtypes
        []
      end                                 
    
      # Initialize a new gateway 
      # 
      # See the documentation for the gateway you will be using to make sure there
      # are no other required options
      def initialize(options = {})    
        @ssl_strict = options[:ssl_strict] || false
      end
                                     
      # Are we running in test mode?
      def test?
        Base.gateway_mode == :test
      end
      
      def authorize(money, creditcard, options = {})
        raise NotImplementedError, 'Credit authorization is not implemented by ' + name
      end

      def purchase(money, creditcard, options = {})
        raise NotImplementedError, 'Credit purchase is not implemented by ' + name
      end

      def capture(money, identification, options = {})
        raise NotImplementedError, 'Credit capture is not implemented by ' + name
      end
      
      def credit(money, identification, options = {})  
        raise NotImplementedError, 'Credit crediting is not implemented by ' + name
      end

      def recurring(money, identification, options = {})  
        raise NotImplementedError, 'Recurring Crediting is not implemented by ' + name
      end

      def store(money, identification, options = {})  
        raise NotImplementedError, 'CC Store is not implemented by ' + name
      end

      def unstore(money, identification, options = {})  
        raise NotImplementedError, 'CC Forget is not implemented by ' + name
      end
            
      protected
              
      def name
        self.class.name.scan(/\:\:(\w+)Gateway/).flatten.first
      end
      
      def test_result_from_cc_number(number)
        return false unless test?
        
        case number.to_s
        when '1', 'success' 
          Response.new(true, 'Successful test mode response', :receiptid => '#0001')
        when '2', 'failure' 
          Response.new(false, 'Failed test mode response', :receiptid => '#0001')
        when '3', 'error' 
          raise Error, 'big bad exception'
        else 
          false
        end
      end
    end
  end
end