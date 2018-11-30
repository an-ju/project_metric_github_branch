require "project_metric_github_branch/version"
require 'project_metric_github_branch/data_generator'
require 'octokit'
require 'json'

class ProjectMetricGithubBranch
  class Error < StandardError; end
  def initialize(credentials, raw_data = nil)
    @project_url = credentials[:github_project]
    @identifier = URI.parse(@project_url).path[1..-1]
    @client = Octokit::Client.new access_token: credentials[:github_access_token]
    @client.auto_paginate = true
    @main_branch = credentials[:github_main_branch]

    self.raw_data = raw_data if raw_data
  end

  def refresh
    set_branches
    set_pulls
    @raw_data = { branches: @branches.map(&:to_h), pulls: @pulls.map(&:to_h) }.to_json
  end

  def raw_data=(new_data)
    @raw_data = new_data
    @branches = JSON.parse(new_data, symbolize_names: true)[:branches]
    @pulls = JSON.parse(new_data, symbolize_names: true)[:pulls]
  end

  def score
    refresh unless @raw_data
    working_branches.length
  end

  def image
    refresh unless @raw_data
    { chartType: 'github_branch',
      data: { standing_branches: standing_branches.map(&:to_h),
              working_branches: working_branches.map(&:to_h),
              legacy_branches: legacy_branches.map(&:to_h)
      }
    }.to_json
  end

  def self.credentials
    %I[github_project github_access_token github_main_branch]
  end

  private

  def set_branches
    @branches = @client.branches(@identifier)
  end

  def set_pulls
    @pulls = @client.pull_requests(@identifier, state: 'all')
  end

  def standing_branches
    open_pr = @pulls.select { |pr| pr[:state].eql? 'open' }
                  .map { |pr| pr[:head][:sha] }
    open_branches.select { |br| open_pr.include? br[:commit][:sha] }
  end

  def working_branches
    open_pr = @pulls.select { |pr| pr[:state].eql? 'open' }
                  .map { |pr| pr[:head][:sha] }
    open_branches.reject { |br| open_pr.include? br[:commit][:sha] || br[:name].eql?(@main_branch) }
  end

  def open_branches
    closed_branches = @pulls.reject { |pr| pr[:merged_at].nil? }
                          .map { |pr| pr[:head][:sha] }
   @branches.reject { |br| closed_branches.include? br[:commit][:sha] }
  end

  def legacy_branches
    closed_branches = @pulls.reject { |pr| pr[:merged_at].nil? }
                          .map { |pr| pr[:head][:sha] }
    @branches.select { |br| closed_branches.include? br[:commit][:sha] }
  end

end
