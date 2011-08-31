module VaultedBilling
  module Transactions
    class Ipcommerce < VaultedBilling::Transaction
      CaptureStates = %w(
        !! NotSet CannotCapture ReadyForCapture CapturePending Captured
        CaptureDeclined InProcess CapturedUndoPermitted CapturePendingUndoPermitted CaptureError
        CaptureUnknown BatchSent BatchSentUndoPermitted
      ).freeze

      TransactionStates = %w(
        !! NotSet Declined Verified Authorized Adjusted
        Captured CaptureDeclined PartiallyCaptured Undone ReturnRequested
        PartialReturnRequested ReturnUndone Returned PartiallyReturned InProcess
        ErrorValidation ErrorUnknown ErrorConnecting
      ).freeze

      attr_accessor :raw_result
      attr_accessor :id
      attr_accessor :amount
      attr_accessor :approval_code
      attr_accessor :captured_amount
      attr_accessor :captured_state
      attr_accessor :captured_state_id
      attr_accessor :captured_status_message
      attr_accessor :transaction_state_id
      attr_accessor :transaction_state   
      attr_accessor :batch_id     

      def captured?
        %w(Captured).include?(captured_state)
      end

      def capture_failed?
        %w(CaptureDeclined CaptureError).include?(captured_state)
      end

      def capture_pending?
        %w(BatchSent InProcess).include?(captured_state)
      end

      def failed?
        %w(Declined CaptureDeclined ErrorValidation ErrorUnknown).include?(transaction_state)
      end    

      def initialize(input)
        self.raw_result = input.to_s
        self.id = input['TransactionInformation']['TransactionId']
        self.amount = input['TransactionInformation']['Amount']
        self.approval_code = input['TransactionInformation']['ApprovalCode']
        self.captured_amount = input['TransactionInformation']['CapturedAmount']
        self.captured_state = CaptureStates[input['TransactionInformation']['CaptureState']]
        self.captured_state_id = input['TransactionInformation']['CaptureState']
        self.captured_status_message = input['TransactionInformation']['CaptureStatusMessage']          
        self.transaction_state_id = input['TransactionInformation']['TransactionState']
        self.transaction_state =TransactionStates[input['TransactionInformation']['TransactionState']]
        self.batch_id = input['TransactionInformation']['BatchId']
      end
    end
  end
end