require "project_metric_github_branch/version"
require 'project_metric_github_branch/data_generator'
require 'octokit'
require 'json'
require 'project_metric_base'

class ProjectMetricGithubBranch
  include ProjectMetricBase
  add_credentials %I[github_project github_access_token github_main_branch]
  add_raw_data %w[github_branches github_pulls]

  class Error < StandardError; end
  def initialize(credentials, raw_data = nil)
    @project_url = credentials[:github_project]
    @identifier = URI.parse(@project_url).path[1..-1]
    @client = Octokit::Client.new access_token: credentials[:github_access_token]
    @client.auto_paginate = true
    @main_branch = credentials[:github_main_branch]

    complete_with raw_data
  end

  def score
    working_branches.length
  end

  def image
    { chartType: 'github_branch',
      data: { standing_branches: standing_branches.map(&:to_h),
              working_branches: working_branches.map(&:to_h),
              legacy_branches: legacy_branches.map(&:to_h)
      }
    }
  end

  private

  def github_branches
    @github_branches = @client.branches(@identifier)
  end

  def github_pulls
    @github_pulls = @client.pull_requests(@identifier, state: 'all')
  end

  def standing_branches
    open_pr = @github_pulls.select { |pr| pr['state'].eql? 'open' }
                  .map { |pr| pr['head']['sha'] }
    open_branches.select { |br| open_pr.include? br['commit']['sha'] }
  end

  def working_branches
    open_pr = @github_pulls.select { |pr| pr['state'].eql? 'open' }
                  .map { |pr| pr['head']['sha'] }
    open_branches.reject { |br| open_pr.include? br['commit']['sha'] || br['name'].eql?(@main_branch) }
  end

  def open_branches
    closed_branches = @github_pulls.reject { |pr| pr['merged_at'].nil? }
                          .map { |pr| pr['head']['sha'] }
   @github_branches.reject { |br| closed_branches.include? br['commit']['sha'] }
  end

  def legacy_branches
    closed_branches = @github_pulls.reject { |pr| pr['merged_at'].nil? }
                          .map { |pr| pr['head']['sha'] }
    @github_branches.select { |br| closed_branches.include? br['commit']['sha'] }
  end

end
