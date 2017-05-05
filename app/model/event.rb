class Event < Lissio::Model
	property :id, as: Integer, primary: true

	property :opens, as: Time
	property :closes, as: Time

	property :title, as: String
	property :description, as: String
	property :status, as: Symbol

	property :questions, as: [Question]

	property :tickets
	property :orders

	adapter REST
end
