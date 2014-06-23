# encoding: utf-8
require 'test_helper'

describe Klarna::API::Methods::Reservation do

   # TODO: Mock responses using VCR.

  before do
    valid_credentials!
    @client = Klarna::API::Client.new

    @protocol_version = ::Klarna::API::PROTOCOL_VERSION.to_s
    @user_agent = ::XMLRPC::Client::USER_AGENT.to_s

    expose_protected_methods_in @client.class

    #TODO use fixtures!
    @order_items = []
    @order_items << @client.make_goods(1, 'ABC1', "T-shirt 1", 1.00 * 100, 25, 0, :INC_VAT => true)
    @order_items << @client.make_goods(3, 'ABC2', "T-shirt 2", 7.00 * 100, 25, 0, :INC_VAT => true)
    @order_items << @client.make_goods(7, 'ABC3', "T-shirt 3", 17.00 * 100, 25, 0, :INC_VAT => true)
    @order_items_total = (1 * (1.00 * 100) + 3 * (7.00 * 100) + 7 * (17.00 * 100)).to_i

    @order_items_changed = []
    @order_items_changed << @client.make_goods(2, 'ABC1', "T-shirt 1", 1.00 * 100, 25, 0, :INC_VAT => true)
    @order_items_changed << @client.make_goods(3, 'ABC2', "T-shirt 2", 7.00 * 100, 25, 0, :INC_VAT => true)
    @order_items_changed << @client.make_goods(7, 'ABC3', "T-shirt 3", 17.00 * 100, 25, 0, :INC_VAT => true)
    @order_items_total_changed = (2 * (1.00 * 100) + 3 * (7.00 * 100) + 7 * (17.00 * 100)).to_i

    base_address_se = {:fname => 'Testperson-se', :lname => 'Approved', :street => 'Stårgatan 12', :postno => '12345', :city => 'Ankeborg', :country => :SE, :telno => '076 526 00 00', :cellno => '076 526 00 00', :email => 'always_approved@klarna.com'}
    base_address_de = {:fname => 'Testperson-de', :lname => 'Approved', :street => 'Hellersbergstraße', :postno => '41460', :city => 'Neuss', :country => :DE, :telno => '015 22 11 33 56', :cellno => '01522113356', :email => 'always_approved@klarna.com', :house_number => '14'}

    denied_address = {:lname => 'Denied'}
    pending_order = {:email => 'pending_accepted@klarna.com'}
    denied_order = {:email => 'pending_denied@klarna.com'}
    
    @address_approved_SE = @client.make_reservation_address(base_address_se)
    @address_denied_SE = @client.make_reservation_address(base_address_se.merge denied_address)
    @address_order_pending_SE = @client.make_reservation_address(base_address_se.merge pending_order)
    @address_order_denied_SE = @client.make_reservation_address(base_address_se.merge denied_order)

    @address_approved_DE = @client.make_reservation_address(base_address_de)
    @address_denied_DE   = @client.make_reservation_address(base_address_de.merge denied_address)
    @address_order_pending_DE   = @client.make_reservation_address(base_address_de.merge pending_order)
    @address_order_denied_DE   = @client.make_reservation_address(base_address_de.merge denied_order)

    @approved_reservation_DE = {pno: '07071960', amount: @order_items_total, order_id: '1234567', delivery_address: @address_approved_DE, billing_address: @address_approved_DE, currency: :EUR, country: :DE, language: :DE, goods_list: @order_items, pno_encoding: 6 }
    @pending_reservation_DE = {pno: '07071960', amount: @order_items_total, order_id: '1234567', delivery_address: @address_order_pending_DE, billing_address: @address_order_pending_DE, currency: :EUR, country: :DE, language: :DE, goods_list: @order_items, pno_encoding: 6 }
    @denied_reservation_DE = {pno: '07071960', amount: @order_items_total, order_id: '1234567', delivery_address: @address_order_denied_DE, billing_address: @address_order_denied_DE, currency: :EUR, country: :DE, language: :DE, goods_list: @order_items, pno_encoding: 6 }

  end

  # Spec: http://integration.klarna.com/en/api/advanced-integration/functions/checkorderstatus
  describe '#check_order_status' do
    it 'should be defined' do
      assert_respond_to @client, :check_order_status
    end

    it 'should return status ok for an accepted order' do
      reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
      status = @client.check_order_status id: reservation_no, type: 0
      assert_equal Klarna::API::ORDER_STATUS[:ACCEPTED] , status
    end

    it 'should return status pending for a pending order' do
      reservation_no, invoice_status = @client.reserve_amount(@pending_reservation_DE)
      status = @client.check_order_status id: reservation_no, type: 0
      assert_equal Klarna::API::ORDER_STATUS[:PENDING] , status
    end

    it 'should return status pending for a denied order' do
      reservation_no, invoice_status = @client.reserve_amount(@denied_reservation_DE)
      status = @client.check_order_status id: reservation_no, type: 0
      #TODO When (or) will this status change to denied!?
      assert_equal Klarna::API::ORDER_STATUS[:PENDING] , status
    end

  end

  # Spec: http://integration.klarna.com/en/api/advanced-integration/functions/activate
  describe '#activate' do
    it 'should be defined' do
      assert_respond_to @client, :activate
    end

    it 'should return risk status and invoice number for an accepted reservation' do
      reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
      risk, invoice_no = @client.activate reservation_no: reservation_no
      assert_match /^(ok|no_risk)$/ ,risk
      assert_match /^\d+$/, invoice_no
    end

    it 'should raise error for when trying to activate an invalid reservation' do
      assert_raises ::Klarna::API::Errors::KlarnaServiceError do
        @client.activate reservation_no: '123456'
      end
    end

  end

  # Spec: http://integration.klarna.com/en/api/advanced-integration/functions/reserveamount
  describe '#reserve_amount' do
    it 'should be defined' do
      assert_respond_to @client, :reserve_amount
    end


    describe "DE" do
      it 'should create an approved reservation successfully with valid arguments' do
        reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
        assert_match /^\d+$/, reservation_no.to_s
        assert_match '1', invoice_status.to_s
      end

      it 'should create a pending reservation successfully with valid arguments' do
        reservation_no, invoice_status = @client.reserve_amount(@pending_reservation_DE)
        assert_match /^\d+$/, reservation_no.to_s
        assert_match '2', invoice_status.to_s
      end

      it 'should create a pending reservation successfully with valid arguments' do
        reservation_no, invoice_status = @client.reserve_amount(@denied_reservation_DE)
        assert_match /^\d+$/, reservation_no.to_s
        assert_match '2', invoice_status.to_s
      end
    end

  end

  # Spec: http://integration.klarna.com/en/api/advanced-integration/functions/activatereservation
  # describe '#activate_reservation' do
  #   it 'should be defined' do
  #     assert_respond_to @client, :activate_reservation
  #   end
  # end

  # Spec: http://integration.klarna.com/en/api/advanced-integration/functions/cancelreservation
  describe '#cancel_reservation' do
    it 'should be defined' do
      assert_respond_to @client, :cancel_reservation
    end

    it 'should return ok for a valid reservation number' do
      reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
      status = @client.cancel_reservation reservation_no
      assert_equal 'ok' , status
    end

    it 'should raise error for when trying cancel an invalid reservation' do
      assert_raises ::Klarna::API::Errors::KlarnaServiceError do
        @client.cancel_reservation '123456'
      end
    end
  end

  describe '#split_reservation' do
    it 'should be defined' do
      assert_respond_to @client, :split_reservation
    end

    it 'should return ok for a valid reservation number' do
      reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
      status = @client.split_reservation({ reservation_id: reservation_no, split_amount: @order_items.first[:goods][:price] })
      assert_match /^\d+$/, status.first
      assert_equal 1, status.last
    end

    it 'should raise error for when trying split from an invalid reservation' do
      assert_raises ::Klarna::API::Errors::KlarnaServiceError do
        @client.split_reservation({ reservation_id: '123456', split_amount: @order_items.first[:goods][:price] })
      end
    end

    it 'should raise error for when trying split an amount higher than the invoice amount' do
      reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
      assert_raises ::Klarna::API::Errors::KlarnaServiceError do
        @client.split_reservation({ reservation_id: reservation_no, split_amount: @order_items_total + 1 })
      end
    end
  end

  describe '#update' do
    it 'should be defined' do
      assert_respond_to @client, :update
    end

    it 'should update a reservation with valid goods_list arguments' do
      reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
      status = @client.update reservation_no, { :goods_list => @order_items_changed }
      assert_equal 'ok' , status
    end

    it 'should update a reservation with valid delivery address arguments' do
      reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
      status = @client.update reservation_no, { :dlv => @address_order_pending_DE }
      assert_equal 'ok' , status
    end

    it 'should update a reservation with valid order id' do
      reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
      status = @client.update reservation_no, { :orderid1 => '123ABC' }
      assert_equal 'ok' , status
    end

    it 'should raise error for when trying to update a reservation with different addresses for delivery and billing' do
      assert_raises ::Klarna::API::Errors::KlarnaServiceError do
        reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
        status = @client.update reservation_no, { :dlv_addr => @address_approved_SE, :bill_addr => @address_approved_DE }
      end
    end

    it 'should raise error for when trying to update with an invalid reservation number' do
      assert_raises ::Klarna::API::Errors::KlarnaServiceError do
        reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
        status = @client.update '098765432', { :goods_list => @order_items_changed }
      end
    end

    it 'should raise error for when trying to update with no update information given' do
      assert_raises ::Klarna::API::Errors::KlarnaServiceError do
        reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
        status = @client.update '098765432', { }
      end
    end
  end

  # Spec: http://integration.klarna.com/en/api/advanced-integration/functions/changereservation
  # describe '#change_reservation' do
  #   it 'should be defined' do
  #     assert_respond_to @client, :change_reservation
  #   end
  # end

  # Spec: http://integration.klarna.com/en/api/advanced-integration/functions/reserveocrnums
  # describe '#reserve_ocr_numbers' do
  #   it 'should be defined' do
  #     assert_respond_to @client, :reserve_ocr_numbers
  #   end
  # end

  # http://integration.klarna.com/en/api/advanced-integration/functions/mkaddress
  describe '#make_reservation_address' do
    it 'should be defined' do
      assert_respond_to @client, :make_reservation_address
    end
  end

end