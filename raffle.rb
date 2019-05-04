# frozen_string_literal: true

require 'logger'
require 'redis'

require './holder'

# Raffle class
class Raffle
  def initialize(url)
    @redis = Redis.new(url: url)
  end

  def random_holder_from_chat(chat_id)
    holders = holders_from(chat_id)
    holders.sample
  end

  def holders_from(chat_id)
    group = @redis.get(chat_id)

    return [] if group.nil?

    group = JSON.parse(group).map do |h|
      Holder.new(h['id'], h['first_name'], h['last_name'])
    end

    group
  end

  def add_holder(chat_id, holder)
    holders = holders_from(chat_id)
    holders << holder
    save_holders(chat_id, holders)
  end

  def remove_holder(chat_id, holder)
    holders = holders_from(chat_id)
    holders = holders.reject { |h| h.id == holder.id }
    save_holders(chat_id, holders)
  end

  def save_holders(chat_id, holders)
    tmp = holders
          .uniq(&:id)
          .map(&:to_hash)
          .to_json

    @redis.set(chat_id, tmp)
  end
end
