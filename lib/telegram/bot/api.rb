module Telegram
  module Bot
    class Api
      ENDPOINTS = %w(
        getUpdates setWebhook deleteWebhook getWebhookInfo getMe sendMessage
        forwardMessage sendPhoto sendAudio sendDocument sendSticker sendVideo
        sendVoice sendVideoNote sendLocation sendVenue sendContact
        sendChatAction getUserProfilePhotos getFile kickChatMember
        unbanChatMember leaveChat getChat getChatAdministrators
        getChatMembersCount getChatMember answerCallbackQuery editMessageText
        editMessageCaption editMessageReplyMarkup deleteMessage
        answerInlineQuery sendInvoice answerShippingQuery answerPreCheckoutQuery
        sendGame setGameScore getGameHighScores
      ).freeze

      attr_reader :token

      def initialize(token)
        @token = token
      end

      def method_missing(method_name, *args, &block)
        endpoint = method_name.to_s
        endpoint = camelize(endpoint) if endpoint.include?('_')

        ENDPOINTS.include?(endpoint) ? call(endpoint, *args) : super
      end

      def respond_to_missing?(*args)
        method_name = args[0].to_s
        method_name = camelize(method_name) if method_name.include?('_')

        ENDPOINTS.include?(method_name) || super
      end

      def call(endpoint, raw_params = {})
        params = serialize_params(raw_params)
        response = conn.post("/bot#{token}/#{endpoint}", params)
        if response.status == 200
          JSON.parse(response.body)
        else
          raise Exceptions::ResponseError.new(response),
                'Telegram API has returned the error.'
        end
      end

      private

      def serialize_params(h)
        h.each_with_object({}) do |(key, value), params|
          params[key] =
            if value.is_a?(Array)
              value.map { |v| serialize_value(v) }
            else
              serialize_value(value)
            end
        end
      end

      def serialize_value(value)
        if value.is_a?(Types::Base)
          value.to_compact_hash
        else
          value
        end
      end

      def camelize(method_name)
        words = method_name.split('_')
        words.drop(1).map(&:capitalize!)
        words.join
      end

      def conn
        @conn ||= Faraday.new(url: 'https://api.telegram.org') do |faraday|
          faraday.request :multipart
          faraday.request :json
          faraday.adapter Telegram::Bot.configuration.adapter
        end
      end
    end
  end
end
