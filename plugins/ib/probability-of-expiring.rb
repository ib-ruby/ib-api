module IB
  module ProbabilityOfExpiring

    # Use  by calling
    #   a = Stock.new symbol: 'A'
    #
    require 'prime'
    require 'distribution'



    def probability_of_assignment  **args
      ( probability_of_expiring(**args) - 1 ).abs
    end
    def probability_of_expiring  **args
      @probability_of_expiring = calculate_probability_of_expiring(**args) if @probability_of_expiring.nil? ||  ! args.empty?
      @probability_of_expiring
    end

    private
=begin
Here are the steps to calculate the probability of expiry cone for a stock in
the next six months using the Black-Scholes model:

*  Determine the current stock price and the strike price for the option you
   are interested in. Let's say the current stock price is $100 and the strike
   price is $110.  *  Determine the time to expiry. In this case, we are
   interested in the next six months, so the time to expiry is 0.5 years.  *
   Determine the implied volatility of the stock. Implied volatility is a measure
   of the expected volatility of the stock over the life of the option, and can be
   estimated from the option prices in the market.

* Use the Black-Scholes formula to calculate the probability of the stock
  expiring within the range of prices that make up the expiry cone. The formula
  is:

                    P = N(d2)

  Where P is the probability of the stock expiring within the expiry cone, and
  N is the cumulative distribution function of the standard normal
  distribution. d2 is calculated as:

                    d2 = (ln(S/K) + (r - 0.5 * σ^2) * T) / (σ * sqrt(T))

  Where S is the current stock price, K is the strike price, r is the risk-free
  interest rate, σ is the implied volatility, and T is the time to expiry.

  Look up the value of N(d2) in a standard normal distribution table, or use a
  calculator or spreadsheet program that can calculate cumulative distribution
  functions.

  The result is the probability of the stock expiring within the expiry cone.
  For example, if N(d2) is 0.35, then the probability of the stock expiring
                 within the expiry cone is 35%.

(ChatGPT)
=end
    def calculate_probability_of_expiring price: nil,
                                          interest: 0.03,
                                          iv: nil,
                                          strike: nil,
                                          expiry: nil,
                                          ref_date: Date.today

      if iv.nil?  && self.respond_to?( :greek )
        IB::Connection.logger.info "Probability_of_expiring: using current IV and Underlying-Price for calculation"
          request_greeks if greek.nil?
          iv = greek.implied_volatility
          price = greek.under_price if price.nil?
      end
      error "ProbabilityOfExpiringCone needs iv as input" if iv.nil? || iv.zero?

      if price.nil?
        price =  if self.strike.to_i.zero?
                   market_price
                 else
                   underlying.market_price
                 end
      end
      error "ProbabilityOfExpiringCone needs price as input" if price.to_i.zero?


      strike ||= self.strike
      error "ProbabilityOfExpiringCone needs strike as input" if strike.to_i.zero?

      if expiry.nil?
        if last_trading_day == ''
          error "ProbabilityOfExpiringCone needs expiry as input"
        else
          expiry = last_trading_day
        end
      end
      time_to_expiry = ( Date.parse( expiry.to_s ) - ref_date ).to_i

      # # Calculate d1 and d2
      d1 = (Math.log(price/strike.to_f) + (interest + 0.5*iv**2)*time_to_expiry) / (iv * Math.sqrt(time_to_expiry))
      d2 = d1 - iv * Math.sqrt(time_to_expiry)
      #
      # # Calculate the probability of expiry cone
      Distribution::Normal.cdf(d2)

    end
  end

  class Contract
    include ProbabilityOfExpiring
  end

end
