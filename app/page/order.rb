class Page
	class Order < Page
		class Header < Lissio::Component
			on :render do
				$document['header'].remove
			end
		end

		SimpleMessage = proc do
			height 100.vh
			display :flex
			align items: :center
			justify content: :center

			rule 'mark' do
				font size: 2.em,
				     weight: :bold

				text align: :center
			end
		end

		class Success < Order
			class Content < Lissio::Component
				def initialize(order)
					@order = order
				end

				html do |_|
					_.mark.tertiary "Il tuo ordine è andato a buon fine."
				end

				css(&SimpleMessage)
			end
		end

		class Failure < Order
			class Content < Lissio::Component
				html do |_|
					_.mark.secondary "Il tuo ordine è fallito, assicurati che i dati siano corretti e ci siano abbastanza fondi."
				end

				css(&SimpleMessage)
			end
		end

		class Cancel < Order
			class Content < Lissio::Component
				html do |_|
					_.mark.primary "Il tuo ordine è stato annullato."
				end

				css(&SimpleMessage)
			end
		end
	end
end
