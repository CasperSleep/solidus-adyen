# Users may want to have transactions for different stores be processed by
# different merchant accounts in Adyen. We don't always have direct access to
# the store when creating a payment request, so this class provides methods to
# look up the store and its corresponding merchant account given limited information.
#
# For example:
# In gateway actions such as authorize, capture, cancel, etc. the
# only information we consistently have access to is the psp reference for the
# payment.
module SolidusAdyen
  class AccountLocator
    attr_reader :store_account_map, :default_account
    # Creates a new merchant account locator.
    #
    # @param store_account_map [Hash] a hash mapping store codes to merchant accounts
    # @param default_account [String] the default merchant account to use
    def initialize(store_account_map, default_account)
      @store_account_map = store_account_map
      @default_account = default_account
    end

    # Tries to find a store that has a payment with the given psp reference. If
    # one exists, returns the merchant account for that store. Otherwise, returns
    # the default merchant acount.
    #
    # @param psp_reference [String] the psp reference for the payment
    # @return merchant account [String] the name of the merchant account
    def by_reference(psp_reference)
      store = Spree::Store.
                joins(orders: :payments).
                find_by(spree_payments: { response_code: psp_reference })
      code = store.try!(:code)

      by_store_code(code, store)
    end

    # If the order belongs to a store, returns the merchant account for that
    # store. Otherwise, returns the default merchant account.
    #
    # @param order [Spree::Order] the order used to find the merchant account
    # @return merchant account [String] the name of the merchant account
    def by_order(order)
      store = order.store
      code = store.try!(:code)
      by_store_code(code, store)
    end

    # Returns the merchant account for the store if one is provided. Returns
    # the default merchant account otherwise.
    #
    # @param code [String] the store code used to look up the merchant account
    # @param store [Store] the store used to look up the merchant account
    # @return merchant account [String] the name of the merchant account
    def by_store_code(code, store)
      store.try(:adyen_merchant_id).presence || store_account_map[code] || default_account
    end
  end
end
