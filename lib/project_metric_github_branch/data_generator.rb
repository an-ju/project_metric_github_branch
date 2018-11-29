class ProjectMetricGithubBranch
  def self.fake_data
    [fake_sample(3, 5, 7), fake_sample(3, 1, 5), fake_sample(0, 0, 0)]
  end

  def self.fake_sample(standing, working, legacy)
    { score: working,
      image: { chartType: 'github_branch',
               data: { standing_branches: Array.new(standing) { branch },
                       working_branches: Array.new(working) { branch },
                       legacy_branches: Array.new(legacy) { branch }
               }
      }.to_json
    }

  end

  def self.branch
    {"name":"test","commit":{"sha":"bd5421d1c58d7840b7e7ec07cf141422280963ea","url":"https://api.github.com/repos/DrakeW/projectscope/commits/bd5421d1c58d7840b7e7ec07cf141422280963ea"}}
  end

end