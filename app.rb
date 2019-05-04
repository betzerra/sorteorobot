require 'json'
require 'logger'
require 'sinatra'
require 'telegram/bot'

require './raffle_controller'

bot = Telegram::Bot::Client.new(ENV['TELEGRAM_TOKEN'])
logger = Logger.new(STDOUT)
raffle_controller = RaffleController.new(bot)

post '/tg' do
  request.body.rewind
  data = JSON.parse(request.body.read)
  logger.debug("Received data: #{data.inspect}")

  raffle_controller.handle_data(data)

  '{}'
end
