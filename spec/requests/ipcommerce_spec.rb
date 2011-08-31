require 'spec_helper'

describe VaultedBilling::Gateways::Ipcommerce do
  let(:gateway) { VaultedBilling.gateway(:ipcommerce).new }
  let(:merchant_profile_id) { 'AutoTest_B447F00001' }
  let(:options) { { :merchant_profile_id => merchant_profile_id, :workflow_id => 'B447F00001' } }

  it { should be_a VaultedBilling::Gateway }
  
  context '#capture_selective' do
    let(:amount) { 10.00 }
    let(:customer) { Factory.build(:customer) }
    let(:credit_card) { Factory.build(:ipcommerce_credit_card) }
    let(:authorization) { gateway.authorize(customer, credit_card, amount, options) }

    shared_examples_for 'a successful capture_selective' do |count|
      it_should_behave_like 'a transaction request'
      it { should be_success }
      its(:id) { should_not be_nil }
      its(:authcode) { should be_nil }
      its(:message) { should =~ %r{Batch file successfully uploaded.} }
      its(:code) { should == 1 }
      it "finds the correct number of transactions to capture" do
         MultiJson.decode(subject.raw_response).first["TransactionSummaryData"]["NetTotals"]["Count"].should == count
      end
    end

    context 'with a single authorization' do
      subject { gateway.capture_selective([authorization.id], differences, options) }
      
      context 'when successful' do
        context 'with no differences' do
          let(:differences) { nil }
          use_vcr_cassette 'ipcommerce/capture_selective/single/no-differences/success'
          it_should_behave_like 'a successful capture_selective', 1
        end
      
        context 'with differences' do
          let(:differences) { [{ :id => authorization.id, :amount => 12.00 }] }
          use_vcr_cassette 'ipcommerce/capture_selective/single/differences/success'
          it_should_behave_like 'a successful capture_selective', 1
        end
      
        context 'passing in a difference of the same amount' do
          let(:differences) { [{ :id => authorization.id, :amount => amount }] }
          use_vcr_cassette 'ipcommerce/capture_selective/single/same-differences/success'
          it_should_behave_like 'a successful capture_selective', 1
        end
      end
      
      context 'with a failure' do
        subject { gateway.capture_selective([authorization.id], differences, options) }

        context 'with differences' do
          let(:differences) { [{ :id => authorization.id, :amount => amount*-1 }] }
           use_vcr_cassette 'ipcommerce/capture_selective/single/differences/failure'
           it { should be_a VaultedBilling::Transaction }
           it { should_not be_success }
           its(:message) { should =~ /^The value -10\.00 is too small.  The minimum value is 0\./i }
           its(:raw_response) { should_not be_nil }
        end
      end
    end

    context 'with multiple authorizations' do
      subject { gateway.capture_selective([authorization.id, second_authorization.id], differences, options) }
      let(:second_amount) { 15.00 }
      let(:second_authorization) { gateway.authorize(customer, credit_card, second_amount, options) }
      
      context 'when successful' do
        context 'with no differences' do
          let(:differences) { nil }
          use_vcr_cassette 'ipcommerce/capture_selective/multiple/no-differences/success'
          it_should_behave_like 'a successful capture_selective', 2
        end
        
        context 'with multiple differences' do
          let(:differences) { [{ :id => authorization.id, :amount => 12.00 }, { :id => second_authorization.id, :amount => 25.00 }] }
          use_vcr_cassette 'ipcommerce/capture_selective/multiple/differences/success'
          it_should_behave_like 'a successful capture_selective', 2
        end
      
        context 'passing in a difference of the same amount' do
          let(:differences) { [{ :id => authorization.id, :amount => amount }, { :id => second_authorization.id, :amount => second_amount }] }
          use_vcr_cassette 'ipcommerce/capture_selective/multiple/same-differences/success'
          it_should_behave_like 'a successful capture_selective', 2
        end
      end
      
      context 'with a failure' do
        context 'with a bad difference' do
          let(:differences) { [{ :id => authorization.id, :amount => amount*-1 }, { :id => second_authorization.id, :amount => second_amount*-1 }] }
          subject { gateway.capture_selective([authorization.id], differences, options) }
          use_vcr_cassette 'ipcommerce/capture_selective/multiple/differences/failure'
          it { should be_a VaultedBilling::Transaction }
          it { should_not be_success }
          its(:message) { should =~ /^The value -10\.00 is too small.  The minimum value is 0\./i }
        end
      end
    end

    context 'ignores difference data that is not associated with a transaction' do
      use_vcr_cassette 'ipcommerce/capture_selective/ignore_invalid_difference_data'
      subject { gateway.capture_selective([authorization.id], [{ :id => "fail", :amount => 10.00 }], options) }
      it_should_behave_like 'a successful capture_selective', 1
    end
    
    context 'with a bad authorization id' do
      # As long as there is at least one authorization id found to be captured, the request succeeds
      context 'with at least one good authorization id' do
        subject { gateway.capture_selective([authorization.id, "fail"], [], options) }        
        use_vcr_cassette 'ipcommerce/capture_selective/bad_authorization_id/success'
        it_should_behave_like 'a successful capture_selective', 1
      end
      
      # If no transactions are found to be captured, the request fails
      context 'with only bad authorization ids' do
        subject { gateway.capture_selective(["fail"], [], options) }
        use_vcr_cassette 'ipcommerce/capture_selective/bad_authorization_id/fail'
        it { should be_a VaultedBilling::Transaction }
        it { should_not be_success }
        its(:message) { should =~ /^No transactions found to be settled/i }
      end
    end
  end

  context '#capture_all' do
    let(:amount) { 10.00 }
    let(:customer) { Factory.build(:customer) }
    let(:credit_card) { Factory.build(:ipcommerce_credit_card) }
    let(:authorization) { gateway.authorize(customer, credit_card, amount, options) }

    shared_examples_for 'a successful capture_all' do
      it_should_behave_like 'a transaction request'
      it { should be_success }
      its(:id) { should_not be_nil }
      its(:authcode) { should be_nil }
      its(:message) { should =~ %r{Batch file successfully uploaded.} }
      its(:code) { should == 1 }
    end

    context 'with a single authorization' do
      subject { gateway.capture_all(options) }

      context 'when successful' do
        use_vcr_cassette 'ipcommerce/capture_all/success'
        let!(:authorize) { authorization }
        it_should_behave_like 'a successful capture_all'
      end
    end
  end

  context '#return_unlinked' do
    let(:amount) { 10.00 }
    let(:customer) { Factory.build(:customer) }
    let(:credit_card) { Factory.build(:ipcommerce_credit_card) }
     
    context 'with a credit card' do
      subject { gateway.return_unlinked(customer, credit_card, amount, options) }

      context 'when successful' do
        use_vcr_cassette 'ipcommerce/return_unlinked/success'
         
        it_should_behave_like 'a transaction request'
        it { should be_success }
        its(:id) { should_not be_nil }
        its(:authcode) { should == "" }
        its(:message) { should == "Transaction Approved" }
        its(:code) { should == 1 }
      end
    end
  end

  context '#query_transaction_details' do
    let(:customer) { Factory.build(:customer) }
    let(:credit_card) { Factory.build(:ipcommerce_credit_card) }
    let(:authorization) { gateway.authorize(customer, credit_card, 100.00, options) }
    let(:authorization2) { gateway.authorize(customer, credit_card, 30.00, options) }
    let(:capture) { gateway.capture_all(options) }
    
    subject { gateway.query_transaction_details([authorization.id, authorization2.id]) }
    
    context 'with a pending capture' do
      use_vcr_cassette 'ipcommerce/query_transaction_details/success'
      before(:each) { authorization; authorization2; capture; }

      it { should be_success }
      its(:length) { should == 2 }
      
      context 'first result' do
        subject { gateway.query_transaction_details([authorization.id, authorization2.id]).first }
        
        it { should be_kind_of(VaultedBilling::Transaction) }
        it { should be_kind_of(VaultedBilling::Transactions::Ipcommerce) }
        its(:id) { should == authorization.id }
        its(:raw_result) { should be_kind_of(String) }
        its(:amount) { should == 100.00 }
        its(:captured_amount) { should == 100.00 }
        its(:captured_state) { should == "BatchSent" }
        its(:transaction_state) { should == "Verified" }
      end
    end
  end
  
  context '#query_transactions_families' do
    let(:customer) { Factory.build(:customer) }
    let(:credit_card) { Factory.build(:ipcommerce_credit_card) }
    let(:authorization) { gateway.authorize(customer, credit_card, 100.00, options) }
    
    subject { gateway.query_transactions_families() }
    
    context 'with a pending capture' do
      use_vcr_cassette 'ipcommerce/query_transactions_families/success'
      before(:each) { authorization; }

      it { should be_success }
      its(:length) { should == 50 }
    end
  end
  
  context '#query_batch' do
    let(:customer) { Factory.build(:customer) }
    let(:credit_card) { Factory.build(:ipcommerce_credit_card) }
    let(:authorization) { gateway.authorize(customer, credit_card, 100.00, options) }
    
    subject { gateway.query_batch() }
    
    context 'with a pending capture' do
      use_vcr_cassette 'ipcommerce/query_batch/success'
      before(:each) { authorization; }

      it { should be_success }
      its(:length) { should == 50 }
    end
  end
  
  context '#query_transactions_summary' do
    let(:customer) { Factory.build(:customer) }
    let(:credit_card) { Factory.build(:ipcommerce_credit_card) }
    let(:authorization) { gateway.authorize(customer, credit_card, 100.00, options) }
    
    subject { gateway.query_transactions_summary() }
    
    context 'with a pending capture' do
      use_vcr_cassette 'ipcommerce/query_transactions_summary/success'
      before(:each) { authorization; }

      it { should be_success }
      its(:length) { should == 50 }
    end
  end
end
