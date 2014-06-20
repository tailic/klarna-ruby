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

    @order_items = []
    @order_items << @client.make_goods(1, 'ABC1', "T-shirt 1", 1.00 * 100, 25, 0, :INC_VAT => true)
    @order_items << @client.make_goods(3, 'ABC2', "T-shirt 2", 7.00 * 100, 25, 0, :INC_VAT => true)
    @order_items << @client.make_goods(7, 'ABC3', "T-shirt 3", 17.00 * 100, 25, 0, :INC_VAT => true)
    @order_items_total = (1 * (1.00 * 100) + 3 * (7.00 * 100) + 7 * (17.00 * 100)).to_i

    @address_SE = @client.make_address("Testperson-se", "Approved","", "Stårgatan 1", "12345", "Ankeborg", :SE, "076 526 00 00", "0765260000", "youremail@email.com")
    @address_DE = @client.make_address("Testperson-de", "Approved", "", "Hellersbergstraße", "41460", "Neuss", :DE, "01522113356", "01522113356", "youremail@email.com", "14")


    @reservation_args_DE = {pno: "07071960", amount: @order_items_total, order_id: '1234567', delivery_address: @address_DE, billing_address: @address_DE, currency: :EUR, country: :DE, language: :DE, goods_list: @order_items, pno_encoding: 6 }

  end

  # Spec: http://integration.klarna.com/en/api/advanced-integration/functions/checkorderstatus
  describe '#check_order_status' do
    it 'should be defined' do
      assert_respond_to @client, :check_order_status
    end
  end

  # Spec: http://integration.klarna.com/en/api/advanced-integration/functions/activate
  describe '#activate' do
    it 'should be defined' do
      assert_respond_to @client, :activate
    end
  end

  # Spec: http://integration.klarna.com/en/api/advanced-integration/functions/reserveamount
  describe '#reserve_amount' do
    it 'should be defined' do
      assert_respond_to @client, :reserve_amount
    end


    describe "DE" do
      it 'should create reservation successfully with valid arguments' do
        reservation_no, invoice_status = @client.reserve_amount(@reservation_args_DE)
        assert_match /^\d+$/, reservation_no.to_s
        assert_match /^(1|2)$/, invoice_status.to_s
      end
    end

  end

  # Spec: http://integration.klarna.com/en/api/advanced-integration/functions/activatereservation
  describe '#activate_reservation' do
    it 'should be defined' do
      assert_respond_to @client, :activate_reservation
    end
  end

  # Spec: http://integration.klarna.com/en/api/advanced-integration/functions/cancelreservation
  describe '#cancel_reservation' do
    it 'should be defined' do
      assert_respond_to @client, :cancel_reservation
    end
  end

  describe '#split_reservation' do
    it 'should be defined' do
      assert_respond_to @client, :split_reservation
    end
  end

  # Spec: http://integration.klarna.com/en/api/advanced-integration/functions/changereservation
  describe '#change_reservation' do
    it 'should be defined' do
      assert_respond_to @client, :change_reservation
    end
  end

  # Spec: http://integration.klarna.com/en/api/advanced-integration/functions/reserveocrnums
  describe '#reserve_ocr_numbers' do
    it 'should be defined' do
      assert_respond_to @client, :reserve_ocr_numbers
    end
  end

  # http://integration.klarna.com/en/api/advanced-integration/functions/mkaddress
  describe '#make_reservation_address' do
    it 'should be defined' do
      assert_respond_to @client, :make_reservation_address
    end
  end

end