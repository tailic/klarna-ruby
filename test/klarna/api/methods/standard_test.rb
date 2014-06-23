# encoding: utf-8
require 'test_helper'

describe Klarna::API::Methods::Standard do

   # TODO: Mock responses using VCR.

  before do
    valid_credentials!
    @klarna = Klarna::API::Client.new
    @klarna.client_ip = '127.0.0.1'

    @protocol_version = ::Klarna::API::PROTOCOL_VERSION.to_s
    @user_agent = ::XMLRPC::Client::USER_AGENT.to_s

    @pno_format_sweden = ::Klarna::API::COUNTRIES[:SE]
    @country_sweden = ::Klarna::API::COUNTRIES[:SE]

    expose_protected_methods_in @klarna.class

    #TODO use fixtures!
  end

  # Spec:
  #   http://integration.klarna.com/en/api/standard-integration/functions/getaddresses
  describe '#get_addresses' do
    it 'should be defined' do
      assert_respond_to @klarna, :get_addresses
    end

    # it 'should require: pno, country'

    it 'should handle pno-format as integer (pno-format ID)' do
      assert @klarna.get_addresses("4304158399", 2) # a.k.a. ::Klarna::API::PNO_FORMATS[:SE]
    end

    it 'should handle pno-format as integer (pno-format ID)' do
      assert @klarna.get_addresses("4304158399", :SE)
    end

    # it 'should pre-validate the specified pno, and raise validation error if it s invalid without any service call'

    describe "SE" do
      it 'should return address for a valid pno' do
        result = @klarna.get_addresses("4304158399", :SE)
        assert_equal [@protocol_version, @user_agent, "4304158399", @klarna.store_id, @klarna.digest("4304158399"), 2, 5, '127.0.0.1'], @klarna.last_request_params
        assert_equal [["Karl", "Lidin", "Junibacksg 42", "23634", "Hollviken", :SE]], result

        result = @klarna.get_addresses("5311096845", :SE)
        assert_equal [@protocol_version, @user_agent, "5311096845", @klarna.store_id, @klarna.digest("5311096845"), 2, 5, '127.0.0.1'], @klarna.last_request_params
        assert_equal [["Maud", "Johansson", "Köpmansg 7", "12149", "Johanneshov", :SE]], result
      end

      it 'should ignore format symbols in pno' do
        result = @klarna.get_addresses("430415-8399", :SE)
        assert_equal [@protocol_version, @user_agent, "4304158399", @klarna.store_id, @klarna.digest("4304158399"), 2, 5, '127.0.0.1'], @klarna.last_request_params
      end
    end
  end

  describe '#get_address' do
    it 'should be defined' do
      assert_respond_to @klarna, :get_address
    end

    it 'should only return first returned address for a valid SSN' do
      result = @klarna.get_address("4304158399", :SE)
      assert_equal ["Karl", "Lidin", "Junibacksg 42", "23634", "Hollviken", :SE], result
    end
  end

  # Spec:
  #   http://integration.klarna.com/en/api/standard-integration/functions/mkaddr
  describe '#make_address' do
    it 'should be defined' do
      assert_respond_to @klarna, :make_address
    end

    describe "SE" do
      it 'should generate an valid address array' do
        assert_equal ({
            :fname        => 'Testperson-se',
            :lname        => 'Approved',
            :careof       => '',
            :street       => 'Stårgatan 12',
            :house_number => '',
            :postno       => '12345',
            :city         => 'Ankeborg',
            :country      => 209,
            :telno        => '0765260000',
            :cellno       => '0765260000',
            :email        => 'youremail@email.com'
          }.with_indifferent_access),
          @klarna.make_address({:fname => 'Testperson-se',
                                :lname => 'Approved',
                                :careof => '',
                                :street => 'Stårgatan 12',
                                :postno => '12345',
                                :city => 'Ankeborg',
                                :country => :SE,
                                :telno => '076 526 00 00',
                                :cellno => '076 526 00 00',
                                :email => 'youremail@email.com'})
      end

      # TODO
      describe 'argument constraints: raise argument error if not true (no API-call)' do
        describe 'care_of' do
          # it 'should be a string or nil'
        end

        describe 'street' do
          # it 'should be a string'
        end

        describe 'postal code' do
          # it 'should be a string/integer'
        end

        describe 'city' do
          # it 'should be a string'
        end

        describe 'country' do
          # it 'should be a string/symbol/integer (-> valid Klarna country ID)'
        end

        describe 'phone' do
          # it 'should be a string/integer'

          # it 'should ignore whitespace'
        end

        describe 'cell_phone' do
          # it 'should be a string/integer'

          # it 'should ignore whitespace'
        end

        describe 'email' do
          # it 'should be a valid email (string)'
        end
      end
    end

    describe 'DE' do
      it 'should generate an valid address array' do
        assert_equal ({
            :fname        => 'Testperson-de',
            :lname        => 'Approved',
            :careof       => '',
            :street       => 'Hellersbergstraße',
            :house_number => '14',
            :postno       => '41460',
            :city         => 'Neuss',
            :country      => 81,
            :telno        => '01522113356',
            :cellno       => '01522113356',
            :email        => 'youremail@email.com'

        }.with_indifferent_access),
        @klarna.make_address({:fname => 'Testperson-de',
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
      end

      # TODO
      describe 'argument constraints: raise argument error if not true (no API-call)' do

      end
    end
  end

  # Spec:
  #   http://integration.klarna.com/en/api/standard-integration/functions/mkgoodsflags
  describe '#make_goods' do
    it 'should be defined' do
      assert_respond_to @klarna, :make_goods
    end

    # it 'should require: quantity, artno vs title, price, vat'

    # it 'should pre-validate the specified address values, and raise validation error if it s invalid without any service call'

    describe 'argument constraints: raise argument error if not true (no API-call)' do
      describe 'quantity' do
        # it 'should be a integer/string'

        # it 'should be >= 1'
      end

      describe 'artno' do
        # it 'should be a integer/string if no title is specified'
      end

      describe 'title' do
        # it 'should be a integer/string if no artno is specified'
      end

      describe 'price' do
        # it 'should be a integer/string/decimal if no artno is specified'

        # it 'should convert to cents if decimal (assumption)'
      end

      describe 'vat' do
        # it 'should be a integer/string/decimal if no artno is specified'
      end
    end

    it 'should generate an valid address structure: quantity, artno, title, price, vat' do
      assert_equal ({
          'goods' => {
              'artno'     => "ABC123",
              'title'     => "T-shirt",
              'price'     => 2500,
              'vat'       => 25.00,
              'discount'  => 0.00,
              'flags'     => 0
            },
          'qty' => 5
        }),
        @klarna.make_goods(5, "ABC123", "T-shirt", 25.00 * 100, 25)
    end

    it 'should generate an valid address structure: quantity, artno, title, price, vat, discount' do
      assert_equal ({
          'goods' => {
              'artno'     => "ABC123",
              'title'     => "T-shirt",
              'price'     => 2500,
              'vat'       => 25.00,
              'discount'  => 10.00,
              'flags'     => 0
            },
          'qty' => 5
        }),
        @klarna.make_goods(5, "ABC123", "T-shirt", 25.00 * 100, 25, 10)
    end

    it 'should generate an valid address structure: quantity, artno, title, price, vat, discount, flags' do
      assert_equal ({
          'goods' => {
              'artno'     => "ABC123",
              'title'     => "T-shirt",
              'price'     => 2500,
              'vat'       => 25.00,
              'discount'  => 10.00,
              'flags'     => 32
            },
          'qty' => 5
        }),
        @klarna.make_goods(5, "ABC123", "T-shirt", 25.00 * 100, 25, 10, ::Klarna::API::GOODS[:INC_VAT])
    end

    it 'should be possible to set flags via options' do
      assert_equal ({
          'goods' => {
              'artno'     => "ABC123",
              'title'     => "T-shirt",
              'price'     => 2500,
              'vat'       => 25.00,
              'discount'  => 0.00,
              'flags'     => 48
            },
          'qty' => 5
        }),
        @klarna.make_goods(5, "ABC123", "T-shirt", 25.00 * 100, 25, 0, :inc_vat => true, :is_handling => true)
    end
  end

  # Spec:
  #   http://integration.klarna.com/en/api/advanced-integration/functions/hasaccount
  describe '#has_account?' do
    it 'should be defined' do
      assert_respond_to @klarna, :has_account?
    end

    # FIXME: Throws error "Unknown call (-99)". :S
    it 'should be true' # do
    #   assert_equal true, @klarna.has_account?("4304158399", :SE)
    # end
  end

end
