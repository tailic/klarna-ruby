# encoding: utf-8

module Klarna
  module API
    module Methods
      module Invoicing

        # == TODO:
        #
        #   * #total_credit_purchase_cost
        #

        # Create an invoice.
        #
        def add_invoice(store_user_id, order_id, articles, shipping_fee,
                            handling_fee, shipment_type, pno, first_name, last_name, address_delivery, address_billing, client_ip,
                            currency, country, language, pno_encoding, pclass = nil, annual_salary = nil,
                            password = nil, ready_date = nil, comment = nil, rand_string = nil, new_password = nil, flags = nil)
          shipment_type = ::Klarna::API.id_for(:shipment_type, shipment_type)
          currency = ::Klarna::API.id_for(:currency, currency)
          country = ::Klarna::API.id_for(:country, country)
          language = ::Klarna::API.id_for(:language, language)
          pno_encoding = ::Klarna::API.id_for(:pno_format, pno_encoding)
          pclass = pclass ? ::Klarna::API.id_for(:pclass, pclass) : -1
          flags = ::Klarna::API.parse_flags(:INVOICE, flags)
          articles = Array.wrap(articles).compact
          #TODO get constant for gender ( gender = ::Klarna::API.id_for(:gender, gender) )
          reference = '' #TODO
          reference_code = '' #TODO
          order_id2 = '' #TODO
          gender = 0 #TODO add to funciton params
          ship_info = {delay_adjust: 1}
          travel_info = ''
          income_info = ''
          bank_info = ''
          store_user_id = ''
          extra_info = ''

          params = [
            ::Klarna::API::PROTOCOL_VERSION,
            ::XMLRPC::Client::USER_AGENT,
            pno,
            gender,
            reference,
            reference_code,
            order_id,
            order_id2,
            address_delivery,
            address_billing,
            client_ip.to_s,
            flags.to_i,
            currency,
            country,
            language,
            self.store_id,
            self.digest(articles.collect { |g| g[:goods][:title] }, :store_id => false),
            pno_encoding,
            pclass,
            articles,
            comment.to_s,
            ship_info,
            travel_info,
            income_info,
            bank_info,
            store_user_id,
            extra_info


            #shipping_fee, #TODO deprecated?
            #shipment_type, #TODO deprecated?
            #handling_fee, #TODO deprecated?
            #first_name, #TODO deprecated? part of address
            #last_name, #TODO deprecated? part of address
            #password.to_s, #TODO deprecated?
            #new_password.to_s, #TODO deprecated?
            #ready_date.to_s, #TODO deprecated?
            #rand_string.to_s, #TODO deprecated?
            #annual_salary.to_i #TODO deprecated?
          ]

          self.call(:add_invoice, *params)
        end
        alias :add_transaction :add_invoice

        # Activate a passive invoice - optionally only partly.
        #
        # == Note:
        #
        #   This function call cannot activate an invoice created in test mode. It is however possible
        #   to manually activate such an invoice.
        #
        #   When partially activating an invoice only the articles and quantities specified by
        #   you will be activated. A passive invoice is created containing the articles on the
        #   original invoice not activated.
        #
        def activate_invoice(invoice_no, articles = nil)
          # TODO: Parse/Validate invoice_no as :integer
          # TODO: Parse/Valdiate articles as array of articles
          articles = Array.wrap(articles).compact
          pclass = -1 #TODO ??
          shipment_info = 0 #TODO ??

          params = [
            ::Klarna::API::PROTOCOL_VERSION,
            ::XMLRPC::Client::USER_AGENT,
            self.store_id,
            invoice_no
          ]

          # Only partly?
          if articles.present?
            params << articles
            params << self.digest(invoice_no, articles.collect { |a| [a[:goods][:artno], a[:qty]].join(':') }.join(':'))
            params << pclass
            params << shipment_info
            method = :activate_part
          else
            params << self.digest(invoice_no)
            params << pclass
            params << shipment_info
            method = :activate_invoice
          end

          self.call(method, *params)
        end
        alias :activate_part :activate_invoice

        # Delete a passive invoice.
        #
        def delete_invoice(invoice_no)
          # TODO: Parse/Validate invoice_no as :integer

          params = [
            ::Klarna::API::PROTOCOL_VERSION,
            ::XMLRPC::Client::USER_AGENT,
            self.store_id,
            invoice_no,
            self.digest(invoice_no)
          ]

          self.call(:delete_invoice, *params)
        end

        # Give discounts for invoices.
        #
        def return_amount(invoice_no, amount, vat)
          params = [
            ::Klarna::API::PROTOCOL_VERSION,
            ::XMLRPC::Client::USER_AGENT,
            self.store_id,
            invoice_no,
            amount,
            vat,
            self.digest(invoice_no)
          ]
          self.call(:return_amount, *params) # raise NotImplementedError
        end

        # Return a invoice - optionally only partly.
        #
        def credit_invoice(invoice_no, credit_id, articles = nil)
          articles = Array.wrap(articles).compact


          params = [
            ::Klarna::API::PROTOCOL_VERSION,
            ::XMLRPC::Client::USER_AGENT,
            self.store_id,
            invoice_no,
            credit_id,
          ]

          if articles.present? # Only partly?
            params << articles
            params << self.digest(invoice_no, articles.collect { |a| [a[:goods][:artno], a[:qty]].join(':') }.join(':'))
            method = :credit_part
          else
            params << self.digest(invoice_no)
            method = :credit_invoice
          end

          self.call(method, *params)
        end

        # Send an active invoice to the customer via e-mail.
        #
        # == Note:
        #
        #   Regular postal service is used if the customer lacks an e-mail address.
        #
        def email_invoice(invoice_no)
          # TODO: Parse/Validate invoice_no as integer

          params = [
            ::Klarna::API::PROTOCOL_VERSION,
            ::XMLRPC::Client::USER_AGENT,
            self.store_id,
            invoice_no,
            self.digest(invoice_no)
          ]

          self.call(:email_invoice, *params)
        end

        # Request a postal send-out of an active invoice to a customer by Klarna.
        #
        def send_invoice(invoice_no)
          # TODO: Parse/Validate invoice_no as integer

          params = [
            ::Klarna::API::PROTOCOL_VERSION,
            ::XMLRPC::Client::USER_AGENT,
            self.store_id,
            invoice_no,
            self.digest(invoice_no)
          ]

          self.call(:send_invoice, *params)
        end

        # Create quantity and article number (i.e. the +articles+ argument for the
        # +activate_part+ and +credit_part+ function).
        #
        def make_article(quantity, article_no)
          quantity = quantity.to_i
          article_no = article_no.to_s
          [quantity, article_no]
        end

        # Change the quantity of a specific item in a passive invoice.
        #
        def update_goods_quantity(invoice_no, article_no, new_quantity)
          # TODO: Parse/Validate invoice_no as integer
          # TODO: Parse/Validate article_no as string
          # TODO: Parse/Validate new_quantity as integer

          params = [
            ::Klarna::API::PROTOCOL_VERSION,
            ::XMLRPC::Client::USER_AGENT,
            self.store_id,
            self.digest(invoice_no, article_no, new_quantity, :store_id => false),
            invoice_no,
            article_no,
            new_quantity
          ]

          self.call(:update_goods_qty, *params)
        end

        # Change the amount of a fee (for example the invoice fee) in a passive invoice.
        #
        def update_charge_amount(invoice_no, charge_type, new_amount)
          # TODO: Parse/Validate invoice_no as integer
          # TODO: Parse/Validate charge_type as integer/charge-type
          # TODO: Parse/Validate new_amount as integer (or parse from decimal)

          params = [
            ::Klarna::API::PROTOCOL_VERSION,
            ::XMLRPC::Client::USER_AGENT,
            self.store_id,
            self.digest(invoice_no, charge_type, new_amount),
            invoice_no,
            charge_type,
            new_amount
          ]

          self.call(:update_charge_amount, *params)
        end

        # Change the store’s order number for a specific invoice.
        #
        def update_order_no(invoice_no, new_order_no)
          # TODO: Parse/Validate invoice_no as integer
          # TODO: Parse/Validate new_order_no as integer

          params = [
            ::Klarna::API::PROTOCOL_VERSION,
            ::XMLRPC::Client::USER_AGENT,
            self.store_id,
            invoice_no,
            self.digest(invoice_no, new_order_no),
            new_order_no
          ]

          self.call(:update_orderno, *params)
        end

        # Retrieve the address for an invoice.
        #
        def invoice_address(invoice_no)
          # TODO: Parse/Validate invoice_no as integer

          params = [
            ::Klarna::API::PROTOCOL_VERSION,
            ::XMLRPC::Client::USER_AGENT,
            self.store_id,
            invoice_no,
            self.digest(invoice_no)
          ]

          self.call(:invoice_address, *params).tap do |result|
            result[5] = result[5].to_s.upcase
          end
        end
        alias :get_invoice_address :invoice_address

        # Retrieve the total amount of an invoice - optionally only partly.
        #
        def invoice_amount(invoice_no, articles = nil)
          # TODO: Parse/Validate invoice_no as integer
          articles = Array.wrap(articles).compact
          artnos =
            if articles.first.respond_to?(:key?) && articles.first.key?(:qty) && articles.first.key?(:artno)
              articles
            else
              articles.collect { |a| {:artno => a[:goods][:artno], :qty => a[:qty]} }
            end

          params = [
            ::Klarna::API::PROTOCOL_VERSION,
            ::XMLRPC::Client::USER_AGENT,
            self.store_id,
            invoice_no
          ]

          # Only partly?
          if articles.present?
            params << artnos
            params << self.digest(invoice_no, artnos.collect { |an| [an[:artno], an[:qty]].join(':') }.join(':'))
            method = :invoice_part_amount
          else
            params << self.digest(invoice_no)
            method = :invoice_amount
          end

          self.call(method, *params)
        end
        alias :get_invoice_amount :invoice_amount

        # Check if invoice is paid.
        #
        def invoice_paid?(invoice_no)
          # TODO: Parse/Validate invoice_no as numeric value (string)

          params = [
            ::Klarna::API::PROTOCOL_VERSION,
            ::XMLRPC::Client::USER_AGENT,
            invoice_no,
            self.store_id,
            self.digest(invoice_no)
          ]

          result = self.call(:is_invoice_paid, *params)
          result == 'unpaid' ? false : true
        end

      end
    end
  end
end
