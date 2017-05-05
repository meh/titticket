class Ticket < Lissio::Model
	property :id, as: Integer, primary: true
	property :event, as: Integer

	property :opens, as: Time
	property :closes, as: Time

	property :title, as: String
	property :description, as: String
	property :status, as: Symbol

	property :amount, as: Amount
	property :payment, as: [Payment]
	property :questions, as: [Question]

	adapter REST
end
