class Event < Lissio::Model
	property :id, as: Integer, primary: true

	property :opens, as: Time
	property :closes, as: Time

	property :title, as: String
	property :description, as: String
	property :links, as: [Link]
	property :status, as: Symbol

	property :questions, as: [Question]

	property :tickets
	property :orders

	adapter REST

	class People < Lissio::Collection
		class Person < Lissio::Model
			property :name, as: String
			property :confirmed, as: Boolean
		end

		model Person

		adapter REST, endpoint: -> method, id {
			case method
			when :fetch
				"/query/event?q=people&id=#{id}"

			else
				raise NotImplemented
			end
		}
	end
end
