desc 'This task updates patch quality to account for the passage of time'
task :update_patch_quality => :environment do
  puts "Updating patch quality..."
  UpdatePatchQualityJob.new.perform
  puts "done."
end

desc 'This task checks for audio sample availability and marks the record'
task :update_patch_quality => :environment do
  puts "Updating patch audio sample availability..."
  UpdatePatchUpdateAudioSampleAvailableJob.new.perform
  puts "done."
end
