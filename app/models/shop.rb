class Shop < ActiveRecord::Base
  Rails.env == 'development'||'test' ? HOOK_ADDRESS = 'http://shipwireapp:3001/' : HOOK_ADDRESS = 'production root url'
  #TODO: set production url

  attr_accessible :login, :password, :automatic_fulfillment

  has_many :variants
  has_many :fulfillments
  has_many :orders

  validates_presence_of :login, :password, :token
  validates :domain, :presence => true, :uniqueness => true

  before_create :set_domain
  after_create :setup_webhooks

  def credentials
    return {login: login, password: password}
  end

  private

  def set_domain
    domain = ShopifyAPI::Shop.current.myshopify_domain
  end

  def setup_webhooks
    hooks = {
      'orders/paid' => 'orderpaid',
      'orders/cancelled' => 'ordercancelled',
      'orders/create' => 'ordercreate',
      'orders/updated' => 'orderupdated',
      'orders/fulfilled' => 'orderfulfilled'
    }
    hooks.each { |topic, action| make_webhook(topic, action) }
  end

  def make_webhook(topic, action)
    ShopifyAPI::Webhook.create({topic: topic, address: HOOK_ADDRESS + action, format: 'json'})
  end

end