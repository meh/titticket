class Events < Lissio::Collection
	model Event

	adapter REST, endpoint: '/query/event'
end
