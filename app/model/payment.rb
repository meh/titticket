class Payment < Lissio::Model
	class Price < Lissio::Model
		class Beyond < Lissio::Model
			property :value, as: Float
			property :date, as: Time
		end

		property :value, as: Float
		property :beyond, as: Beyond
	end

	property :type
	property :price, as: Price
end
