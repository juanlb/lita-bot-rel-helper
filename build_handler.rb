module Lita
  module Handlers
    class BuildHandler < Handler
      # config :top_clicks_all_time_url

      STATUS_DIR = '/tmp/lita'
      STATUS_FILE = "#{STATUS_DIR}/status.data"
      EXEC_BUILD_FILE = "#{STATUS_DIR}/build.sh"
      BUILD_LOG_FILE = '/tmp/build_docker.log'
      BUILD_RESULT_FILE = '/tmp/build_result.log'

      route(/^test$/i, command: true) do |response|
        response.reply("Hi #{response.message.user.name}")
      end

      route(/^force_init$/i, command: true, help: {"*force_init*" => "Reset bot status"}) do |response|
        `rm #{STATUS_FILE}` if File.exist?(STATUS_FILE)
        `rm #{EXEC_BUILD_FILE}` if File.exist?(EXEC_BUILD_FILE)
        `rm #{EXEC_BUILD_FILE}_run` if File.exist?("#{EXEC_BUILD_FILE}_run")
        `rm #{BUILD_LOG_FILE}` if File.exist?(BUILD_LOG_FILE)
        `rm #{BUILD_RESULT_FILE}` if File.exist?(BUILD_RESULT_FILE)
        response.reply('`force_init` done.')
      end

      route(/^status$/i, command: true) do |response|
        process_status(response)
        if File.exist?(BUILD_LOG_FILE)
          message = "In case you want to know, these are the last 20 log's lines\n```#{last_log_lines}```"
          response.reply(message)
        end
      end

      route(/^yes$/i, command: true) do |response|
        if status == :waiting_confirmation
          status_building(params)
          response.reply("Great! I'll start the build process, it is going to take several minutes.\n I'll let you know when it is done")
          start_build_process

          every(1) do |timer|
            if File.exist?("#{EXEC_BUILD_FILE}_run") #The build process is execute by the cron
              response.reply('The build process is started in the remote server...')
              timer.stop
            end
          end
          every(1) do |timer|
            if File.exist?(BUILD_RESULT_FILE) # The build process finished, and created this one line file
              build_result = File.open(BUILD_RESULT_FILE).read.chomp
              build_result_a = build_result.split(' ')
              if build_result_a.size == 3 && build_result_a.first == 'Pushed' && build_result_a[1] == 'tag:'
                response.reply("*Build done!* env: `#{params[:env]}`, branch: `#{params[:branch]}`, *tag:* `#{build_result_a[2]}`")
              else
                response.reply('Something went *wrong*. This is the *last 20 lines* of the building process:')
                response.reply("```#{last_log_lines}```")
              end
              status_init
              `rm #{BUILD_RESULT_FILE}` if File.exist?(BUILD_RESULT_FILE)
              `rm #{EXEC_BUILD_FILE}` if File.exist?(EXEC_BUILD_FILE)
              timer.stop
            end
          end
        end
      end

      route(/^no$/i, command: true) do |response|
        if status == :waiting_confirmation
          status_init
          response.reply("Build *cancelled*")
        end
      end

      route(/build/, 
            command: true,
            help: { "*build* [`ENV`] [`BRANCH`]" => "*Build* docker image for `ENV` from `BRANCH`, and *push* it to dockerhub. It returns the docker `TAG`" }) do |response|
        # url = config.top_clicks_all_time_url

        if status == :init
          if response.message.body.strip.split(' ').size != 3
            invalid_params(response)
          elsif not ['production', 'beta', 'demo'].include?(response.message.body.strip.split(' ')[1])
            response.reply(" *#{response.message.body.strip.split(' ')[1]}* is not a valid environment name: *[prodction, beta, demo]*")
            invalid_params(response)
          else
            cmd, env, branch = response.message.body.strip.split(' ')
            status_wait_confirmation(env, branch, response.message.user.name)
            response.reply("I'm going to build a `#{env}` docker image from `#{branch}` branch, Ok? ( *yes* / *no* )")
          end
        else
          response.reply("I'm not ready to build now, I'm in the middle of something, my status is *#{status}*")
          process_status(response)
        end
      end

      private

      def invalid_params(response)
        response.reply('Please, send a full command. Example "*build* *beta* *feature/SEE-100*"')
      end

      def process_status(response)
        case status
        when :init
          response.reply("I'm waiting for instructions")
        when :waiting_confirmation
          response.reply("I'm *waiting confirmation* for build a `#{params[:env]}` docker image from `#{params[:branch]}` branch, started by *#{params[:user]}*, Ok? ( *yes* / *no* )")
        when :building
          response.reply("I'm building right now! `#{params[:env]}` docker image from `#{params[:branch]}` started by *#{params[:user]}*")
        end
      end

      def write_status_file(status, hash = {})
        status_hash = {status: status, params: hash}
        File.write(STATUS_FILE, status_hash)
      end

      def read_status_file
        `mkdir -p #{STATUS_DIR}`

        if not File.exist?(STATUS_FILE)
          status_init
        end

        eval(File.open(STATUS_FILE).read.chomp)
      end

      def last_log_lines
        `tail -20 #{BUILD_LOG_FILE}` if File.exist?(BUILD_LOG_FILE)
      end

      def status
        read_status_file[:status]
      end

      def params
        read_status_file[:params]
      end

      def status_init
        write_status_file(:init)
      end

      def status_wait_confirmation(env, branch, user)
        write_status_file(:waiting_confirmation, {env: env, branch: branch, user: user})
      end

      def status_building(params)
        write_status_file(:building, params)
      end

      def start_build_process
        file_content = "#!/bin/bash\n#{ENV['LITA_BUILD_SCRIPT']} #{params[:env]} #{params[:branch]}\n"
        File.write(EXEC_BUILD_FILE, file_content)
        `chmod +x #{EXEC_BUILD_FILE}`
      end
    end

    Lita.register_handler(BuildHandler)
  end
end