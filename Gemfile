source 'https://rubygems.org'
gemspec
gem "rake"
group :dev do
  gem 'rubygems-tasks'
end
group :dev, :test do
  gem 'pry'
end
group :test do
  gem 'minitest', '~> 5.4', require: ['minitest', 'minitest/spec']
end
