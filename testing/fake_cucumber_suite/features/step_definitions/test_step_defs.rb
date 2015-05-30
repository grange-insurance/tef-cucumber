And(/^echo "([^"]*)"$/) do |message|
  system("echo #{message}")
end

And(/^explode$/) do
  raise('Boom!!!')
end
