class MigrateBetaUsers < ActiveRecord::Migration
  def self.up

    announce "Migrating Beta users"
    
    betas =  SubscriptionPlan.find_by_name("Beta").subscriptions
    betas += SubscriptionPlan.find_by_name("ChurchBeta").subscriptions
    
    Subscription.transaction(betas) do
      begin
        new_plan = SubscriptionPlan.find_by_name("Unlimited")
        for beta in betas do
          if beta.homebase.nil?
            say "Subscription_id #{beta.id} has no homebase."
          else
            say "Migrating subscription_id #{beta.id}..."
            extend_trial = beta.plan.name == "ChurchBeta" ? 6.months : 3.months
            beta.plan = new_plan
            beta.trial_ends_at = Time.now + extend_trial
            beta.price = new_plan.price
            beta.periodicity = "monthly"
            beta.save
            write "success."
          end
        end
      rescue Exception => e
        announce "Failed. Rolling Back. "
      end
    end
    
  end

  def self.down
    # not really any way to undo this...
    #raise IrreversibleMigration
  end
end
