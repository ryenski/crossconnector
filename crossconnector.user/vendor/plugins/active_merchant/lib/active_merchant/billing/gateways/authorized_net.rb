module ActiveMerchant
  module Billing
        
    class AuthorizedNetGateway < Base
      API_VERSION = '3.1'
      GATEWAY_URL = "https://secure.authorize.net/gateway/transact.dll"

      APPROVED, DECLINED, ERROR = 1, 2, 3

      RESPONSE_CODE, RESPONSE_REASON_CODE, RESPONSE_REASON_TEXT = 0, 2, 3
      AVS_RESULT_CODE, TRANSACTION_ID, CARD_CODE_RESPONSE_CODE  = 5, 6, 38

      CARD_CODE_ERRORS = %w( N S )

      CARD_CODE_MESSAGES = {
        "M" => "Card verification number matched",
        "N" => "Card verification number didn't match",
        "P" => "Card verification number was not processed",
        "S" => "Card verification number should be on card but was not indicated",
        "U" => "Issuer was not certified for card verification"
      }

      AVS_ERRORS = %w( A E N R W Z )

      AVS_MESSAGES = {
        "A" => "Street address matches billing information, zip/postal code does not",
        "B" => "Address information not provided for address verification check",
        "E" => "Address verification service error",
        "G" => "Non-U.S. card-issuing bank",
        "N" => "Neither street address nor zip/postal match billing information",
        "P" => "Address verification not applicable for this transaction",
        "R" => "Payment gateway was unavailable or timed out",
        "S" => "Address verification service not supported by issuer",
        "U" => "Address information is unavailable",
        "W" => "9-digit zip/postal code matches billing information, street address does not",
        "X" => "Street address and 9-digit zip/postal code matches billing information",
        "Y" => "Street address and 5-digit zip/postal code matches billing information",
        "Z" => "5-digit zip/postal code matches billing information, street address does not",
      }
     
      # URL
      attr_reader :url 
      attr_reader :response
      attr_reader :options

      def initialize(options = {})
        requires!(options, :login, :password)
        
        # these are the defaults for the authorized test server
        @options = {
          :login      => "Y",
          :password   => "X",          
        }.update(options)
                                           
        super      
      end      
      
      def authorize(money, creditcard, options = {})
        add_creditcard(options, creditcard)        
        commit('AUTH_ONLY', money, options)
      end
      
      def purchase(money, creditcard, options = {})
        add_creditcard(options, creditcard)        
        commit('AUTH_CAPTURE', money, options)
      end                       
    
      def capture(money, identification, options = {})
        commit('PRIOR_AUTH_CAPTURE', money, options.merge(:order_number => identification))
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
  
      def commit(action, money, parameters)
        parameters[:amount]       = amount(money)
        parameters[:test_request] = test? ? 'TRUE' : 'FALSE'                                                      
        
        if result = test_result_from_cc_number(parameters[:card_num])
          return result
        end
                   
        data = ssl_post GATEWAY_URL, post_data(action, parameters)
      
        @response = parse(data)
        success = @response[:response_code] == APPROVED
        message = message_from(@response)

        Response.new(success, message, @response)
      end
                                               
      def parse(body)
        fields = body[1..-2].split(/\$,\$/)
               
        results = {         
          :response_code => fields[RESPONSE_CODE].to_i,
          :response_reason_code => fields[RESPONSE_REASON_CODE], 
          :response_reason_text => fields[RESPONSE_REASON_TEXT],
          :avs_result_code => fields[AVS_RESULT_CODE],
          :transaction_id => fields[TRANSACTION_ID],
          :card_code => fields[CARD_CODE_RESPONSE_CODE]
        }        
      end     

      def post_data(action, parameters = {})
        post = {}

        post[:version]    = API_VERSION
        post[:login]      = @options[:login]
        post[:password]   = @options[:password]
        post[:type]       = action
        post[:delim_data] = "TRUE"
        post[:encap_char] = "$"

        post.merge(parameters).collect { |key, value| "x_#{key}=#{CGI.escape(value)}" }.join("&")
      end
      
      def add_creditcard(post, creditcard)
        post[:card_num]  = creditcard.number
        post[:card_code] = creditcard.verification_number if creditcard.verification_number?
        post[:address]   = creditcard.street if creditcard.street?
        post[:zip]       = creditcard.zip_code if creditcard.zip_code?
        post[:country]   = creditcard.country if creditcard.country?        
        post[:exp_date]  = expdate(creditcard)
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
      
      def message_from(results)        
        if results[:response_code] == DECLINED
        
          if CARD_CODE_ERRORS.include?(results[:card_code])
            return CARD_CODE_MESSAGES[results[:response_code]]
          elsif AVS_ERRORS.include?(results[:avs_result_code])
            return AVS_MESSAGES[results[:avs_result_code]]
          end
          
        else
          return results[:response_reason_text][0..-2] # Forget the punctuation at the end
        end
      end
        
      def expdate(creditcard)
        year  = sprintf("%.4i", creditcard.year)
        month = sprintf("%.2i", creditcard.month)

        "#{month}#{year[-2..-1]}"
      end
    end
  end
end