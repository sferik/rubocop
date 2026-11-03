require "csv"
module Reports
  class SalesReport
    attr_reader :rows,:options
    def initialize(rows, options={})
      @rows=rows
      @options = {:format => "csv", :title => "Sales", :currency => "USD"}.merge(options)
    end

    def generate()
      if options[:format] == "csv" then
        to_csv
      else
        if options[:format] == "text"
          to_text
        else
          raise ArgumentError.new("unknown format: " + options[:format].to_s)
        end
      end
    end

    def to_csv
      CSV.generate do |csv|
        csv << ["Region","Product","Units","Revenue"]
        rows.each { |row|
          csv << [ row[:region], row[:product], row[:units], format_money(row[:revenue]) ]
        }
      end
    end

    def to_text
      lines = []
      lines << "#{options[:title]} report"
      lines << "=" * 40
      rows.each do |row|
          lines << "%-10s %-15s %5d %12s" % [row[:region], row[:product], row[:units], format_money(row[:revenue])]
      end
      lines << "Total: " + format_money(total_revenue)
      return lines.join("\n")
    end

    def total_revenue
      rows.inject(0) { |sum, row| sum + row[:revenue] }
    end

    def top_products(n = 3)
      totals = Hash.new(0)
      rows.each do |row| totals[row[:product]] += row[:revenue] end
      totals.sort_by { |product, revenue| -revenue }.first(n).map { |product, revenue| product }
    end

    def regions
      rows.map { |row| row[:region] }.uniq.sort()
    end

    def by_region(region)
      rows.select { |row| row[:region] == region and row[:units] > 0 }
    end

    def empty?
      !(rows.size > 0)
    end

    def format_money(amount)
      unless amount.nil?
        sprintf("%s %.2f", options[:currency], amount)
      else
        "n/a"
      end
    end

    def growth(previous)
      return nil if previous == nil
      return 0.0 if previous.total_revenue == 0
      ((total_revenue - previous.total_revenue) / previous.total_revenue.to_f * 100).round(1)
    end

    def summary
      { :regions => regions.length, :products => rows.map { |r| r[:product] }.uniq.length, :revenue => total_revenue, :top => top_products }
    end

    def self.load(path)
      new(CSV.read(path, :headers => true).map { |r| { :region => r["Region"], :product => r["Product"], :units => r["Units"].to_i, :revenue => r["Revenue"].to_f } })
    end
  end
end
