require 'vaulted_billing/gateway'

VaultedBilling::Gateway.module_eval do
  def capture_selective(transactions, differences = [], options = {})
    raise NotImplementedError
  end
end