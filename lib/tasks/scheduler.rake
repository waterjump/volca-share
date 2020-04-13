desc "This task is called by the Heroku scheduler add-on"
task :update_patch_quality => :environment do
  puts "Updating patch quality..."
  UpdatePatchQualityJob.new.perform
  puts "done."
end
