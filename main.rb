require 'tempfile'
require 'pqueue' 
class Transaction
  attr_accessor :timestamp, :transaction_id, :user_id, :amount

  def initialize(timestamp, transaction_id, user_id, amount)
    @timestamp = timestamp
    @transaction_id = transaction_id
    @user_id = user_id
    @amount = amount.to_f
  end
  
  # преобразования обратно в строку для записи в файл
  def to_s
    "#{@timestamp},#{@transaction_id},#{@user_id},#{@amount}"
  end
end

def heap_sort(array)
  n = array.size

  # максимальная куча
  (n / 2 - 1).downto(0) do |i|
    heapify(array, n, i)
  end

  # получаем элементы кучи
  (n - 1).downto(1) do |i|
    array[0], array[i] = array[i], array[0]  # Обмен
    heapify(array, i, 0)
  end

  # инвертируем массив для получения порядка убывания
  array.reverse!
end

def heapify(array, n, i)
  largest = i
  l = 2 * i + 1
  r = 2 * i + 2

  largest = l if l < n && array[l].amount > array[largest].amount
  largest = r if r < n && array[r].amount > array[largest].amount

  if largest != i
    array[i], array[largest] = array[largest], array[i]
    heapify(array, n, largest)
  end
end

# конечный метод
def external_sort(input_file, output_file, chunk_size)
  temp_files = []

  # Фаза 1: чтение и сортировка чанков
  File.open(input_file, 'r') do |file|
    until file.eof?
      transactions = []

      # Читаем чанки по chunk_size строк
      chunk_size.times do
        break if file.eof?
        line = file.readline
        data = line.strip.split(',')
        transaction = Transaction.new(data[0], data[1], data[2], data[3])
        transactions << transaction
      end

      # сортировка транзакций в памяти
      heap_sort(transactions)

      # запись отсортированных транзакций во временный файл
      temp_file = Tempfile.new('sorted_chunk')
      temp_files << temp_file

      transactions.each do |t|
        temp_file.puts t.to_s
      end

      temp_file.rewind
    end
  end

  # Фаза 2: слияние отсортированных чанков
  File.open(output_file, 'w') do |output|
    enumerators = temp_files.map do |temp_file|
      Enumerator.new do |yielder|
        temp_file.each_line do |line|
          data = line.strip.split(',')
          transaction = Transaction.new(data[0], data[1], data[2], data[3])
          yielder.yield transaction
        end
      end
    end

    # используем приоритетную очередь для слияния
    pq = PQueue.new([]) { |a, b| a[:transaction].amount > b[:transaction].amount }

    enumerators.each_with_index do |enum, idx|
      begin
        transaction = enum.next
        pq.push({ transaction: transaction, enumerator: enum })
      rescue StopIteration
      end
    end

    until pq.empty?
      item = pq.pop
      transaction = item[:transaction]
      output.puts transaction.to_s

      begin
        next_transaction = item[:enumerator].next
        pq.push({ transaction: next_transaction, enumerator: item[:enumerator] })
      rescue StopIteration
      end
    end
  end

  # удаление временных temp files
  temp_files.each { |temp_file| temp_file.close; temp_file.unlink }
end