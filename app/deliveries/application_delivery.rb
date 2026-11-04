# Base class for deliveries (Active Delivery). A delivery sends one notification
# through every channel: PostsDelivery.published(post) calls PostsMailer.published.
class ApplicationDelivery < ActiveDelivery::Base
  self.abstract_class = true
end
