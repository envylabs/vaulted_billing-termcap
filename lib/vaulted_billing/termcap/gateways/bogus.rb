require 'vaulted_billing/gateways/bogus'

VaultedBilling::Gateways::Bogus.class_eval do
  def capture_selective(transaction_ids, differences = [], options = {})
    transaction_response
  end
  
  def capture_all(options = {})
    transaction_response
  end
  
  def return_unlinked(customer, credit_card, amount, options = {})
    transaction_response
  end
end
  