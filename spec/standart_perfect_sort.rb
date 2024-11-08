require 'rspec'
require 'tempfile'
require_relative '../main'  # Подключаем ваш основной файл

RSpec.describe 'External Sort' do
  it 'sorts transactions by amount in descending order' do
    # Создаем временный файл с входными данными
    input_file = Tempfile.new('transactions')
    input_file.puts '2023-09-03T12:45:00Z,txn1,user1,100.50'
    input_file.puts '2023-09-03T12:46:00Z,txn2,user2,200.75'
    input_file.puts '2023-09-03T12:47:00Z,txn3,user3,50.25'
    input_file.puts '2023-09-03T12:48:00Z,txn4,user4,150.00'
    input_file.rewind

    # Создаем временный файл для выходных данных
    output_file = Tempfile.new('sorted_transactions')

    # Вызываем функцию external_sort из вашего main.rb
    external_sort(input_file.path, output_file.path, 2)  # Размер чанка 2

    # Проверяем результат
    output_file.rewind
    lines = output_file.readlines.map(&:strip)
    amounts = lines.map { |line| line.split(',')[3].to_f }

    expect(amounts).to eq amounts.sort.reverse

    # Закрываем и удаляем временные файлы
    input_file.close
    input_file.unlink
    output_file.close
    output_file.unlink
  end
end