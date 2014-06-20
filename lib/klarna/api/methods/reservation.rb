# encoding: utf-8

module Klarna
  module API
    module Methods
      module Reservation

        # To check an invoice or a reservation order status if it is ok, pending or denied.
        #
        def check_order_status(params)
          
          xmlrpc_params = [
            ::Klarna::API::PROTOCOL_VERSION,
            ::XMLRPC::Client::USER_AGENT,
            params[:id],
            params[:type]
          ]
          
          self.call(:check_order_status, *xmlrpc_params)
        end

        # To check an invoice or a reservation order status if it is ok, pending or denied.
        #
        def activate(params)

          signature = [
              ::Klarna::API::PROTOCOL_VERSION.clone.gsub('.',':'),
              ::XMLRPC::Client::USER_AGENT,
              store_id,
              params[:rno],
              store_secret
          ]

          xmlrpc_params = [
              ::Klarna::API::PROTOCOL_VERSION,
              ::XMLRPC::Client::USER_AGENT,
              store_id,
              ::Klarna::API.digest(signature),
              params[:rno],
              {}
          ]

          # %w{orderid1 orderid2 flags reference reference_code ocr bclass cust_no artnos artno qty}.each do |attr|
          #   attr = attr.to_sym
          #   xmlrpc_params.push params[attr] if params[attr]
          # end

          self.call(:activate, *xmlrpc_params).tap do |result|
            result = result.first
          end
        end

        # Reserve a purchase amount for a specific customer. The reservation is valid, by default, for 7 days.
        # Pass cellphone no. instead of Pno for SMS payments.
        #
        def reserve_amount(params)
          
          xmlrpc_params = [
            ::Klarna::API::PROTOCOL_VERSION,
            ::XMLRPC::Client::USER_AGENT,
            params[:pno],
            params[:gender] || 0,
            params[:amount],
            params[:reference] || '',
            params[:reference_code] || '',
            params[:order_id],
            params[:order_id],
            params[:delivery_address],
            params[:billing_address],
            params[:client_ip] || '0.0.0.0',
            params[:flags] || 0,
            params[:currency],
            params[:country],
            params[:language],
            self.store_id,
            self.digest(params[:pno], params[:amount]),
            params[:pno_encoding],
            (params[:pclass] || ::Klarna::API::DEFAULTS[:PCLASS]),
            params[:goods_list],
            params[:comment] || '',
            params[:shipmentinfo] || { delay_adjust: 1 },
            params[:travelinfo] || [],
            params[:income_expense] || [::Klarna::API::DEFAULTS[:YSALARY]],
            params[:bankinfo] || [],
            params[:session_id] || [],
            params[:extra_info] || []
          ]
          
          self.call(:reserve_amount, *xmlrpc_params).tap do |result|
            result = result.first
          end
        end

        # Activate purchases which have been previously reserved with the reserve_amount function.
        #
        def activate_reservation(params)
                                   
          xmlrpc_params = [
            ::Klarna::API::PROTOCOL_VERSION,
            ::XMLRPC::Client::USER_AGENT,
            params[:reservation_id],
            params[:ocr] || '',
            params[:pno],
            params[:gender] || 0,
            params[:reference] || '',
            params[:reference_code] || '',
            params[:order_id_1],
            params[:order_id_2],
            params[:delivery_address],
            params[:billing_address],
            params[:client_ip] || '0.0.0.0',
            params[:flags] || 0,
            params[:currency],
            params[:country],
            params[:language],
            self.store_id,
            self.digest(params[:pno], params[:goods_list].map{ |goods| goods[:goods][:artno]+':'+goods[:qty].to_s } ),
            params[:pno_encoding],
            (params[:pclass] || ::Klarna::API::DEFAULTS[:PCLASS]),
            params[:goods_list],
            params[:comment] || '',
            params[:shipmentinfo] || { delay_adjust: 1 },
            params[:travelinfo] || [],
            params[:income_expense] || [::Klarna::API::DEFAULTS[:YSALARY]],
            params[:session_id] || [],
            params[:extra_info] || []
          ]
          
          xmlrpc_params = [xmlrpc_params] # Klarna needs all values to be in first param for activate_reservation only
          
          self.call(:activate_reservation, *xmlrpc_params)
        end

        # Cancel a reservation.
        #
        def cancel_reservation(params)
          xmlrpc_params = [
            ::Klarna::API::PROTOCOL_VERSION,
            ::XMLRPC::Client::USER_AGENT,
            params[:reservation_id],
            self.store_id,
            self.digest(params[:reservation_id])
          ]
          self.call(:cancel_reservation, *xmlrpc_params)
        end

        # Split a reservation due to for example outstanding articles.
        #
        def split_reservation(params)
          
          xmlrpc_params = [
            ::Klarna::API::PROTOCOL_VERSION,
            ::XMLRPC::Client::USER_AGENT,
            params[:reservation_id],
            params[:split_amount],
            params[:order_id_1],
            params[:order_id_2],
            params[:flags].to_i || 0,
            self.store_id,
            self.digest(params[:reservation_id], params[:split_amount])
          ]
          self.call(:split_reservation, *xmlrpc_params).tap do |result|
            result = result.first
          end
        end

        # Change a reservation.
        #
        def change_reservation(params)
          
          xmlrpc_params = [
            ::Klarna::API::PROTOCOL_VERSION,
            ::XMLRPC::Client::USER_AGENT,
            params[:reservation_id],
            params[:new_amount],
            self.store_id,
            self.digest(params[:reservation_id], params[:new_amount])
          ]
          self.call(:change_reservation, *xmlrpc_params).tap do |result|
            result = result.first
          end
        end

        # Reserves one or more OCR numbers for your store.
        #
        def reserve_ocr_numbers(number_of_ocrs)
          # params = [
          #   ::Klarna::API::PROTOCOL_VERSION,
          #   ::XMLRPC::Client::USER_AGENT,
          #   number_of_ocrs,
          #   self.store_id,
          #   self.digest(number_of_ocrs)
          # ]
          # self.call(:reserve_ocr_nums, *params)
          raise NotImplementedError
        end

        # Create addresses for arguments such as the +activate_reservation+ function.
        #
        def make_reservation_address(params)
          {                              
            :email            => (params[:email] || ''),
            :telno            => (params[:telno] || ''),
            :cellno           => (params[:cellno] || ''),
            :fname            => (params[:fname] || ''),
            :lname            => (params[:lname] || ''),
            :company          => (params[:company] || ''),
            :careof           => (params[:careof] || ''),
            :street           => (params[:street] || ''),
            :zip              => (params[:zip] || ''),
            :city             => (params[:city] || ''),
            :country          => (::Klarna::API.id_for(:country, params[:country]) || ''),
            :house_number     => (params[:house_number] || ''),
            :house_extension  => (params[:house_extension] || '')
          }.with_indifferent_access
        end
        alias :mk_reservation_address :make_reservation_address

      end
    end
  end
end
