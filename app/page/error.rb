class Page
	class Error < Page
		class Header < Lissio::Component
			on :render do
				$document['header'].remove
			end
		end

		class Content < Lissio::Component
			def initialize(error = nil)
				@error = error
			end

			html do |_|
				if @error
					_.div.alert.critical do
						_.h1 @error.inspect

						@error.backtrace.each {|line|
							_.p line.to_s
						}
					end
				else
					_.mark.secondary "Ah no lo so io come ci sei finito qui."
				end
			end

			css do
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
		end
	end
end
