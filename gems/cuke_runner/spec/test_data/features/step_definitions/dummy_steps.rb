When(/^I run a test that passes$/) do
end

When(/^I run a test that fails$/) do
end

Then(/^There will be a zero return code$/) do
end

Then(/^There will be a non-zero return code$/) do
  raise("I'm failing your test!!!")
end