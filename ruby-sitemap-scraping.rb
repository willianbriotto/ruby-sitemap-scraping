require 'rubygems'
require 'sitemap_generator'
require 'HTTParty'
require 'Nokogiri'
require 'JSON'
require 'optparse'
require 'uri'

CHECK_LIST = []
INVALID_LIST = ["#", "/", "javascript://"]

def scrapy(host)
	page = HTTParty.get(host)
	return Nokogiri::HTML(page)
end

def addInSitemap(urI, quiet)
	if !quiet
		puts "#{urI.scheme}://#{urI.host}#{urI.path}"
	end
	add urI.path, :changefreq => 'daily', :priority => 0.9, :host => "#{urI.scheme}://#{urI.host}"
end

def isSameHost(host, __url)
	__parse = URI.parse(__url)
	if host == __parse.host and !__parse.host.to_s.empty?
		return false
	end
	return true
end

def createSitemap(host, path, recursive, quiet)
	deep = []
	
	parse_page = scrapy("#{host}#{path}");
	hrefs = parse_page.css('a')
	
	hrefs.each do |link|
		if !isSameHost(host, path) or link['href'].nil?
			return
		end
		
		__path = link['href'].sub(host, '') # This get just path
		if !CHECK_LIST.include? "#{__path}"
			__url = __path			
			__parse = URI.parse(__url)
			
			if !__parse.scheme
				__url = "#{host}#{__url}"
				__parse = URI.parse(__url)
			end

			__url = __path			
			__parse = URI.parse(__url)
			
			if !__parse.scheme
				__url = "#{host}#{__url}"
				__parse = URI.parse(__url)
			end
			
			if !__parse.scheme
				return
			end
					
			if __parse.path != '/' and !CHECK_LIST.include? "#{__parse.path}"
				deep.push("#{__parse.path}")
				CHECK_LIST.push("#{__parse.path}")
				
				addInSitemap(__parse, quiet)
			end
		end
	end
	
	deep = deep.uniq
	if deep.length > 0 and recursive
		deep.each do |__in|
			createSitemap(host, __in, recursive)
		end
	end
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: simple_scrapy_sitemap.rb [options]"

  opts.on('-h', '--host HOST', 'Host name') { |v| options[:host] = v }
  opts.on('-p', '--path PATH_TO_SAVE', 'Path to save') { |v| options[:path] = v }
  opts.on('-r', '--recursive', 'Set recursive mode to go associated link') { |v| options[:recursive] = true }
  opts.on('-q', '--quiet', 'No add itens') { |v| options[:quiet] = true }

  opts.on('-H', '--help', 'Usage') do
    puts opts
    exit
  end
end.parse!

raise OptionParser::MissingArgument if options[:host].nil?

SitemapGenerator::Sitemap.default_host = options[:host]
SitemapGenerator::Sitemap.create do
	createSitemap(options[:host], '', options[:recursive], options[:quiet])
end
SitemapGenerator::Sitemap.ping_search_engines