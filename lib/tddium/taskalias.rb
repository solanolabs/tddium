require 'tddium/tasks'

taskmap = {
  :'config:init' => :'tddium:config:init',
  :'config:reset' => :'tddium:config:reset',
  :'dev' => :'tddium:dev',
  :'stopdev' => :'tddium:stopdev',
  :'parallel' => :'tddium:parallel',
  :'sequential' => :'tddium:sequential',
}

taskmap.each do |new, old|
  oldtask = Rake::Task[old]
  task new, oldtask.arg_names => old
  Rake::Task[new].comment = oldtask.comment
  oldtask.clear_comment
end

