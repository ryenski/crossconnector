module ActiveMerchant
  module Billing
  
    # This credit card object can be used as a stand alone object. It acts just like a active record object
    # but doesn't support the .save method as its not backed by a database.
    class CreditCard
      include Validateable

      # required
      attr_accessor :number, :month, :year, :type
      

      def before_validate
        self.type.downcase! if type.respond_to?(:downcase)
        self.month = month.to_i
        self.year = year.to_i
        self.number.to_s.gsub!(/[^\d]/, "")
      end

      def validate        
        @errors.add "month", "cannot be empty"                    unless (1..12).include?(month.to_i)
        @errors.add "year", "cannot be empty"                     unless (Time.now.year..Time.now.year+10).include?(year.to_i)
        if type != 'bogus'
          @errors.add "card_type", "is invalid."                         unless CreditCard.card_companies.keys.include?(type)
          @errors.add "card_type", "doesn't match the card number"        unless CreditCard.type?(number) == type
          @errors.add "card_number", "is not a vaild credit card number" unless CreditCard.valid_number?(number)                     
        end
      end  

      # optional 
      attr_accessor :name, :company, :address1, :address2, :city, :state, :zip, :country, :phone, :fax, :email, :addrnum
      attr_accessor :cvmvalue, :cvmindicator, :track
      
      
      def name?
        @name != nil
      end
      
      def zip_code?
        @zip_code != nil
      end
      
      def state?
        @state != nil
      end
      
      def country?
        @country != nil
      end
      
      def city?
        @city != nil
      end
           
      def street?
        @street != nil
      end  

      def verification_number?
        @verification_number != nil
      end      
      
      def last_four
        len = self.number.length
        self.number[(len - 4), len]
      end
      
      def mask
        case self.type.downcase
        when 'amex'
          "XXXX-XXXXXX-X#{self.last_four}"
        else
          "XXXX-XXXX-XXXX-#{self.last_four}"
        end
      end
      
      
      # Get the regexps for different card companies 
      # == Known card types
      #	*Card Type*                       *Prefix*                         *Length*
      #	mastercard                        51-55                            16
      #	visa                              4                                13, 16
      #	american_express                  34, 37                           15
      #	diners_club                       300-305, 36, 38                  14
      #	enroute                           2014, 2149                       15
      #	discover                          6011                             16
      #	jcb                               3                                16
      #	jcb                               2131, 1800                       15
      #	bankcard                          5610, 56022[1-5]                 16
      #	switch                            various                          16,18,19
      #	solo                              63, 6767                         16,18,19
      def self.card_companies
        { 
          'visa' =>  /^4\d{12}(\d{3})?$/,
          'master' =>  /^5[1-5]\d{14}$/,
          'discover' =>  /^6011\d{12}$/,
          'american_express' =>  /^3[47]\d{13}$/,
          'diners_club' =>  /^3(0[0-5]|[68]\d)\d{11}$/,
          'enroute' =>  /^2(014|149)\d{11}$/,
          'jcb' =>  /^(3\d{4}|2131|1800)\d{11}$/,
          'bankcard' =>  /^56(10\d\d|022[1-5])\d{10}$/,
          'switch' =>  [/^49(03(0[2-9]|3[5-9])|11(0[1-2]|7[4-9]|8[1-2])|36[0-9]{2})\d{10}(\d{2,3})?$/, /^564182\d{10}(\d{2,3})?$/, /^6(3(33[0-4][0-9])|759[0-9]{2})\d{10}(\d{2,3})?$/],
          'solo' =>  /^6(3(34[5-9][0-9])|767[0-9]{2})\d{10}(\d{2,3})?$/ 
        }
      end

      # Returns a string containing the type of card from the list of known information below.
      def self.type?(number)
        return 'visa' if Base.gateway_mode == :test and ['1','2','3','success','failure','error'].include?(number.to_s)
        
        card_companies.each do |company, patterns|
          return company if [patterns].flatten.any? { |pattern| number =~ pattern  } 
        end     
      end

      # Returns true if it validates. Optionally, you can pass a card type as an argument and make sure it is of the correct type.
      # == References
      # - http://perl.about.com/compute/perl/library/nosearch/P073000.htm
      # - http://www.beachnet.com/~hstiles/cardtype.html
      def self.valid_number?(number)
        return true if Base.gateway_mode == :test and ['1','2','3','success','failure','error'].include?(number.to_s)
        
      	return false unless number.to_s.length >= 13

      	sum = 0
      	for i in 0..number.length
      		weight = number[-1*(i+2), 1].to_i * (2 - (i%2))
      		sum += (weight < 10) ? weight : weight - 9
      	end

      	(number[-1,1].to_i == (10 - sum%10)%10)  	
      end

    end
  end
end