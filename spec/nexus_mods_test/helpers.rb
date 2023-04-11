require 'digest'
require 'webmock/rspec'
require 'rspec/support/object_formatter'
require 'nexus_mods_test/factories/games'
require 'nexus_mods_test/factories/mods'
require 'nexus_mods_test/factories/mod_files'
require 'nexus_mods'

module NexusModsTest

  module Helpers

    # Integer: Mocked user ID
    MOCKED_USER_ID = 1_234_567

    # String: Mocked API key
    MOCKED_API_KEY = '1234567891234566546543123546879s8df46s5df4sd5f4sd6f87wer9f846sf54sd65v16x5v48r796rwe84f654f35sd1v5df6v54687rUGZWcG0rdz09--62dcd41bb308d2d660548a3cd1ef4094162c4379'

    # String: Mocked user name
    MOCKED_USER_NAME = 'NexusModsUser'

    # String: Mocked user email
    MOCKED_USER_EMAIL = 'nexus_mods_user@test_mail.com'

    # Hash<String, String>: Default HTTP headers returned by the HTTP responses
    DEFAULT_API_HEADERS = {
      'date' => 'Wed, 02 Oct 2019 15:08:43 GMT',
      'content-type' => 'application/json; charset=utf-8',
      'transfer-encoding' => 'chunked',
      'connection' => 'close',
      'set-cookie' => '__cfduid=1234561234561234561234561234561234560028923; expires=Thu, 01-Oct-20 15:08:43 GMT; path=/; domain=.nexusmods.com; HttpOnly; Secure',
      'vary' => 'Accept-Encoding, Origin',
      'userid' => MOCKED_USER_ID.to_s,
      'x-rl-hourly-limit' => '100',
      'x-rl-hourly-remaining' => '100',
      'x-rl-hourly-reset' => '2019-10-02T16:00:00+00:00',
      'x-rl-daily-limit' => '2500',
      'x-rl-daily-remaining' => '2500',
      'x-rl-daily-reset' => '2019-10-03 00:00:00 +0000',
      'cache-control' => 'max-age=0, private, must-revalidate',
      'x-request-id' => '1234561234561234561daf88a8134abc',
      'x-runtime' => '0.022357',
      'strict-transport-security' => 'max-age=15724800; includeSubDomains',
      'expect-ct' => 'max-age=604800, report-uri="https://report-uri.cloudflare.com/cdn-cgi/beacon/expect-ct"',
      'server' => 'cloudflare',
      'cf-ray' => '1234561234561234-MAD'
    }

    # Return the NexusMods instance to be tested.
    # Handle the API key.
    # Cache it for the scope of a test case.
    #
    # Parameters::
    # * *args* (Hash): List of named arguments to give the constructor for the first time usage
    def nexus_mods(**args)
      if @nexus_mods.nil?
        args[:api_key] = MOCKED_API_KEY unless args.key?(:api_key)
        # By default running tests should not persistent cache files
        args[:api_cache_file] = nil unless args.key?(:api_cache_file)
        # Redirect any log into a string so that they don't pollute the tests output and they could be asserted.
        @nexus_mods_logger = StringIO.new
        args[:logger] = Logger.new(@nexus_mods_logger)
        @nexus_mods = NexusMods.new(**args)
      end
      @nexus_mods
    end

    # Get NexusMods logs
    #
    # Result::
    # * String: The NexusMods logs
    def nexus_mods_logs
      @nexus_mods_logger.string
    end

    # Reset the NexusMods instance.
    # Dump the output if needed for debugging purposes.
    def reset_nexus_mods
      if @nexus_mods && test_debug?
        puts '===== NexusMods output BEGIN ====='
        puts nexus_mods_logs
        puts '===== NexusMods output END ====='
      end
      @nexus_mods = nil
    end

    # Expect an HTTP API call to be made, and mock the corresponding HTTP response.
    # Handle the API key and user agent.
    #
    # Parameters::
    # * *host* (String): Expected host being targeted [default: 'api.nexusmodstoto.com']
    # * *http_method* (Symbol): Expected requested HTTP method [default: :get]
    # * *path* (String): Expected requested path [default: '/']
    # * *api_key* (String): Expected API key to be used in request headers [default: MOCKED_API_KEY]
    # * *code* (Integer): Mocked return code [default: 200]
    # * *message* (String): Mocked returned message [default: 'OK']
    # * *json* (Object): Mocked JSON body [default: {}]
    # * *headers* (Hash<String,String>): Mocked additional HTTP headers [default: {}]
    # * *times* (Integer): Number of times the call is expected [default: 1]
    def expect_http_call_to(
      host: 'api.nexusmods.com',
      http_method: :get,
      path: '/',
      api_key: MOCKED_API_KEY,
      code: 200,
      message: 'OK',
      json: {},
      headers: {},
      times: 1
    )
      json_as_str = json.to_json
      mocked_etag = "W/\"#{Digest::MD5.hexdigest("#{path}|#{json_as_str}")}\""
      expected_request_headers = {
        'User-Agent' => "nexus_mods/#{NexusMods::VERSION} (#{RUBY_PLATFORM}) Ruby/#{RUBY_VERSION}",
        'apikey' => api_key
      }
      @expected_stubs << [
        stub_request(http_method, "https://#{host}#{path}").with(headers: expected_request_headers).to_return(
          status: [code, message],
          body: json_as_str,
          headers: DEFAULT_API_HEADERS.
            merge(
              'etag' => mocked_etag
            ).
            merge(headers)
        ),
        times
      ]
    end

    # Expect a successfull call made to validate the user
    #
    # Parameters::
    # * *times* (Integer): Number of times the call is expected [default: 1]
    def expect_validate_user(times: 1)
      expect_http_call_to(
        path: '/v1/users/validate.json',
        json: {
          user_id: MOCKED_USER_ID,
          key: MOCKED_API_KEY,
          name: MOCKED_USER_NAME,
          email: MOCKED_USER_EMAIL,
          is_premium?: false,
          is_supporter?: false,
          profile_url: 'https://www.nexusmods.com/Contents/Images/noavatar.gif',
          is_supporter: false,
          is_premium: false
        },
        times:
      )
    end

    # Setup an API cache file to be used (does not create it)
    #
    # Parameters::
    # * CodeBlock: The code called when the API cache file is reserved
    #   * Parameters::
    #     * *api_cache_file* (String): File name to be used for the API cache file
    def with_api_cache_file
      api_cache_file = "#{Dir.tmpdir}/nexus_mods_test/api_cache.json"
      FileUtils.mkdir_p(File.dirname(api_cache_file))
      FileUtils.rm_f(api_cache_file)
      yield api_cache_file
    end

    # Are we in test debug mode?
    #
    # Result::
    # * Boolean: Are we in test debug mode?
    def test_debug?
      ENV['TEST_DEBUG'] == '1'
    end

  end

end

RSpec.configure do |config|
  config.include NexusModsTest::Helpers
  config.include NexusModsTest::Factories::Games
  config.include NexusModsTest::Factories::Mods
  config.include NexusModsTest::Factories::ModFiles
  config.before do
    @nexus_mods = nil
    # Reload the ApiClient as it stores caches at class level
    NexusMods::ApiClient.clear_cacheable_expiry_caches
    # List of expected stubs and the number of times they were supposed to mock
    # Array< [ WebMock::RequestStub, Integer ] >
    @expected_stubs = []
  end
  config.after do
    @expected_stubs.each do |(stub, times)|
      expect(stub).to have_been_made.times(times)
    end
  end
  config.around do |example|
    example.call
  ensure
    # This would dump the logs in case of debug mode
    reset_nexus_mods
  end
end

# Set a bigger output length for expectation errors, as most error messages include API keys and headers which can be lengthy
RSpec::Support::ObjectFormatter.default_instance.max_formatted_output_length = 16_384
