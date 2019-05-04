# frozen_string_literal: true

require 'json'

# class Holder
class Holder
  attr_accessor :first_name, :last_name, :id

  def initialize(id, first_name, last_name)
    @id = id
    @first_name = first_name
    @last_name = last_name
  end

  def full_name
    "#{@first_name} #{@last_name}"
  end

  def to_hash
    {
      id: @id,
      first_name: @first_name,
      last_name: @last_name
    }
  end

  def to_json(_opts)
    to_hash.to_json
  end

end
