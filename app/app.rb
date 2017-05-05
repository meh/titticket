require 'opal'
require 'time'

require 'browser'
require 'browser/effects'
require 'browser/console'

require 'lissio'
require 'lissio/adapter/storage'

require 'helpers'
require 'components'
require 'models'
require 'pages'

class Boobing < Lissio::Application
	def initialize
		super

		route '/' do
			loading!

			Events.fetch.then {|events|
				load Page::Index.new(events)
			}
		end

		route '/italian-embassy-2017' do
			router.match '/event/1'
		end

		route '/event/:id' do |params|
			loading!

			Event.fetch(params[:id].to_i).then {|event|
				Promise.when(*event.tickets.map { |id| Ticket.fetch(id) })
			}.trace { |event, tickets|
				load Page::Event.new(event, tickets)
			}
		end

		route '/ticket/:id' do |params|
			Ticket.fetch(params[:id].to_i).then {|ticket|
				element.content = ticket.inspect
			}
		end

		route '/order/:id/success' do |params|
			Order.fetch(params[:id]).then {|order|
				load Page::Order::Success.new(order)
			}
		end

		route '/order/:id/failure' do |params|
			Order.fetch(params[:id]).then {|order|
				load Page::Order::Failure.new(order)
			}
		end

		route '/order/:id/cancel' do |params|
			Order.fetch(params[:id]).then {|order|
				load Page::Order::Cancel.new(order)
			}
		end
	end

	def loading!
		element.at_css('.container').tap {|container|
			container.inner_dom = Component::Loader.new.render
		}
	end

	def load(component)
		@current.trigger! 'page:unload' if @current
		@current = component

		element.at_css('header').tap {|header|
			header.inner_dom = @current.header.render
			header.show
		}

		element.at_css('.container').tap {|container|
			container.inner_dom = @current.content.render
		}

		@current.trigger! 'page:load'
	end

	html do
		header.sticky

		div.container

#		footer.sticky do
#			span "Sponsored by Faffanifaffofa Foffina."
#		end
	end

	css do
		rule 'header' do
			display :none
		end

		rule '.container' do
			max width: 1280.px
		end
	end
end
