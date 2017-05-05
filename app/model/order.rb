class Order < Lissio::Model
	property :id, as: String, primary: true
	property :event, as: Integer

	property :total, as: Float
	property :identifier, as: String
	property :email, as: String
	property :private, as: Boolean
	property :confirmed, as: Boolean

	property :answers, as: { String => Answer }

	property :purchases, as: [Purchase]

	adapter REST
end
