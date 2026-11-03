# frozen_string_literal: true

require 'json'
require 'time'

module Warehouse
  # Keeps track of the items in stock, their reservations and their
  # movements between locations.
  class Inventory
    include Enumerable

    LOW_STOCK_THRESHOLD = 5
    LOCATIONS = %w[north south east west].freeze
    DEFAULT_OPTIONS = { strict: false, currency: 'USD', round_to: 2 }.freeze

    Item = Struct.new(:sku, :name, :price, :quantity, :location, keyword_init: true) do
      def total
        price * quantity
      end

      def low_stock?
        quantity < LOW_STOCK_THRESHOLD
      end
    end

    class OutOfStock < StandardError
      def initialize(sku, requested, available)
        super("#{sku}: requested #{requested}, only #{available} available")
      end
    end

    attr_reader :items, :options

    def initialize(items = [], **options)
      @items = items.to_h { |item| [item.sku, item] }
      @options = DEFAULT_OPTIONS.merge(options)
      @reservations = Hash.new(0)
      @log = []
    end

    def each(&block)
      return enum_for(:each) unless block

      @items.each_value(&block)
    end

    def add(sku:, name:, price:, quantity: 1, location: LOCATIONS.first)
      raise ArgumentError, "unknown location: #{location}" unless LOCATIONS.include?(location)

      if (item = @items[sku])
        item.quantity += quantity
      else
        @items[sku] = Item.new(sku: sku, name: name, price: price, quantity: quantity,
                               location: location)
      end
      record(:add, sku, quantity)
      self
    end

    def reserve(sku, quantity)
      item = @items.fetch(sku) { raise KeyError, "no such item: #{sku}" }
      available = item.quantity - @reservations[sku]
      if quantity > available
        raise OutOfStock.new(sku, quantity, available) if options[:strict]

        quantity = available
      end

      @reservations[sku] += quantity
      record(:reserve, sku, quantity)
      quantity
    end

    def release(sku, quantity = nil)
      reserved = @reservations[sku]
      quantity = reserved if quantity.nil? || quantity > reserved
      @reservations[sku] -= quantity
      @reservations.delete(sku) if @reservations[sku].zero?
      record(:release, sku, quantity)
    end

    def move(sku, to:)
      item = @items.fetch(sku)
      return false if item.location == to

      from = item.location
      item.location = to
      record(:move, sku, item.quantity, from: from, to: to)
      true
    end

    def value(location: nil)
      selected = location ? select { |item| item.location == location } : to_a
      selected.sum(&:total).round(options[:round_to])
    end

    def low_stock
      select(&:low_stock?).sort_by { |item| [item.quantity, item.sku] }
    end

    def by_location
      group_by(&:location).transform_values do |items|
        items.map(&:sku).sort
      end
    end

    def search(query)
      pattern = Regexp.new(Regexp.escape(query), Regexp::IGNORECASE)
      select { |item| item.name.match?(pattern) || item.sku.start_with?(query.upcase) }
    end

    def price_band(item)
      case item.price
      when 0...10 then :budget
      when 10...100 then :standard
      when 100...1000 then :premium
      else :luxury
      end
    end

    def summary
      lines = map do |item|
        format('%<sku>-10s %<name>-24s %<quantity>5d %<total>10.2f',
               sku: item.sku, name: item.name, quantity: item.quantity, total: item.total)
      end
      <<~SUMMARY
        Inventory (#{count} items, #{options[:currency]} #{value})
        #{lines.join("\n")}
      SUMMARY
    end

    def to_json(*args)
      {
        items: map(&:to_h),
        reservations: @reservations,
        generated_at: Time.at(0).utc.iso8601
      }.to_json(*args)
    end

    def self.from_json(json, **options)
      data = JSON.parse(json, symbolize_names: true)
      items = data.fetch(:items, []).map { |attributes| Item.new(**attributes) }
      new(items, **options).tap do |inventory|
        data.fetch(:reservations, {}).each do |sku, quantity|
          inventory.reserve(sku.to_s, quantity)
        end
      end
    rescue JSON::ParserError => e
      raise ArgumentError, "invalid inventory: #{e.message}"
    end

    def history(since: nil, kind: nil)
      @log.select do |entry|
        next false if since && entry[:at] < since
        next false if kind && entry[:kind] != kind

        true
      end
    end

    private

    def record(kind, sku, quantity, **details)
      @log << { kind: kind, sku: sku, quantity: quantity, at: @log.size, **details }
    end
  end

  # Applies discounts to the items of an inventory.
  class Pricing
    RULES = {
      bulk: ->(item) { item.quantity >= 100 ? 0.1 : 0 },
      clearance: ->(item) { item.low_stock? ? 0.25 : 0 }
    }.freeze

    def initialize(inventory, rules: RULES.keys)
      @inventory = inventory
      @rules = rules.map { |name| RULES.fetch(name) }
    end

    def discounted_price(item)
      discount = @rules.map { |rule| rule.call(item) }.max || 0
      (item.price * (1 - discount)).round(2)
    end

    def price_list
      @inventory.each_with_object({}) do |item, list|
        list[item.sku] = discounted_price(item)
      end
    end
  end
end
