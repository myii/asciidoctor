# encoding: UTF-8
unless defined? ASCIIDOCTOR_PROJECT_DIR
  $: << File.dirname(__FILE__); $:.uniq!
  require 'test_helper'
end

context 'Logger' do
  MyLogger = Class.new Logger

  context 'LoggerManager' do
    test 'provides access to logger via static logger method' do
      logger = Asciidoctor::LoggerManager.logger
      refute_nil logger
      assert_kind_of Logger, logger
    end

    test 'allows logger instance to be changed' do
      class MyLoggerA < Logger; end
      old_logger = Asciidoctor::LoggerManager.logger
      new_logger = MyLoggerA.new $stdout
      begin
        Asciidoctor::LoggerManager.logger = new_logger
        assert_same new_logger, Asciidoctor::LoggerManager.logger
      ensure
        Asciidoctor::LoggerManager.logger = old_logger
      end
    end

    test 'setting logger instance to falsy value resets instance to default logger' do
      class MyLoggerB < Logger; end
      old_logger = Asciidoctor::LoggerManager.logger
      begin
        Asciidoctor::LoggerManager.logger = MyLoggerB.new $stdout
        Asciidoctor::LoggerManager.logger = nil
        refute_nil Asciidoctor::LoggerManager.logger
        assert_kind_of Logger, Asciidoctor::LoggerManager.logger
      ensure
        Asciidoctor::LoggerManager.logger = old_logger
      end
    end

    test 'creates logger instance from static logger_class property' do
      class MyLoggerC < Logger; end
      old_logger_class = Asciidoctor::LoggerManager.logger_class
      old_logger = Asciidoctor::LoggerManager.logger
      begin
        Asciidoctor::LoggerManager.logger_class = MyLoggerC
        Asciidoctor::LoggerManager.logger = nil
        refute_nil Asciidoctor::LoggerManager.logger
        assert_kind_of MyLoggerC, Asciidoctor::LoggerManager.logger
      ensure
        Asciidoctor::LoggerManager.logger_class = old_logger_class
        Asciidoctor::LoggerManager.logger = old_logger
      end
    end
  end

  context 'Logger' do
    test 'configures default logger with progname equal to asciidoctor' do
      assert_equal 'asciidoctor', Asciidoctor::LoggerManager.logger.progname
    end

    test 'configures default logger with level equal to WARN' do
      assert_equal Logger::Severity::WARN, Asciidoctor::LoggerManager.logger.level
    end

    test 'configures default logger to write messages to $stderr' do
      out_string, err_string = redirect_streams do |out, err|
        Asciidoctor::LoggerManager.logger.warn 'this is a call'
        [out.string, err.string]
      end
      assert_empty out_string
      refute_empty err_string
      assert_includes err_string, 'this is a call'
    end

    test 'configures default logger to use a formatter that matches traditional format' do
      err_string = redirect_streams do |_, err|
        Asciidoctor::LoggerManager.logger.warn 'this is a call'
        Asciidoctor::LoggerManager.logger.fatal 'it cannot be done'
        err.string
      end
      assert_includes err_string, %(asciidoctor: WARNING: this is a call)
      assert_includes err_string, %(asciidoctor: FAILED: it cannot be done)
    end
  end

  context 'Logging' do
    test 'including Logging gives instance methods on module access to logging infrastructure' do
      module SampleModuleA
        include Asciidoctor::Logging
        def get_logger
          logger
        end
      end

      class SampleClassA
        include SampleModuleA
      end
      assert_same Asciidoctor::LoggerManager.logger, SampleClassA.new.get_logger
      assert SampleClassA.private_method_defined? :logger
    end

    test 'including Logging gives static methods on module access to logging infrastructure' do
      module SampleModuleB
        include Asciidoctor::Logging
        def self.get_logger
          logger
        end
      end

      assert_same Asciidoctor::LoggerManager.logger, SampleModuleB.get_logger
    end

    test 'including Logging gives instance methods on class access to logging infrastructure' do
      class SampleClassC
        include Asciidoctor::Logging
        def get_logger
          logger
        end
      end

      assert_same Asciidoctor::LoggerManager.logger, SampleClassC.new.get_logger
      assert SampleClassC.private_method_defined? :logger
    end

    test 'including Logging gives static methods on class access to logging infrastructure' do
      class SampleClassD
        include Asciidoctor::Logging
        def self.get_logger
          logger
        end
      end

      assert_same Asciidoctor::LoggerManager.logger, SampleClassD.get_logger
    end

    test 'can enrich and auto-format message' do
      class SampleClassE
        include Asciidoctor::Logging
        def create_message cursor
          enrich_message 'Asciidoctor was here', :source_location => cursor
        end
      end

      cursor = Asciidoctor::Reader::Cursor.new 'file.adoc', fixturedir, 'file.adoc', 5
      message = SampleClassE.new.create_message cursor
      assert_equal 'Asciidoctor was here', message[:text]
      assert_same cursor, message[:source_location]
      assert_equal 'file.adoc: line 5: Asciidoctor was here', message.inspect
    end
  end
end
