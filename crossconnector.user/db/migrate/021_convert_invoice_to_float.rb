class ConvertInvoiceToFloat < ActiveRecord::Migration
  def self.up
    STDERR.puts "Migrating to version 21"
    
    STDERR.print "Changing prices to Money values in...  "
    
    STDERR.print "invoice, "
    execute "UPDATE invoices set total = total * 100;"

    STDERR.print "subscription_plans, "    
    execute "UPDATE subscription_plans set price = price * 100;"
    
    STDERR.print "subscriptions. "
    execute "UPDATE subscriptions set price = price * 100;"
    
    # One more thing...
    add_column :invoices, :billing_date, :datetime
    
    STDERR.puts "done."
  end

  def self.down
    STDERR.puts "Migrating down from version 21"
    remove_column :invoices, :billing_date
    
    
    STDERR.print "Changing Money back to integer in... "
    
    STDERR.print "invoice... "
    execute "UPDATE invoices set total = total / 100;"
    
    
    STDERR.print "subscription_plans... "    
    execute "UPDATE subscription_plans set price = price / 100;"
    
    STDERR.print "subscriptions.... "
    execute "UPDATE subscriptions set price = price / 100;"
    
    STDERR.puts "done."
  end
end
