require 'spec_helper'

describe Squasher::Config do
  let(:config)    { described_class.new }

  context '.dbconfig?' do
    subject(:result) { config.dbconfig? }

    it 'a file is exists and it has a valid content' do
      expect(result).to be_truthy
    end

    it 'a file is exists but doesnt have a valid content' do
      allow(config).to receive(:dbconfig_file).and_return(File.join(fake_root, 'config', 'invalid_database.yml'))

      expect(result).to be_falsey
    end

    it 'a file is not exists' do
      allow(config).to receive(:dbconfig_file).and_return(File.join(fake_root, 'config', 'not_existed.yml'))

      expect(result).to be_falsey
    end
  end

  context '#stub_dbconfig' do
    it 'add required db config file' do
      config.stub_dbconfig do
        File.open(File.join(fake_root, 'config', 'database.yml')) do |stream|
          content = YAML.load(stream.read)
          expect(content["development"]["database"]).to eq("squasher")
          expect(content["development"]["encoding"]).to eq("utf-8")
          expect(content["another_development"]["database"]).to eq("squasher")
          expect(content["another_development"]["encoding"]).to eq("utf-8")
        end
      end
    end

    it 'recover original schema and db config files if some error raised' do
      begin
        config.stub_dbconfig do
          expect(file_exists?('config', 'database.yml')).to be_truthy
          expect(file_exists?('config', 'database.yml.sq')).to be_truthy

          raise RuntimeError, "Unexpected system error"
        end
      rescue RuntimeError
        expect(file_exists?('config', 'database.yml')).to be_truthy
        expect(file_exists?('config', 'database.yml.sq')).to be_falsey
      end
    end

    def file_exists?(*parts)
      File.exists?(File.join(fake_root, *parts))
    end
  end

  specify { expect(config.migration_file(1230, :sample)).to eq(File.join(fake_root, 'db', 'migrate', '1230_sample.rb')) }
end
