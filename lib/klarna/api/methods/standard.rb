# encoding: utf-8

module Klarna
  module API
    module Methods
      module Standard

        # Retrieve a customer’s address(es). Using this, the customer is not required to enter
        # any information – only confirm the one presented to him/her.
        # Can also be used for companies: If the customer enters a company number,
        # it will return all the addresses where the company is registered at.
        #
        # == Note:
        #
        #   ONLY allowed to be used for Swedish persons with the following conditions:
        #
        #     * It can be only used if invoice or part payment is the default payment method
        #     * It has to disappear if the customer chooses another payment method
        #     * The button is not allowed to be called get address ("hämta adress"), but continue ("fortsätt")
        #       or it can be picked up automatically when all the numbers have been typed.
        #
        #   In the other Nordic countries you will have to have input fields for name, last name, street name,
        #   zip code and city so that the customer can enter this information by himself.
        #
        def get_addresses(pno, pno_encoding, address_type = :GIVEN)
          pno = pno.to_s.gsub(/[\W]/, '')
          pno_encoding = ::Klarna::API.id_for(:pno_format, pno_encoding)
          address_type = ::Klarna::API.id_for(:address_format, address_type)
          params = [
            ::Klarna::API::PROTOCOL_VERSION,
            ::XMLRPC::Client::USER_AGENT,
            pno,
            self.store_id,
            self.digest(pno),
            pno_encoding,
            address_type,
            self.client_ip
          ]
          self.call(:get_addresses, *params).tap do |result|
            result = result.first
            country_id = ::Klarna::API.id_for(:country, result[5])
            result[5] = ::Klarna::API::COUNTRIES.key(country_id)
          end
        end

        # Same as +get_addresses+ but returns only first address.
        #
        def get_address(*args)
          self.get_addresses(*args).first
        end

        # Create addresses (i.e. the +address+ argument to the +add_transaction+ method).
        # TODO Check if neccesary params are set
        def make_address(params = {})
          country = ::Klarna::API.id_for(:country, params[:country])
          phone = params[:telno].to_s.gsub(/[\W\s\t]/, '')
          cell_phone = params[:cellno].to_s.gsub(/[\W\s\t]/, '')
          {
            :fname        => params[:fname],
            :lname        => params[:lname],
            :careof       => params[:careof],
            :street       => params[:street],
            :house_number => params[:house_number].to_s, #AT/DE/NL only
            :postno       => params[:postno],
            :city         => params[:city],
            :country      => country,
            :telno        => phone,
            :cellno       => cell_phone,
            :email        => params[:email]
          }.with_indifferent_access
        end
        alias :mk_address :make_address

        # Create an inventory (i.e. the +goods_list+ argument) to the +add_transaction+ function.
        #
        # == Flags:
        #
        # Argument +flags+ can be used to set the precision of the article, to indicate a shipment
        # or a fee or sending the price with VAT.
        #
        # By using either +PRINT_1000+, +PRINT_100+, or +PRINT_10+, the +flags+
        # function can be used to set article quantity (+quantity+). Unit is either +1/10+, +1/100+
        # or +1/1000+. This is useful for goods measured in meters or kilograms, rather than number of items.
        #
        # By using the +IS_SHIPMENT+ or +IS_HANDLING+ flags a shipping or handling fee can
        # be applied. The fees are sent excluding VAT with the arguments +shipping_fee+ or +handling_fee+.
        #
        # By using the +INC_VAT+ flag, you can send the price including VAT.
        #
        # == Note:
        #
        #   If you are implementing sales with Euros, use the function mk_goods_flags instead
        #   since using this method can result in round off problems. With +mk_goods_flags+ you
        #   are able to send the price with VAT.
        #
        def make_goods(quantity, article_no, title, price, vat, discount = nil, flags = nil)
          flags = ::Klarna::API.parse_flags(:GOODS, flags)
          goods = {
            :goods => {
              :artno     => article_no,
              :title     => title,
              :price     => price.to_i,
              :vat       => vat.to_f.round(2),
              :discount  => discount.to_f.round(2),
            },
            :qty => quantity.to_i
          }
          goods[:goods].merge!(:flags => flags.to_i) # if flags.present?
          goods.with_indifferent_access
        end
        alias :mk_goods :make_goods
        alias :mk_goods_flags :make_goods

        # Check if a user has an account.
        #
        def has_account?(pno, pno_encoding)
          params = [
            self.store_id,
            self.digest(pno),
            pno_encoding
          ]
          self.call(:has_account, *params)
        end

      end
    end
  end
end
