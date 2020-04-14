# frozen_string_literal: true

require 'logger'

require './raffle'
require './holder'

class RaffleController

  def initialize(bot)
    @bot = bot

    redis_url = "#{ENV["REDIS_URL"]}/1"
    @raffle = Raffle.new(redis_url)
    @logger = Logger.new(STDOUT)
  end

  def holder_from_message(message)
    holder = Holder.new(
      message['from']['id'],
      message['from']['first_name'],
      message['from']['last_name']
    )
  end

  def add_holder(message)
    chat_id = message['chat']['id']
    return if chat_id.nil?

    begin
      holder = holder_from_message(message)
      @raffle.add_holder(chat_id, holder)

      @bot.api.send_message(
        chat_id: chat_id,
        text: '👍',
        reply_to_message_id: message['message_id']
      )

      @logger.info("Adding #{holder.full_name} (#{holder.id})")
    rescue => e
      @logger.error(e.message)
      @logger.error("Backtrace #{e.backtrace.join("\n\t")}")
    end
  end

  def remove_holder(message)
    chat_id = message['chat']['id']
    return if chat_id.nil?

    begin
      holder = holder_from_message(message)
      @raffle.remove_holder(chat_id, holder)

      @logger.info("Removing #{holder.full_name} (#{holder.id})")
    rescue => e
      @logger.error(e.message)
      @logger.error("Backtrace #{e.backtrace.join("\n\t")}")
    end
  end

  def show_holders(message)
    chat_id = message['chat']['id']
    return if chat_id.nil?

    begin
      holders = @raffle.holders_from(chat_id)

      if holders.empty?
        @bot.api.send_message(
          chat_id: chat_id,
          text: 'No hay nadie 😱',
          parse_mode: 'markdown'
        )
        return
      end
      list = holders.map { |h| "- #{h.full_name}" }

      @bot.api.send_message(
        chat_id: chat_id,
        text: list.join("\n"),
        parse_mode: 'markdown'
      )

      @logger.info("Show holders at #{chat_id}")
    rescue => e
      @logger.error(e.message)
      @logger.error("Backtrace #{e.backtrace.join("\n\t")}")
    end
  end

  def run_raffle(message)
    chat_id = message['chat']['id']
    return if chat_id.nil?

    begin
      holder = @raffle.random_holder_from_chat(chat_id)

      if holder.nil?
        @bot.api.send_message(
          chat_id: chat_id,
          text: 'No hay nadie en este grupo para participar.'
        )
        return
      end

      @bot.api.send_message(
        chat_id: chat_id,
        text: "Ganó *#{holder.full_name}* 🙌",
        parse_mode: 'markdown'
      )

      @logger.info("Sampled #{holder.full_name} (#{holder.id})")
    rescue => e
      @logger.error(e.message)
      @logger.error("Backtrace #{e.backtrace.join("\n\t")}")
    end
  end

  def reset_raffle(message)
    chat_id = message['chat']['id']
    return if chat_id.nil?

    @raffle.save_holders(chat_id, [])

    @bot.api.send_message(
      chat_id: chat_id,
      text: 'Reseteado 👍',
      parse_mode: 'markdown'
    )

    @logger.info("Reset raffle at #{chat_id}")
  end

  def help(message)
    chat_id = message['chat']['id']
    return if chat_id.nil?

    text = '¡Hola! Soy un bot que hace sorteos en grupos de Telegram.
Estos son mis comandos:

- */agregarme* te agrega al sorteo
- */quitarme* te quita del sorteo
- */concursantes* muestra las personas que participan
- */sorteo* ¡HACE EL SORTEO! (duh)
- */reset* quita a todos del sorteo

[Leer más](https://betzerra.com/sorteo-bot-telegram).'

    begin
      @bot.api.send_message(
        chat_id: chat_id,
        text: text,
        parse_mode: 'markdown',
        disable_web_page_preview: true
      )
    rescue => e
      @logger.error(e.message)
      @logger.error("Backtrace #{e.backtrace.join("\n\t")}")
    end
  end

  def command_not_found_message(message)
    chat_id = message['chat']['id']
    return if chat_id.nil?

    from = message['from']['first_name']
    return if from.nil?

    begin
      @bot.api.send_message(
        chat_id: chat_id,
        text: "Hola, #{from}. No te entiendo."
      )
    rescue => e
      @logger.error(e.message)
      @logger.error("Backtrace #{e.backtrace.join("\n\t")}")
    end
  end

  def handle_data(data)
    return if data['message'].nil?

    message = data['message']

    return if message['text'].nil?

    case message['text']

    when %r{^/agregarme}
      add_holder(message)
    when %r{^/quitarme}
      remove_holder(message)
    when %r{^/concursantes}
      show_holders(message)
    when %r{^/sorteo}
      run_raffle(message)
    when %r{^/reset}
      reset_raffle(message)
    when %r{^/start}
      help(message)
    else
      command_not_found_message(message)
    end

  end
end
