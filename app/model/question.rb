class Question < Lissio::Model
	property :id, as: String
	property :type, as: Symbol

	property :required, as: Boolean
	property :title, as: String
	property :price, as: Float

	property :amount, as: Amount
	property :purchased, as: Integer

	property :children, as: [Question]
end
