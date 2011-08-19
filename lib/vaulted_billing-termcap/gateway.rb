VaultedBilling::Gateway.module_eval do
  def capture_selective(transactions, differences = {}, options = {})
    raise NotImplementedError
  end
end
