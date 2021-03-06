# Sample usage
# cd to book folder
# ruby feed-seeder.rb && dropcaster > index.rss && aws s3 sync . "s3://audiobooks-rss/My Book Name" --acl public-read

require 'colorize'
require 'optparse'

DEFAULT_PATH = "."

def write_to_file(path, string)
	File.write(path, string)
end

def read_arguments
	arguments = {
		path: DEFAULT_PATH,
    description: "Books are cool",
    image_url: "https://pbs.twimg.com/profile_images/378800000448533787/c32fb13e160ee7cd17848e8cacbbcfc5_400x400.jpeg",
	}

	OptionParser.new do |opts|
	  opts.banner = "Usage: example.rb [options]"

	  opts.on("-d", "--description DESCRIPTION", "An optional description for the book")  { |n| arguments[:description] = n }

	  opts.on("-i", "--image IMAGE", "An optional image url for the book") { |n| arguments[:image_url] = n }

    opts.on("-p", "--path PATH", "The path of the folder to create a feed of")         { |n| args[:path] = n }

	  opts.on("-h", "--help", "Prints this help") do
	    puts opts
	    exit
	  end
	end.parse!

	arguments
end

def format_title(title, separator)
	title.gsub(/\b('?[a-z])/) { $1.capitalize }
		.split(" ")
		.join(separator)
end

def generate_url(title, file_format, suffix)
  domain = "https://s3.amazonaws.com"
  bucket = "audiobooks-rss"

 	formatted_title = format_title(title, "+")
  folder = formatted_title
  path = "#{formatted_title}-#{suffix}.mp3"

  [domain, bucket, folder, path].join("/")
end

def generate_template(title, file_url, image_url, description)
return %Q(
:title: '#{title}'

:subtitle: 'Subtitles are useful'

:url: '#{file_url}'

:language: 'en-us'

:copyright: '© mergesort'

:author: 'NYPL Books'

# iTunes prefers square .jpg images that are at least 600 x 600 pixels
#
# If the URL does not start with http: or https:, it will be prefixed with the channel url.
#
:image_url: '#{image_url}'

:description: '#{description}'

:owner:
:name: 'Joe Fabisevich'
:email: 'ireadeveryemail@fabisevi.ch'


:categories: ['Education']

:explicit: No

# Keywords
#
# Apple recommends to use not more than 12 keywords
#
:keywords: []
)
end

# Run app

def start
	begin
		puts "Enter a title:".green
	  title = STDIN.gets.chomp
	end while title.to_s.empty?

	puts "Enter file format (optional):".blue
	file_format = STDIN.gets.chomp

	begin
		puts "Enter a suffix:".green
		suffix = STDIN.gets.chomp
	end while suffix.to_s.empty?

	arguments = read_arguments

	description = arguments[:description]
	image_url = arguments[:image_url]
	path = arguments[:path]
	formatted_title = format_title(title, " ")

	# If the user skips specifying a file format, use the formatted_title instead
	if file_format.to_s.empty?
		file_format = formatted_title
	end

	url = generate_url(title, file_format, suffix)

	channel_yml = generate_template(formatted_title, url, image_url, description)
	write_to_file("#{path}/channel.yml", channel_yml)
end

start
