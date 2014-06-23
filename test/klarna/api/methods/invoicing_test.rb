# encoding: utf-8
 require 'test_helper'

describe Klarna::API::Methods::Invoicing do

  # TODO: Mock responses using VCR.

  INVALID_ORDER_NO = '12312312312312312'

  before do
    #TODO use fixtures!
    valid_credentials!
    @client = Klarna::API::Client.new
    @client.client_ip = '85.230.98.196'

    @protocol_version = ::Klarna::API::PROTOCOL_VERSION.to_s
    @user_agent = ::XMLRPC::Client::USER_AGENT.to_s

    expose_protected_methods_in @client.class

    @order_items = []
    @order_items << @client.make_goods(1, 'ABC1', 'T-shirt 1', 1.00 * 100, 25, 0, :INC_VAT => true)
    @order_items << @client.make_goods(3, 'ABC2', 'T-shirt 2', 7.00 * 100, 25, 0, :INC_VAT => true)
    @order_items << @client.make_goods(7, 'ABC3', 'T-shirt 3', 17.00 * 100, 25, 0, :INC_VAT => true)
    @order_items_total = (1 * (1.00 * 100) + 3 * (7.00 * 100) + 7 * (17.00 * 100)).to_i


    @address_SE = @client.make_address({:fname => 'Testperson-se',
                                        :lname => 'Approved',
                                        :careof => '',
                                        :street => 'Stårgatan 1',
                                        :postno => '12345',
                                        :city => 'Ankeborg',
                                        :country => :SE,
                                        :telno => '076 526 00 00',
                                        :cellno => '076 526 00 00',
                                        :email => 'youremail@email.com'})

    @address_DE = @client.make_address({:fname => 'Testperson-de',
                                        :lname => 'Approved',
                                        :careof => '',
                                        :street => 'Hellersbergstraße',
                                        :postno => '41460',
                                        :city => 'Neuss',
                                        :country => :DE,
                                        :telno => '015 22 11 33 56',
                                        :cellno => '01522113356',
                                        :email => 'youremail@email.com',
                                        :house_number => '14'})

    base_address_se = {:fname => 'Testperson-se', :lname => 'Approved', :street => 'Stårgatan 12', :postno => '12345', :city => 'Ankeborg', :country => :SE, :telno => '076 526 00 00', :cellno => '076 526 00 00', :email => 'youremail@email.com'}
    base_address_de = {:fname => 'Testperson-de', :lname => 'Approved', :street => 'Hellersbergstraße', :postno => '41460', :city => 'Neuss', :country => :DE, :telno => '015 22 11 33 56', :cellno => '01522113356', :email => 'youremail@email.com', :house_number => '14'}

    denied_address = {:lname => 'Denied'}
    pending_order = {:email => 'pending_accepted@client.com'}
    denied_order = {:email => 'pending_denied@client.com'}

    @valid_invoice_args_SE = ['USER-4103219202', 'ORDER-1', @order_items, 0, 0, :NORMAL, '4103219202', 'Testperson-se', 'Approved', @address_SE, @address_SE, '85.230.98.196', :SEK, :SE, :SV, :SE, nil, nil, nil, nil, nil, nil, nil, 2]
    @valid_invoice_args_DE = ['USER-07071960', 'ORDER-1', @order_items, 0, 0, :NORMAL, '07071960', 'Testperson-de', 'Approved', @address_DE, @address_DE, '85.230.98.196', :EUR, :DE, :DE, :DE, nil, nil, nil, nil, nil, nil, nil, 2]

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

  # Spec: http://integration.klarna.com/en/api/standard-integration/functions/addtransaction
  # describe '#add_invoice' do
  #   it 'should be defined' do
  #     assert_respond_to @client, :add_transaction
  #   end
  #
  #   describe "SE" do
  #     it 'should create order successfully with valid arguments' do
  #       invoice_no = @client.add_transaction(
  #         'USER-4103219202', 'ORDER-1', @order_items, 0, 0, ::Klarna::API::SHIPMENT_TYPES[:NORMAL], '4103219202', 'Testperson-se', 'Approved', @address_SE, @address_SE, '85.230.98.196', ::Klarna::API::CURRENCIES[:SEK], ::Klarna::API::COUNTRIES[:SE], ::Klarna::API::LANGUAGES[:SV], ::Klarna::API::PNO_FORMATS[:SE])
  #
  #       assert_match /^\d+$/, invoice_no
  #     end
  #
  #     it 'should accept shortcut arguments for: shipment_type, currency, country, language, pno_encoding' do
  #       invoice_no = @client.add_invoice(
  #         'USER-4103219202', 'ORDER-1', @order_items, 0, 0, :NORMAL, '4103219202', 'Testperson-se', 'Approved', @address_SE, @address_SE, '85.230.98.196', :SEK, :SE, :SV, :SE)
  #
  #       assert_match /^\d+$/, invoice_no
  #     end
  #   end
  #
  #   describe "DE" do
  #     it 'should create order successfully with valid arguments' do
  #       invoice_no = @client.add_transaction(
  #           'USER-07071960', 'ORDER-1', @order_items, 0, 0, ::Klarna::API::SHIPMENT_TYPES[:NORMAL], '07071960', 'Testperson-de', 'Approved', @address_DE, @address_DE, '85.230.98.196', ::Klarna::API::CURRENCIES[:EUR], ::Klarna::API::COUNTRIES[:DE], ::Klarna::API::LANGUAGES[:DE], ::Klarna::API::PNO_FORMATS[:DE])
  #
  #       assert_match /^\d+$/, invoice_no
  #     end
  #
  #     it 'should accept shortcut arguments for: shipment_type, currency, country, language, pno_encoding' do
  #       invoice_no = @client.add_invoice(
  #           'USER-07071960', 'ORDER-1', @order_items, 0, 0, :NORMAL, '07071960', 'Testperson-de', 'Approved', @address_DE, @address_DE, '85.230.98.196', :EUR, :DE, :DE, :DE)
  #
  #       assert_match /^\d+$/, invoice_no
  #     end
  #   end
  # end

  # NOTE: active_invoice don't seem to work with the Klarna 2.0 backend currently, raises "invoice_in_test_mode" (which it didn't before).

  # Spec:
  #   http://integration.klarna.com/en/api/standard-integration/functions/activateinvoice
  #   http://integration.klarna.com/en/api/standard-integration/functions/activatepart (combined)
  # describe '#activate_invoice' do
  #   it 'should be defined' do
  #     assert_respond_to @client, :activate_invoice
  #   end
  #
  #   describe 'full' do
  #     it 'should raise error for when trying to activate an non-existing invoice' do
  #       assert_raises ::Klarna::API::Errors::KlarnaServiceError do
  #         @client.activate_invoice(INVALID_ORDER_NO)
  #       end
  #     end
  #
  #     it 'should successfully activate an existing invoice' # do
  #   #     invoice_no = @client.add_invoice(*@valid_invoice_args_SE)
  #   #
  #   #     assert_equal "#{@client.endpoint_uri}/temp/#{invoice_no}.pdf", @client.activate_invoice(invoice_no)
  #   #   end
  #   end
  #
  #   describe 'partial' do
  #     it 'should raise error for when trying to activate an non-existing invoice' do
  #       assert_raises ::Klarna::API::Errors::KlarnaServiceError do
  #         activate_articles = [@order_items.first]
  #         @client.activate_invoice(INVALID_ORDER_NO, activate_articles)
  #       end
  #     end
  #
  #     # FAILS: Klarna API 2.0 don't support this for test-accounts. :(
  #     it 'should successfully activate an existing partial invoice' # do
  #     #     invoice_no = @client.add_invoice(*@valid_invoice_args_SE)
  #     #     activate_articles = [@order_items.first]
  #     #
  #     #     assert_equal "#{@client.endpoint_uri}/temp/#{invoice_no}.pdf", @client.activate_invoice(invoice_no, activate_articles)
  #     #   end
  #   end
  # end

  # Spec:
  #   http://integration.klarna.com/en/api/standard-integration/functions/deleteinvoice
  # describe '#delete_invoice' do
  #   it 'should be defined' do
  #     assert_respond_to @client, :delete_invoice
  #   end
  #
  #   it 'should raise error when trying to delete an non-existing invoice' do
  #     assert_raises ::Klarna::API::Errors::KlarnaServiceError do
  #       @client.delete_invoice(INVALID_ORDER_NO)
  #     end
  #   end
  #
  #   describe "SE" do
  #     it 'should successfully delete an existing invoice' do
  #       invoice_no = @client.add_invoice(*@valid_invoice_args_SE)
  #       assert_equal 'ok', @client.delete_invoice(invoice_no)
  #     end
  #   end
  #
  #   describe "DE" do
  #     it 'should successfully delete an existing invoice' do
  #       invoice_no = @client.add_invoice(*@valid_invoice_args_DE)
  #       assert_equal 'ok', @client.delete_invoice(invoice_no)
  #     end
  #   end
  # end

  # Spec:
  #   http://integration.klarna.com/en/api/invoice-handling-functions/functions/returnamount
  describe '#return_amount' do
    it 'should be defined' do
      assert_respond_to @client, :return_amount
    end

    it 'should successfully give discount on invoice' do
      vat = 25
      reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
      risk, invoice_no = @client.activate reservation_no: reservation_no
      invoice_no_after = @client.return_amount invoice_no, @order_items.first[:goods][:price], vat
      assert_match /^\d+$/, invoice_no_after
    end

    it 'should raise error for non-existing invoice' do
        assert_raises ::Klarna::API::Errors::KlarnaServiceError do
          amount = 100
          vat = 25
          @client.return_amount(INVALID_ORDER_NO, amount, vat)
        end
    end

    # describe "SE" do
    #   it 'should raise error for existing but un-activated invoice' do
    #     assert_raises ::Klarna::API::Errors::KlarnaServiceError do
    #       reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_SE)
    #       risk, invoice_no = @client.activate reservation_no: reservation_no
    #       amount = 100
    #       vat = 25
    #
    #       assert_equal invoice_no, @client.return_amount(invoice_no, amount, vat)
    #     end
    #   end
    # end
    #
    # describe "DE" do
    #   it 'should raise error for existing but un-activated invoice' do
    #     assert_raises ::Klarna::API::Errors::KlarnaServiceError do
    #       reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
    #       risk, invoice_no = @client.activate reservation_no: reservation_no
    #       amount = 100
    #       vat = 25
    #
    #       assert_equal invoice_no, @client.return_amount(invoice_no, amount, vat)
    #     end
    #   end
    # end

      # FAILS: Klarna API 2.0 don't support this for test-accounts. :(
      it 'should successfully return amount for an activated invoice' # do
      #   invoice_no = @client.add_invoice(*@valid_invoice_args_SE)
      #   amount = 100
      #   vat = 25
      #
      #   assert_equal invoice_no, @client.credit_invoice(invoice_no, credit_no)
      # end
  end

  # Spec:
  #   http://integration.klarna.com/en/api/invoice-handling-functions/functions/returnamount
  describe '#credit_invoice' do
    it 'should be defined' do
      assert_respond_to @client, :credit_invoice
    end

    describe 'full' do
      it 'should raise error for non-existing invoice' do
        assert_raises ::Klarna::API::Errors::KlarnaServiceError do
          credit_no = ''
          @client.credit_invoice(INVALID_ORDER_NO, credit_no)
        end
      end

      it 'should successfully credit a complete invoice'  do
        reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
        risk, invoice_no = @client.activate reservation_no: reservation_no
        credit_no = ''
        invoice_no_after = @client.credit_invoice invoice_no, credit_no
        assert_equal invoice_no, invoice_no_after
      end

      # describe "SE" do
      #   it 'should raise error for existing but un-activated invoice' do
      #     assert_raises ::Klarna::API::Errors::KlarnaServiceError do
      #       reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_SE)
      #       risk, invoice_no = @client.activate reservation_no: reservation_no
      #       credit_no = ''
      #       @client.credit_invoice(invoice_no, credit_no)
      #     end
      #   end
      # end
      #
      # describe "DE" do
      #   it 'should raise error for existing but un-activated invoice' do
      #     assert_raises ::Klarna::API::Errors::KlarnaServiceError do
      #       reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
      #       risk, invoice_no = @client.activate reservation_no: reservation_no
      #       credit_no = ''
      #       @client.credit_invoice(invoice_no, credit_no)
      #     end
      #   end
      # end

      # FAILS: Klarna API 2.0 don't support this for test-accounts. :(
      # it 'should successfully credit an activated invoice' # do
      #   invoice_no = @client.add_invoice(*@valid_invoice_args_SE)
      #   invoice_url = @client.activate_invoice(invoice_no)
      #   credit_no = ''
      #
      #   assert_equal invoice_no, @client.credit_invoice(invoice_no, credit_no)
      # end
    end

    describe 'partial' do

      # describe "SE" do
      #   it 'should raise error for existing but un-activated invoice' do
      #     assert_raises ::Klarna::API::Errors::KlarnaServiceError do
      #       reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_SE)
      #       risk, invoice_no = @client.activate reservation_no: reservation_no
      #       refund_articles = [@order_items.first]
      #       credit_no = ''
      #       @client.credit_invoice(invoice_no, credit_no, refund_articles)
      #     end
      #   end
      # end
      #
      # describe "DE" do
      #   it 'should raise error for existing but un-activated invoice' do
      #     assert_raises ::Klarna::API::Errors::KlarnaServiceError do
      #       reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
      #       risk, invoice_no = @client.activate reservation_no: reservation_no
      #       refund_articles = [@order_items.first]
      #       credit_no = ''
      #       @client.credit_invoice(invoice_no, credit_no, refund_articles)
      #     end
      #   end
      # end
      it 'should successfully credit part of an invoice'  do
        reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
        risk, invoice_no = @client.activate reservation_no: reservation_no
        credit_no = ''
        refund_articles = [@order_items.last]
        invoice_no_after = @client.credit_invoice invoice_no, credit_no, refund_articles
        assert_equal invoice_no, invoice_no_after
      end
    end
  end

  # Spec:
  #   http://integration.klarna.com/en/api/invoice-handling-functions/functions/emailinvoice
  describe '#email_invoice' do
    it 'should be defined' do
      assert_respond_to @client, :email_invoice
    end

    # describe "SE" do
    #   it 'should raise error for e-mail request of an existing but un-activated invoice' do
    #     assert_raises ::Klarna::API::Errors::KlarnaServiceError do
    #       reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_SE)
    #       risk, invoice_no = @client.activate reservation_no: reservation_no
    #       @client.email_invoice(invoice_no)
    #     end
    #   end
    # end

    # describe "DE" do
    #   it 'should raise error for e-mail request of an existing but un-activated invoice' do
    #     assert_raises ::Klarna::API::Errors::KlarnaServiceError do
    #       reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
    #       risk, invoice_no = @client.activate reservation_no: reservation_no
    #       @client.email_invoice(invoice_no)
    #     end
    #   end
    # end

    # FAILS: Klarna API 2.0 don't support this for test-accounts. :(
    it 'should successfully accept email request' do
      reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
      risk, invoice_no = @client.activate reservation_no: reservation_no

      assert_equal invoice_no, @client.email_invoice(invoice_no)
    end
  end

  # Spec:
  #   http://integration.klarna.com/en/api/invoice-handling-functions/functions/sendinvoice
  describe '#send_invoice' do
    it 'should be defined' do
      assert_respond_to @client, :send_invoice
    end

    # describe "SE" do
    #   it 'should raise error for snail-mail request of an existing but un-activated invoice' do
    #     assert_raises ::Klarna::API::Errors::KlarnaServiceError do
    #       reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_SE)
    #       risk, invoice_no = @client.activate reservation_no: reservation_no
    #       @client.send_invoice(invoice_no)
    #     end
    #   end
    # end
    #
    # describe "DE" do
    #   it 'should raise error for snail-mail request of an existing but un-activated invoice' do
    #     assert_raises ::Klarna::API::Errors::KlarnaServiceError do
    #       reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
    #       risk, invoice_no = @client.activate reservation_no: reservation_no
    #       @client.send_invoice(invoice_no)
    #     end
    #   end
    # end
    # FAILS: Klarna API 2.0 don't support this for test-accounts. :(
    it 'should successfully accept snail-mail request of an activated invoice'  do
      reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
      risk, invoice_no = @client.activate reservation_no: reservation_no

      assert_equal invoice_no, @client.send_invoice(invoice_no)
    end
  end

  # Spec:
  #   http://integration.klarna.com/en/api/invoice-handling-functions/functions/mkartno
  describe '#make_article' do
    it 'should be defined' do
      assert_respond_to @client, :make_article
    end

    it 'should generate valid article structure' do
      assert_equal [5, '12345'], @client.make_article(5, 12345)
      assert_equal [5, '12345'], @client.make_article(5, '12345')
    end
  end

  # Spec:
  #   http://integration.klarna.com/en/api/other-functions/functions/updategoodsqty
  # describe '#update_goods_quantity' do
  #   it 'should be defined' do
  #     assert_respond_to @client, :update_goods_quantity
  #   end
  #
  #   it 'should raise error for an non-existing invoice' do
  #     assert_raises ::Klarna::API::Errors::KlarnaServiceError do
  #       @client.update_goods_quantity(INVALID_ORDER_NO, 'ABC1', 10)
  #     end
  #   end
  #
  #   describe "SE" do
  #     it 'should raise error for an non-existing article-no for an existing invoice' do
  #       assert_raises ::Klarna::API::Errors::KlarnaServiceError do
  #         reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_SE)
  #         risk, invoice_no = @client.activate reservation_no: reservation_no
  #
  #         @client.update_goods_quantity(invoice_no, 'XXX', 10)
  #       end
  #     end
  #
  #     it 'should successfully update goods quantity for an existing invoice and valid article-no' do
  #       reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_SE)
  #       risk, invoice_no = @client.activate reservation_no: reservation_no
  #
  #       assert_equal invoice_no, @client.update_goods_quantity(invoice_no, 'ABC1', 10)
  #     end
  #   end
  #
  #   describe "DE" do
  #     it 'should raise error for an non-existing article-no for an existing invoice' do
  #       assert_raises ::Klarna::API::Errors::KlarnaServiceError do
  #         reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
  #         risk, invoice_no = @client.activate reservation_no: reservation_no
  #
  #         @client.update_goods_quantity(invoice_no, 'XXX', 10)
  #       end
  #     end
  #
  #     # it 'should successfully update goods quantity for an existing invoice and valid article-no' do
  #     #   reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
  #     #   risk, invoice_no = @client.activate reservation_no: reservation_no
  #     #
  #     #   assert_equal invoice_no, @client.update_goods_quantity(invoice_no, 'ABC1', 10)
  #     # end
  #   end
  # end

  # Spec:
  #   http://integration.klarna.com/en/api/other-functions/functions/updatechargeamount
  # describe '#update_charge_amount' do
  #   it 'should be defined' do
  #     assert_respond_to @client, :update_charge_amount
  #   end
  #
  #   it 'should raise error for an non-existing invoice' do
  #     assert_raises ::Klarna::API::Errors::KlarnaServiceError do
  #       @client.update_charge_amount(INVALID_ORDER_NO, 1, 10.00 * 100)
  #     end
  #   end
  #
  #   it 'should successfully update shipment fee for an existing invoice'
  #
  #   it 'should successfully update handling fee for an existing invoice'
  # end

  # Spec: http://integration.klarna.com/en/api/other-functions/functions/updateorderno
  # describe '#update_order_no' do
  #   it 'should be defined' do
  #     assert_respond_to @client, :update_order_no
  #   end
  #
  #   it 'should raise error for an non-existing invoice' do
  #     assert_raises ::Klarna::API::Errors::KlarnaServiceError do
  #       @client.update_order_no(INVALID_ORDER_NO, '123')
  #     end
  #   end
  #
  #   # FIXME: Throws "invno"-error - don't know why. :S
  #   it 'should successfully update order-no for an existing invoice' # do
  #   #   invoice_no = @client.add_invoice(*@valid_invoice_args_SE)
  #   #   new_invoice_no = (invoice_no.to_i + 1).to_s
  #
  #   #   assert_equal new_invoice_no, @client.update_order_no(invoice_no, new_invoice_no)
  #   # end
  # end

  # Spec:
  #   http://integration.klarna.com/en/api/other-functions/functions/invoiceaddress
  # describe '#invoice_address' do
  #   it 'should be defined' do
  #     assert_respond_to @client, :invoice_address
  #   end
  #
  #   it 'should raise error for an non-existing invoice' do
  #     assert_raises ::Klarna::API::Errors::KlarnaServiceError do
  #       @client.invoice_address(INVALID_ORDER_NO)
  #     end
  #   end
  #
  #   describe "SE" do
  #     it 'should successfully return the address for an existing invoice' do
  #       reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
  #       risk, invoice_no = @client.activate reservation_no: reservation_no
  #       assert_equal ['Testperson-se', 'Approved', 'Stårgatan 1', '12345', 'Ankeborg', 'SE'], @client.invoice_address(invoice_no)
  #     end
  #   end
  #
  #   describe "DE" do
  #     it 'should successfully return the address for an existing invoice' do
  #       reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
  #       risk, invoice_no = @client.activate reservation_no: reservation_no
  #       assert_equal ['Testperson-de', 'Approved', 'Hellersbergstraße 14', '41460', 'Neuss', 'DE'], @client.invoice_address(invoice_no)
  #     end
  #   end
  # end

  # Spec:
  #   http://integration.klarna.com/en/api/other-functions/functions/invoiceamount
  #   http://integration.klarna.com/en/api/other-functions/functions/invoicepartamount (combined)
  # describe '#invoice_amount' do
  #   it 'should be defined' do
  #     assert_respond_to @client, :invoice_amount
  #   end
  #
  #   describe 'full' do
  #     it 'should raise error for an non-existing invoice' do
  #       assert_raises ::Klarna::API::Errors::KlarnaServiceError do
  #         @client.invoice_amount(INVALID_ORDER_NO)
  #       end
  #     end
  #
  #     describe "SE" do
  #       it 'should successfully return the invoice amount for an existing invoice' do
  #         reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
  #         risk, invoice_no = @client.activate reservation_no: reservation_no
  #
  #         assert_equal @order_items_total, @client.invoice_amount(invoice_no)
  #       end
  #     end
  #
  #     describe "DE" do
  #       it 'should successfully return the invoice amount for an existing invoice' do
  #         reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
  #         risk, invoice_no = @client.activate reservation_no: reservation_no
  #
  #         assert_equal @order_items_total, @client.invoice_amount(invoice_no)
  #       end
  #     end
  #
  #   end
  #
  #   describe 'partial' do
  #     it 'should raise error for an non-existing invoice' do
  #       assert_raises ::Klarna::API::Errors::KlarnaServiceError do
  #         articles = [@order_items.last]
  #         @client.invoice_amount(INVALID_ORDER_NO, articles)
  #       end
  #     end
  #
  #     describe "SE" do
  #       it 'should successfully return the invoice amount for an existing invoice' do
  #         reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
  #         risk, invoice_no = @client.activate reservation_no: reservation_no
  #         articles = [@order_items.last]
  #
  #         assert_equal 7*(17.00 * 100), @client.invoice_amount(invoice_no, articles)
  #       end
  #     end
  #
  #     describe "DE" do
  #       it 'should successfully return the invoice amount for an existing invoice' do
  #         reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
  #         risk, invoice_no = @client.activate reservation_no: reservation_no
  #         articles = [@order_items.last]
  #
  #         assert_equal 7*(17.00 * 100), @client.invoice_amount(invoice_no, articles)
  #       end
  #     end
  #   end
  # end

  # describe '#invoice_paid?' do
  #   it 'should be defined' do
  #     assert_respond_to @client, :invoice_paid?
  #   end
  #
  #   it 'should raise error for an non-existing invoice' do
  #     assert_raises ::Klarna::API::Errors::KlarnaServiceError do
  #       @client.invoice_paid?(INVALID_ORDER_NO)
  #     end
  #   end
  #
  #   describe "SE" do
  #     it 'should be unpaid for an existing but un-activated invoice' do
  #       reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
  #       risk, invoice_no = @client.activate reservation_no: reservation_no
  #
  #       assert_equal false, @client.invoice_paid?(invoice_no)
  #     end
  #   end
  #
  #   describe "DE" do
  #     it 'should be unpaid for an existing but un-activated invoice' do
  #       reservation_no, invoice_status = @client.reserve_amount(@approved_reservation_DE)
  #       risk, invoice_no = @client.activate reservation_no: reservation_no
  #
  #       assert_equal false, @client.invoice_paid?(invoice_no)
  #     end
  #   end
  # end

end