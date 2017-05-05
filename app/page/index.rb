class Page
	class Index < Page
		class Header < Lissio::Component
			def initialize(events)
				@events = events
			end

			html do |_|
				_.a.logo.href('/').text("Italian Grappa")

				@events.each do |event|
					_.a.button.href("/event/#{event.id}").text(event.title)
				end
			end
		end

		class Content < Lissio::Component::Markdown
			def initialize(*)
				super()
			end

			content <<-MD.gsub(/^\t{4}/m, '')
				Fuffa
				=====
			MD
		end
	end
end
