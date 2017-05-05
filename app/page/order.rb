class Page
	module Order
		class Success < Page
			Header = Page::Header::None

			class Content < Lissio::Component
				def initialize(order)
					@order = order
				end

				html do |_|
					_.h1.style('text-align' => :center) do
						_.mark.tertiary "si ok"
						_.small do
							_.br
							_ << "#{@order.id}"
						end
					end


	#				_.div.purchases do
	#					order.purchases.each do |purchase|
	#						_.div.card.fluid.purchase
	#					end
	#				end
				end
			end
		end

		class Failure < Page
			Header = Page::Header::None

			class Content < Lissio::Component
				def initialize(order)
					@order = order
				end

				html do |_|
					_.h1.style('text-align' => :center) do
						_.mark.secondary "no ok"
						_.small do
							_.br
							_ << "#{@order.id}"
						end
					end

	#				_.div.purchases do
	#					order.purchases.each do |purchase|
	#						_.div.card.fluid.purchase
	#					end
	#				end
				end
			end
		end

		class Cancel < Page
			Header = Page::Header::None

			class Content < Lissio::Component
				def initialize(order)
					@order = order
				end

				html do |_|
					_.h1.style('text-align' => :center) do
						_.mark.primary "ah ok"
						_.small do
							_.br
							_ << "#{@order.id}"
						end
					end

	#				_.div.purchases do
	#					order.purchases.each do |purchase|
	#						_.div.card.fluid.purchase
	#					end
	#				end
				end
			end
		end
	end
end
