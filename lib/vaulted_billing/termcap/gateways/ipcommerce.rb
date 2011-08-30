require 'vaulted_billing/gateways/ipcommerce'

VaultedBilling::Gateways::Ipcommerce.class_eval do
  
  ##
  # Captures the passed in transaction ids.
  # Optionally specify difference amounts for each transaction.
  # ex.
  #   differences = [
  #     { :id => 2, :amount => 12.00 }
  #   ]
  def capture_selective(transaction_ids, differences = [], options = {})
    data = {
      :"__type" => "CaptureSelective:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Rest",
      :ApplicationProfileId => @application_id,
      :TransactionIds => transaction_ids,
      :DifferenceData => (differences || []).collect { |difference| capture_difference(difference) }
    }

    response = http(options[:workflow_id] || @service_id).put(data, { :on_success => :decode_with_termcap })
    transaction = new_transaction_from_response(response)
    respond_with(transaction,
                 response,
                 :success => (transaction.code == 1))
  end
  
  def capture_all(options = {})
    data = {
      :"__type" => "CaptureAll:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Rest",
      :ApplicationProfileId => @application_id,
      :BatchIds => [],
      :MerchantProfileId => options[:merchant_profile_id]
    }
     
    response = http(options[:workflow_id] || @service_id).put(data, { :on_success => :decode_with_termcap })
    transaction = new_transaction_from_response(response)
    respond_with(transaction,
                 response,
                 :success => (transaction.code == 1))
  end
  
  def return_unlinked(customer, credit_card, amount, options = {})
    data = {
      :"__type" => "ReturnTransaction:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Rest",
      :ApplicationProfileId => @application_id,
      :MerchantProfileId => options[:merchant_profile_id],
      :Transaction => {
        :"__type" => "BankcardTransaction:http:\/\/schemas.ipcommerce.com\/CWS\/v2.0\/Transactions\/Bankcard",
        :TransactionData => {
          :Amount => "%.2f" % amount,
          :CurrencyCode => 4,
          :TransactionDateTime => Time.now.xmlschema,
          :CustomerPresent => 0,
          :EmployeeId => options[:employee_id],
          :EntryMode => 1,
          :GoodsType => 0,
          :IndustryType => 2,
          :OrderNumber => options[:order_id] || generate_order_number,
          :SignatureCaptured => false
        },
        :TenderData => card_data(credit_card)
      }
    }
     
    response = http(options[:workflow_id] || @service_id).post(data)
    transaction = new_transaction_from_response(response)
    respond_with(transaction,
                 response,
                 :success => (transaction.code == 1))
  end

  private

  def decode_with_termcap(response)
    response.body = decode_body(response.body) || {}
    response.body = (response.body.first || {}) if response.body.is_a?(Array)
    response.success = [1, 2].include?(response.body['Status'])
  end

  def capture_difference(difference)
    {
      :"__type" => "BankcardCapture:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Bankcard",
      :TransactionId => difference[:id], 
      :Addendum => nil,
      :Amount => "%.2f" % difference[:amount]
    }
  end
end