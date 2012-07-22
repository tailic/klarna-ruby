# encoding: utf-8

module Klarna
  module API
    module Methods
      module Reservation

        # Reserve a purchase amount for a specific customer. The reservation is valid, by default, for 7 days.
        # Pass cellphone no. instead of Pno for SMS payments.
        #
        def reserve_amount(pno, amount, order_id, delivery_address, billing_address, client_ip, currency_code,
                           country_code, language_code, pno_encoding, pclass, goods_list,
                           shipmentinfo = '', reference = '', reference_code = '', comment = '', travelinfo ='', bankinfo = '', gender = 0,
                           session_id = [], extra_info = [], annual_salary = nil, flags = 0)
          params = [
            pno,
            gender,
            amount,
            reference,
            reference_code,
            order_id,
            order_id,
            delivery_address,
            billing_address,
            client_ip,
            flags,
            currency_code,
            country_code,
            language_code,
            self.store_id,
            self.digest(pno, amount),
            pno_encoding,
            (pclass || ::Klarna::API::DEFAULTS[:PCLASS]),
            goods_list,
            comment,
            shipmentinfo,
            travelinfo,
            [(annual_salary || ::Klarna::API::DEFAULTS[:YSALARY])],
            bankinfo,
            session_id,
            extra_info
          ]
          
          self.call(:reserve_amount, *params).tap do |result|
            result = result.first
          end
        end

        # Activate purchases which have been previously reserved with the reserve_amount function.
        #
        def activate_reservation(reservation_id, pno, order_id_1, order_id_2, delivery_address, billing_address, client_ip,
                                 currency_code, country_code, language_code, pno_encoding, pclass, goods_list,
                                 ocr = '', reference = '', reference_code = '', comment = '',
                                 shipmentinfo = 0, travel_info = {}, bank_info = {}, session_id = {}, extra_info = {},
                                 annual_salary = nil, gender = 0, flags = 0)
          params = [
            reservation_id,
            ocr,
            pno,
            gender,
            reference,
            reference_code,
            order_id_1,
            order_id_2,
            delivery_address,
            billing_address,
            client_ip,
            flags,
            currency_code,
            country_code,
            language_code,
            self.store_id,
            self.digest(pno, goods_list),
            pno_encoding,
            (pclass || ::Klarna::API::DEFAULTS[:PCLASS]),
            goods_list,
            comment,
            { delay_adjust: shipmentinfo },
            travel_info,
            { yearly_salary: (annual_salary || ::Klarna::API::DEFAULTS[:YSALARY]) },
            bank_info,
            session_id,
            extra_info
          ]
          self.call(:activate_reservation, *params)
        end

        # Cancel a reservation.
        #
        def cancel_reservation(reservation_id)
          params = [
            reservation_id,
            self.store_id,
            self.digest(reservation_id)
          ]
          self.call(:cancel_reservation, *params)
        end

        # Split a reservation due to for example outstanding articles.
        #
        def split_reservation(reservation_id, split_amount, order_id_1, order_id_2, flags = 0)
          params = [
            reservation_id,
            split_amount,
            order_id_1,
            order_id_2,
            flags.to_i,
            self.store_id,
            self.digest(reservation_id, split_amount)
          ]
          self.call(:split_reservation, *params).tap do |result|
            result = result.first
          end
        end

        # Change a reservation.
        #
        def change_reservation(reservation_id, new_amount, flags = 0)
          params = [
            reservation_id,
            new_amount,
            self.store_id,
            self.digest(reservation_id, new_amount),
            flags
          ]
          self.call(:change_reservation, *params).tap do |result|
            result = result.first
          end
        end

        # Reserves one or more OCR numbers for your store.
        #
        def reserve_ocr_numbers(number_of_ocrs)
          # params = [
          #   number_of_ocrs,
          #   self.store_id,
          #   self.digest(number_of_ocrs)
          # ]
          # self.call(:reserve_ocr_nums, *params)
          raise NotImplementedError
        end

        # Create addresses for arguments such as the +activate_reservation+ function.
        #
        def make_reservation_address(email, telno, cellno, first_name, last_name, street_address, zip, city, country_code, house_number = '', house_extension = '')
          {
            :email            => (email || ''),
            :telno            => (telno || ''),
            :cellno           => (cellno || ''),
            :fname            => (first_name || ''),
            :lname            => (last_name || ''),
            :street           => (street_address || ''),
            :zip              => (zip || ''),
            :city             => (city || ''),
            :country          => (::Klarna::API.id_for(:country, country_code) || ''),
            :house_number     => (house_number || ''),
            :house_extension  => (house_extension || '')
          }.with_indifferent_access
        end
        alias :mk_reservation_address :make_reservation_address

      end
    end
  end
end
