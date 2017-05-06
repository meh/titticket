class Page
	class Event < Page
		class Header < Lissio::Component
			def initialize(event, tickets)
				@event   = event
				@tickets = tickets
			end

			on :click, '.button' do |e|
				# TODO: scroll to ticket
			end

			html do |_|
				_.a.logo.href("/").text("Italian Grappa")

				@tickets.each do |ticket|
					_.a.button.text(ticket.title).data(id: ticket.id)
				end
			end
		end

		class Content < Lissio::Component
			def initialize(event, tickets)
				@event    = event
				@general  = Form::General.new(event)

				@tickets  = Hash[tickets.map { |t| [t.id, t] }]
				@forms    = Hash.new
				@checkout = Checkout.new(@event, @general, @tickets)
			end

			on :click, '.ticket .heading' do |e|
				element = e.on.ancestors('.ticket').first
				button  = element.at_css('button.buy')
				ticket  = @tickets[element.data[:id].to_i]

				if element.class_names.include? :active
					element.remove_class :active
					button.remove_class :tertiary

					@forms.delete(ticket.id).element.remove
				else
					element.add_class :active
					button.add_class :tertiary

					@forms[ticket.id] = Form.new(ticket)

					unless ticket.questions.empty?
						element.add_child @forms[ticket.id].render
					end
				end

				@checkout.update(@forms)
			end

			on :input, 'input' do
				@checkout.update(@forms)
			end

			on :change, 'input' do
				@checkout.update(@forms)
			end

			html do |_|
				_.div.card.fluid.inverse.information do
					_.div.section do
						_.div.heading do
							_.h1 @event.title

							_.div.dates do
								_.span "Dal "
								_.strong @event.opens.strftime "%-e/%m/%Y"

								if @event.closes
									_.span " al "
									_.strong @event.closes.strftime "%-e/%m/%Y"
								end
							end
						end
					end

					_.div.section do
						_.div.description do
							`marked(#{@event.description})`
						end
					end
				end

				_.div.tickets do
					@tickets.each_value do |ticket|
						_.div.card.fluid.ticket.data(id: ticket.id) do
							_.div.section do
								_.div.heading do
									_.h4 do
										_ << ticket.title

										if ticket.description
											_.small ticket.description
										end
									end

									if payment = ticket.payment.find { |p| p.type == :paypal }
										if beyond = payment.price!.beyond!
											_.div.price do
												_.strong "#{payment.price!.value}€"
												_.span " fino al "
												_.strong "#{beyond.date.strftime "%-e/%m/%Y"}"
												_.span " poi "
												_.strong "#{beyond.value}€"
											end
										else
											_.div.price do
												_.strong "#{payment.price!.value}€"
											end
										end
									end

									_.button.buy do
										_.i.fa.fa[:shopping, :cart].fa[:lg]
									end
								end
							end
						end
					end
				end

				_.div.card.fluid.inverse do
					_.div.section do
						_ << @general
					end
				end

				_ << @checkout
			end

			css do
				rule '.heading' do
					display :flex
					align items: :center

					rule 'h1', 'h2', 'h3', 'h4' do
						flex grow: 1
						margin top:    0,
						       bottom: 0
					end
				end

				rule '.information' do
					rule '.description' do
						padding 1.em, 0.5.em
					end
				end

				rule '.ticket' do
					rule '.heading' do
						rule '.buy' do
							margin left: 1.em
						end
					end
				end
			end

			class Checkout < Lissio::Component
				def initialize(event, general, tickets, forms = {})
					@event   = event
					@general = general

					@tickets = tickets
					@forms   = forms
				end

				# TODO: Only render when there were actual changes.
				def update(forms)
					@forms = forms
					render
				end

				def types
					@tickets.values.flat_map { |t| t.payment.map { |p| p.type } }.uniq
				end

				def type!(name)
					case name
					when :wire
						"Bonifico"

					when :cash
						"Contante"

					when :paypal
						"PayPal"
					end
				end

				def price(type)
					return if @forms.empty?

					@forms.values.map {|form|
						return unless payment = form.item.payment.find { |p| p.type == type }

						if payment.price!.beyond! && payment.price!.beyond!.date < Time.now
							payment.price!.beyond!.value
						else
							payment.price!.value
						end
					}.reduce(0, :+).round(2)
				end

				# FIXME: This will explode with required nested questions.
				def valid?
					@forms.each_value {|form|
						form.questions.each {|question|
							return false unless validate(question)
						}
					}

					return false unless @general.identifier
					return false unless @general.email

					@general.questions.each {|question|
						return false unless validate(question)
					}

					true
				end

				def validate(question)
					question.children.all? { |q| validate(q) } &&
						(!question.required || !question.value.nil?)
				end

				on :click, 'button' do |e|
					return unless valid?

					data = {
						event:   @event.id,
						payment: { type: e.on.data[:type] },

						identifier: @general.identifier,
						email:      @general.email,
						answers:    @general.questions.select(&:value).map { |question|
							{ id: question.id, value: question.value }
						},

						tickets: @forms.values.map {|form|
							{ id:      form.item.id,
								answers: form.questions.select(&:value).map { |question|
									{ id: question.id, value: question.value }
								} }
						}
					}

					Browser::HTTP.post("#{REST::URL}/v1/order", JSON.dump(data)) {
						content_type "application/json"
					}.then {|res|
						data  = res.json
						order = data[:id]

						if action = data[:action]
							if to = action[:redirect]
								$window.location.uri = to
								next
							end
						end

						Boobing.navigate "/order/#{order}/success"
					}
				end

				html do |_|
					types.each do |type|
						if value = price(type)
							# TODO: remove this once it's implemented
							if type == :wire
								_.button.disabled!.data(type: type) do
									_ << "Paga con #{type!(type)} "
									_.strong "#{value}€"
								end
							elsif valid?
								_.button.tertiary.data(type: type) do
									_ << "Paga con #{type!(type)} "
									_.strong "#{value}€"
								end
							else
								_.button.secondary.data(type: type) do
									_ << "Paga con #{type!(type)} "
									_.strong "#{value}€"
								end
							end
						else
							_.button.disabled!.data(type: type) do
								_ << "Paga con #{type!(type)} "
								_.strong "0€"
							end
						end
					end
				end
			end

			class Form < Lissio::Component
				attr_reader :item, :questions

				def initialize(item)
					@item      = item
					@questions = item.questions.map { |q| Question.new(q) }
				end

				tag class: [:section, :form]

				html do |_|
					@questions.each do |question|
						_ << question
					end
				end

				css do
					rule 'input[type="text"]', 'input[type="email"]' do
						display :block
					end

					rule 'label[data-required="true"]::after' do
						content '"*"'
						margin left: 0.5.em
					end

					rule '& > .question' do
						margin bottom: 1.em
					end
				end

				class General < self
					def identifier
						element.at_css('input#identifier').value.trim
					end

					def email
						if element.at_css('input#email').to_n.JS['validity'].JS['valid']
							element.at_css('input#email').value.trim
						end
					end

					on :render do
						element >> DOM { |_|
							_.div.question do
								_.label.for(:identifier).text("Nome o Nick").data(required: true)
								_.input.identifier!.type(:text)
							end
						}

						element >> DOM { |_|
							_.div.question do
								_.label.for(:email).text("E-Mail").data(required: true)
								_.input.email!.type(:email)
							end
						}
					end
				end

				class Question < Lissio::Component
					attr_reader :parent, :inner, :children

					def initialize(inner, parent = nil)
						@parent   = parent
						@inner    = inner
						@children = inner.children.map { |q| Question.new(q, self) }
					end

					def method_missing(*args, &block)
						@inner.__send__(*args, &block)
					end

					def value
						case @inner.type
						when :bool
							element.at_css('input').checked?

						when :one
							if question = @children.find { |q| q.value }
								question.id
							end

						when :many
							@children.select(&:value).map(&:id)

						when :text
							element.at_css('input').value.trim
						end
					end

					tag class: :question

					html do |_|
						case @inner.type
						when :bool
							case @parent.inner.type
							when :many
								_.input(id: @inner.id).type(:checkbox).tab_index(0)
								_.label.for(@inner.id).text(@inner.title).data(required: @inner.required)

							when :one
								_.input(id: @inner.id).type(:radio).tab_index(0).name(@parent.inner.id)
								_.label.for(@inner.id).text(@inner.title).data(required: @inner.required)
							end

						when :text
							_.label.for(@inner.id).text(@inner.title).data(required: @inner.required)
							_.input(id: @inner.id).type(:text).tab_index(0)

						else
							_.label.text(@inner.title).data(required: @inner.required)
						end

						unless @children.empty?
							_.div.input[:group].children do
								@children.each {|question|
									_ << question
								}
							end
						end
					end

					css do
						rule 'label[data-required="true"]' do
							font weight: :bold
						end

						rule '.children' do
							display :block
							margin left: 1.em,
							       bottom: 1.em
						end
					end
				end
			end
		end

		class People < Page
			Header = Event::Header

			class Content < Lissio::Component
				def initialize(event, tickets, people)
					@people = people
				end

				html do |_|
					@people.each_slice(6) do |people|
						_.div.row do
							people.each do |name|
								_.div.col[:sm, "3"].do {
									_.div.card.fluid do
										_.div.section name
									end
								}
							end
						end
					end
				end
			end
		end
	end
end
