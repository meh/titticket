class Page
	class Order < Page
		def self.load(id)
			::Order.fetch(id)
		end

		SimpleMessage = proc do
			height 100.vh
			display :flex
			align items: :center
			justify content: :center

			rule '.card' do
				font size: 2.em,
				     weight: :bold

				text align: :center
			end
		end

		class Header < Lissio::Component
			on :render do
				$document['header'].remove
			end
		end

		class Content < Lissio::Component
			def initialize(order, success = false)
				@order = order
			end

			html do |_|
				_.div.card.large.success do
					_.div.section do
						_ << "Il tuo ordine è andato a buon fine."
					end
				end
			end

			css(&SimpleMessage)
		end

		class Failure < Order
			class Content < Lissio::Component
				html do |_|
					_.div.card.large.error do
						_.div.section do
							_ << "Il tuo ordine è fallito, assicurati che i dati siano corretti e ci siano abbastanza fondi."
						end
					end
				end

				css(&SimpleMessage)
			end
		end

		class Cancel < Order
			class Content < Lissio::Component
				html do |_|
					_.div.card.large.warning do
						_.div.section do
							_ << "Il tuo ordine è stato annullato."
						end
					end
				end

				css(&SimpleMessage)
			end
		end
	end
end
