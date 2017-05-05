class Purchase < Lissio::Model
	property :ticket, as: Ticket
	property :total, as: Float
	property :answers, as: { String => Answer }
end
