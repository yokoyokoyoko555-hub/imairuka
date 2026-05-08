class StripeSettings
  def self.mode
    ENV.fetch("STRIPE_MODE", "connect").presence_in(%w[connect direct]) || "connect"
  end

  def self.connect_mode?
    mode == "connect"
  end

  def self.direct_mode?
    mode == "direct"
  end

  def self.configured?
    ENV["STRIPE_SECRET_KEY"].present?
  end

  def self.checkout_available?(company)
    return false unless configured?
    return true if direct_mode?

    company&.stripe_connected?
  end

  def self.mode_label
    direct_mode? ? "直接決済" : "Stripe Connect"
  end
end
