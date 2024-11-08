require 'rspec'
require 'tempfile'
require_relative '../main'

RSpec.describe 'External Sort' do
  let(:output_file) { Tempfile.new('sorted_transactions') }

  after do
    output_file.close
    output_file.unlink
  end

  it 'sorts transactions by amount in descending order' do
    input_file = Tempfile.new('transactions')
    input_file.puts '2023-09-03T12:45:00Z,txn1,user1,100.50'
    input_file.puts '2023-09-03T12:46:00Z,txn2,user2,200.75'
    input_file.puts '2023-09-03T12:47:00Z,txn3,user3,50.25'
    input_file.puts '2023-09-03T12:48:00Z,txn4,user4,150.00'
    input_file.rewind

    external_sort(input_file.path, output_file.path, 2)

    output_file.rewind
    amounts = output_file.readlines.map { |line| line.split(',')[3].to_f }
    expect(amounts).to eq amounts.sort.reverse

    input_file.close
    input_file.unlink
  end

  it 'handles an empty file correctly' do
    input_file = Tempfile.new('empty_transactions')
    external_sort(input_file.path, output_file.path, 2)
    output_file.rewind
    expect(output_file.read).to be_empty

    input_file.close
    input_file.unlink
  end

  it 'handles transactions with the same amount' do
    input_file = Tempfile.new('same_amount_transactions')
    input_file.puts '2023-09-03T12:45:00Z,txn1,user1,100.50'
    input_file.puts '2023-09-03T12:46:00Z,txn2,user2,100.50'
    input_file.puts '2023-09-03T12:47:00Z,txn3,user3,100.50'
    input_file.rewind
  
    external_sort(input_file.path, output_file.path, 2)
  
    output_file.rewind
    lines = output_file.readlines.map(&:strip)
  
    # Форматируем суммы в строках до двух знаков после запятой
    formatted_lines = lines.map do |line|
      parts = line.split(',')
      parts[3] = format('%.2f', parts[3].to_f)
      parts.join(',')
    end
  
    # Проверка, что все строки присутствуют, независимо от порядка
    expect(formatted_lines).to match_array([
      '2023-09-03T12:45:00Z,txn1,user1,100.50',
      '2023-09-03T12:46:00Z,txn2,user2,100.50',
      '2023-09-03T12:47:00Z,txn3,user3,100.50'
    ])
  
    input_file.close
    input_file.unlink
  end
  it 'handles malformed lines gracefully' do
    input_file = Tempfile.new('malformed_transactions')
    input_file.puts '2023-09-03T12:45:00Z,txn1,user1,100.50'
    input_file.puts 'this is not a valid line'
    input_file.puts '2023-09-03T12:47:00Z,txn3,user3,150.00'
    input_file.rewind

    external_sort(input_file.path, output_file.path, 2)

    output_file.rewind
    amounts = output_file.readlines.map { |line| line.split(',')[3].to_f }
    expect(amounts).to eq amounts.sort.reverse

    input_file.close
    input_file.unlink
  end

  it 'sorts large number of transactions efficiently' do
    input_file = Tempfile.new('large_transactions')
    
    1000.times do |i|
      input_file.puts "2023-09-03T12:45:00Z,txn#{i},user#{i},#{rand(100.0..1000.0).round(2)}"
    end
    input_file.rewind

    external_sort(input_file.path, output_file.path, 100)

    output_file.rewind
    amounts = output_file.readlines.map { |line| line.split(',')[3].to_f }
    expect(amounts).to eq amounts.sort.reverse

    input_file.close
    input_file.unlink
  end
end
