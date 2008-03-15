require 'digest/sha1'
require 'openssl'
require 'cgi'

module ActiveRecord
  module PasswordSystem
    
    #def self.append_features(base)
    #  super
    #  base.extend(ClassMethods)  
    #end
    
    def self.included(base)
      base.class_eval do
        alias_method :create_without_password, :create
        alias_method :create, :create_with_password
        
        alias_method :update_without_password, :update
        alias_method :update, :update_with_password
      end
    end
    
    
    def create_with_password
      generate_password
      create_without_password
    end
    
    def update_with_password
      generate_password
      update_without_password
    end
    
    def generate_password
      if self.respond_to?(:salted_password) and self.respond_to?(:salt) and self.respond_to?(:password)
        unless self.password.blank?
          self[:salt] = ActiveRecord::PasswordSystem.hashed("salt-#{Time.now}") if self.respond_to?(:salt)
          self[:salted_password] = ActiveRecord::PasswordSystem.encrypt(self.password, self.salt) if self.respond_to?(:salted_password)
        end 
      end
    end
    
    
    
    CIPHERTYPE = "aes-192-ecb"  
    GLOBAL_SALT = 'e0429c0df7151bddb0aad81ff80cd2dc4ac3ad13'
    
    # Apply SHA1 encryption to the supplied password. 
    def self.hashed(str)
      Digest::SHA1.hexdigest("#{GLOBAL_SALT}--#{str}--")
    end
    
    def self.encrypt(str, key)
      cipher = OpenSSL::Cipher::Cipher.new(CIPHERTYPE)
      cipher.encrypt
      cipher.key = key
      cipher.iv = GLOBAL_SALT
      cipher.update(str)
      CGI.escape(cipher.final.to_s)
    end
    
    def self.decrypt(str, key)
      cipher = OpenSSL::Cipher::Cipher.new(CIPHERTYPE)
      cipher.decrypt
      cipher.key = key
      cipher.iv = GLOBAL_SALT
      cipher.update(CGI.unescape(str))
      cipher.final.to_s
    end
  
  end
end