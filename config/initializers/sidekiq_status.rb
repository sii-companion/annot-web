module Sidekiq::Status
    remove_const :DEFAULT_EXPIRY
    DEFAULT_EXPIRY = 60*60*24*30*6  # 6 months
end
