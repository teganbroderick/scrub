#!/usr/bin/env ruby 

require 'json'

def main
	sensitive_fields_file = File.read(ARGV[0])
	sensitive_fields_array = []
	sensitive_fields_file.each_line { |line| sensitive_fields_array.append(line.strip) }
	
	user_data = JSON.parse(File.read(ARGV[1])).to_json

	scrubbed_data = scrub(user_data, sensitive_fields_array).to_json

	# To see the output of the code in the terminal, uncomment the line below
	# puts(scrubbed_data)

	#---TESTING---------------------------------------------------------
	# To test, uncomment the line below and pass in the required output.json file as a third command line argument.

	# test_code(scrubbed_data, JSON.parse(File.read(ARGV[2])).to_json)
	#-------------------------------------------------------------------
	
	scrubbed_data
end

def scrub(user_data_json, sensitive_fields_array)
	user_data_hash = JSON.parse(user_data_json)
	scrubbed_data_hash = {}

	user_data_hash.each do |field, value|
		if sensitive_fields_array.include?(field)
			scrubbed_data_hash[field] = evaluate_and_scrub_data(value)
		elsif value.is_a?(Array)
			scrubbed_data_hash[field] = scrub_array(value, sensitive_fields_array)
		elsif value.is_a?(Hash)
			scrubbed_data_hash[field] = scrub(value.to_json, sensitive_fields_array)
		else
			scrubbed_data_hash[field] = value
		end
	end

	return scrubbed_data_hash
end

def evaluate_and_scrub_data(data)
	if data.is_a?(String)
		scrub_string(data)
	elsif data.is_a?(Integer) || data.is_a?(Float)
		scrub_string(data.to_s)	
	elsif data.is_a?(Array)
		scrub_everything_in_array(data)
	elsif data.is_a?(Hash)
		scrub_everything_in_hash(data)
	elsif [true, false].include?(data)
		"-"
	else # covers cases where data == nil or data is another class
		data
	end
end

def scrub_string(input)
	input.gsub(/[A-Za-z0-9]/, "*")
end

def scrub_array(data_array, sensitive_fields_array)
	scrubbed_data_array = []

	data_array.each do |val| 
		if val.is_a?(Array)
			# evaluate each item in the nested array
			scrubbed_data_array.append(evaluate_and_scrub_array_data(val, sensitive_fields_array))
		elsif val.is_a?(Hash)
			# evaluate each item in the hash taking into account whether the key is in the sensitive_fields_array
			scrubbed_data_array.append(scrub(val.to_json, sensitive_fields_array))
		else
			# do not scrub data that is not in a nested array or hash
			scrubbed_data_array.append(val)
		end
	end

	scrubbed_data_array
end

def scrub_everything_in_array(data_array)
	data_array.map { |val| val = evaluate_and_scrub_data(val) }
end

def scrub_everything_in_hash(data_hash)
	scrubbed_data_hash = {}
	data_hash.map { |key, val| scrubbed_data_hash[key] = evaluate_and_scrub_data(val) }
	
	scrubbed_data_hash
end

def test_code(scrubbed_data, expected_output)
	puts("------------------------------------------")
	puts("TEST - COMPARING OUTPUT TO EXPECTED OUTPUT")
	puts("------------------------------------------")

	scrubbed_data == expected_output ? puts("*** Correct output! ***") : puts("*** Incorrect output! ***")
	puts("------------------------------------------")

	puts("Scrubbed data: #{scrubbed_data}")
	puts("Expected ouput: #{expected_output}")
end

main