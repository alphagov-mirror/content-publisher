# frozen_string_literal: true

class EmailDeliveryJob < ActionMailer::DeliveryJob
  # retry at 3s, 18s, 83s, 258s, 627s
  retry_on(Notifications::Client::RequestError,
           wait: :exponentially_longer,
           attempts: 1)

  def perform(mailer, mail_method, delivery_method, *args)
    response_error = OpenStruct.new(
      code: "501",
      body: {
        errors: [
          {
            error: "Testing Content Publisher error handling",
            message: "Testing Content Publisher error handling"
          }
        ]
      }.to_json
    )

    raise Notifications::Client::RequestError, response_error
  end
end
