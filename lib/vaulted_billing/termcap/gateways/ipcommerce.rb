require 'vaulted_billing/gateways/ipcommerce'
require 'vaulted_billing/termcap/transactions/ipcommerce'

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

    response = http("Txn", options[:workflow_id] || @service_id).put(data, { :on_success => :decode_with_termcap })
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
     
    response = http("Txn", options[:workflow_id] || @service_id).put(data, { :on_success => :decode_with_termcap })
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
     
    response = http("Txn", options[:workflow_id] || @service_id).post(data)
    transaction = new_transaction_from_response(response)
    respond_with(transaction,
                 response,
                 :success => (transaction.code == 1))
  end

  def query_transaction_details(options={})
    data = {
      :"__type" => "QueryTransactionsDetail:http://schemas.ipcommerce.com/CWS/v2.0/DataServices/TMS/Rest",
			:PagingParameters => paging_parameters(options[:page], options[:per_page]),
			:IncludeRelated => options[:include_related] || 1,
			:QueryTransactionsParameters => {
				:"__type" => "QueryTransactionsParameters:http://schemas.ipcommerce.com/CWS/v2.0/DataServices/TMS",
				:IsAcknowledged => options[:is_acknowledged] || 0,
				:QueryType => options[:query_type] || 0,
				:TransactionIds => options[:transaction_ids] || nil
			}.merge(date_range("TransactionDateRange", options[:start_date], options[:end_date])),
			:TransactionDetailFormat => 2
    }
    
    if options[:end_date] && options[:start_date]
      data[:QueryTransactionsParameters].merge!(date_range(ptions[:start_date], options[:end_date]))
	  end

    response = http("DataServices", "TMS", "transactionsDetail").post(data, { :on_success => :decode_query_response } )
    transactions = decode_query(response.body)
    respond_with(transactions,
                 response,
                 :success => response.success?)
  end

  def query_transactions_families(options={})
    data = {
      :"__type" => "QueryTransactionsFamilies:http://schemas.ipcommerce.com/CWS/v2.0/DataServices/TMS/Rest",
			:PagingParameters => paging_parameters(options[:page], options[:per_page]),
			:QueryTransactionsParameters => {
				:"__type" => "QueryTransactionsParameters:http://schemas.ipcommerce.com/CWS/v2.0/DataServices/TMS",
				:IsAcknowledged => options[:is_acknowledged] || 0,
				:QueryType => options[:query_type] || 0,
				:TransactionIds => options[:transaction_ids] || nil
			}.merge(date_range("TransactionDateRange", options[:start_date], options[:end_date]))
    }
  
    response = http("DataServices", "TMS", "transactionsFamily").post(data, { :on_success => :decode_query_response } )
    transactions = response.body
    respond_with(transactions,
                 response,
                 :success => response.success?)
  end

  def query_batch(options={})
    data = {
      :"__type" => "QueryBatch:http://schemas.ipcommerce.com/CWS/v2.0/DataServices/TMS/Rest",
			:PagingParameters => paging_parameters(options[:page], options[:per_page]),
			:QueryBatchParameters => {
				:"__type" => "QueryBatchParameters:http://schemas.ipcommerce.com/CWS/v2.0/DataServices/TMS",
				:IsAcknowledged => options[:is_acknowledged] || 0,
				:QueryType => options[:query_type] || 0
			}.merge(date_range("BatchDateRange", options[:start_date], options[:end_date]))
    }

    response = http("DataServices", "TMS", "batch").post(data, { :on_success => :decode_query_response } )
    transactions = response.body
    respond_with(transactions,
                 response,
                 :success => response.success?)
  end

  def query_transactions_summary(options={})
    data = {
      :"__type" => "QueryTransactionsSummary:http://schemas.ipcommerce.com/CWS/v2.0/DataServices/TMS/Rest",
			:PagingParameters => paging_parameters(options[:page], options[:per_page]),
			:QueryTransactionsParameters => {
				:"__type" => "QueryTransactionsParameters:http://schemas.ipcommerce.com/CWS/v2.0/DataServices/TMS",
				:IsAcknowledged => options[:is_acknowledged] || 0,
				:QueryType => options[:query_type] || 0,
				:TransactionIds => options[:transaction_ids] || nil
			}.merge(date_range("TransactionDateRange", options[:start_date], options[:end_date]))
    }

    response = http("DataServices", "TMS", "transactionsSummary").post(data, { :on_success => :decode_query_response } )
    transactions = response.body
    respond_with(transactions,
                 response,
                 :success => response.success?)
  end

  private

  def decode_with_termcap(response)
    response.body = decode_body(response.body) || {}
    response.body = (response.body.first || {}) if response.body.is_a?(Array)
    response.success = [1, 2].include?(response.body['Status'])
  end

  def decode_query_response(response)
    response.body = decode_body(response.body) || {}
    response.success = response.body.is_a?(Array)
  end

  def decode_query(transactions)
    transactions.collect do |transaction|
      VaultedBilling::Transactions::Ipcommerce.new(transaction)
    end
  end

  def capture_difference(difference)
    {
      :"__type" => "BankcardCapture:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Bankcard",
      :TransactionId => difference[:id], 
      :Addendum => nil,
      :Amount => "%.2f" % difference[:amount]
    }
  end
  
  def date_range(key, start_date, end_date)
    return {} unless start_date && end_date
    { 
      "#{key}" => {
			  :EndDateTime => "Date(#{end_date.to_int*1000})",
			  :StartDateTime => "Date(#{start_date.to_int*1000})"
		  }
	  }
  end
  
  def paging_parameters(page, per_page)
    {
			:"__type" => "PagingParameters:http://schemas.ipcommerce.com/CWS/v2.0/DataServices",
			:Page => page || 0,
			:PageSize => per_page || 50
		}
  end
end