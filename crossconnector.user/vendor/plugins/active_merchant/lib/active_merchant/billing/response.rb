module ActiveMerchant
  module Billing
  
    class Error < StandardError
    end
  
    class Response
      attr_reader :params
      attr_reader :message
    
      def success?
        @success
      end
        
      def initialize(success, message, params = {})
        @success, @message, @params = success, message, params.stringify_keys
      end
    end
  end
end