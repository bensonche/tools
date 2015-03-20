#!/usr/bin/ruby

module CheckBranch
	def self.cleanup
		puts
		puts
		puts 'Cleaning up'
		system 'git reset --hard'
		system "git checkout #{@head}"

		exit
	end

	def self.validateParams
		if ARGV.length < 1
			abort "Must specify branch to check"
		end

		@right = ARGV[0]

		@left = 'origin/release'
		if ARGV[1] != nil
			@left = ARGV[1]
		end

		unless @left.start_with? 'origin/'
			@left = "origin/#{@left}"
		end

		unless @right.start_with? 'origin/'
			@right = "origin/#{@right}"
		end
	end

	def self.checkBranchUpdated
		# Check whether branch is updated
		count = `git cherry -v #{@right} #{@left}`.strip.length
		if count != 0
			puts "Branch not updated"
			puts

			system 'git branch -D temp_bc_check_branch'
			system "git checkout -b temp_bc_check_branch #{@right}" or abort

			Signal.trap('INT') { CheckBranch.cleanup }

			success = system "git merge -sresolve #{@left}"
			unless success
				puts
				puts 'Error updating the branch'
				print "Return to previous branch #{@head}? [y/n] "

				loop do
					response = STDIN.gets.chomp.downcase

					if response == "y"
						cleanup
					elsif response == "n"
						abort
					else
						print "Please reply with y or n: "
					end
				end
			end
		end
	end

	def self.getCurrentBranch
		`git rev-parse --abbrev-ref HEAD`
	end

	def self.run
		validateParams
		repoRoot = `git rev-parse --show-toplevel`.strip
		Dir.chdir(repoRoot)

		@head = getCurrentBranch

		checkBranchUpdated

		puts "\e[0;32mList of commits in this branch:\e[00m"
		puts `git log --left-right --cherry-pick --pretty=format:"%ad, %aN: %s" #{@left}..#{@right}`
		puts
		puts "Press [Enter] to continue..."
		STDIN.gets

		puts

		puts "\e[0;32mList of files modified by this branch:\e[00m"
		puts `git diff --name-status #{@left} #{@right}`
		puts
		puts "Press [Enter] to continue..."
		STDIN.gets

		files = `git diff --name-only #{@left} #{@right}`
		files.each_line do |name|
			system "git difftool -w #{@left} #{@right} -- '#{@name}' &"
		end

		if @head != getCurrentBranch
			system "git checkout #{@head}"
		end
	end
end

CheckBranch.run
