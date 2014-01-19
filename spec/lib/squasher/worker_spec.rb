require 'spec_helper'
require 'tempfile'

describe Squasher::Worker do
  context 'failed on #check!' do
    let(:worker) { described_class.new(Time.new(2012, 6, 20)) }

    it 'command was run not in application root' do
      Squasher::Config.any_instance.stub(:migrations_folder? => false)

      expect_exit_with(:migration_folder_missing)
    end

    it 'db configuration is invalid' do
      Squasher::Config.any_instance.stub(:dbconfig? => false)

      expect_exit_with(:dbconfig_invalid)
    end

    it 'matched migrations was not found' do
      expect_exit_with(:no_migrations, :date => "2012/06/20")
    end

    def expect_exit_with(*args)
      expect(Squasher).to receive(:error).with(*args).and_call_original
      expect { worker.process }.to raise_error(SystemExit)
    end
  end

  it 'create a new squashed migration & remove selected migrations' do
    worker = described_class.new(Time.new(2014))
    worker.stub(:under_squash_env).and_yield.and_return(true)
    new_migration_path = File.join(Dir.tmpdir, 'init_schema.rb')
    Squasher::Config.any_instance.stub(:migration_file).with('2013122900', :init_schema).and_return(new_migration_path)

    FileUtils.should_receive(:rm).with(File.join(fake_root, 'db', 'migrate', '201312090000_first_migration.rb'))
    FileUtils.should_receive(:rm).with(File.join(fake_root, 'db', 'migrate', '2013122900_second_migration.rb'))
    Squasher.should_receive(:ask).with(:keep_database).and_return(false)
    Squasher.should_receive(:rake).with("db:drop")
    Squasher.should_receive(:ask).with(:apply_clean).and_return(true)
    Squasher.should_receive(:clean)

    worker.process

    expect(File.exists?(new_migration_path)).to be_true
    File.open(new_migration_path) do |stream|
      content = stream.read
      expect(content).to include("InitSchema")
      expect(content).to include('create_table "managers", :force => true do |t|')
    end
  end
end
