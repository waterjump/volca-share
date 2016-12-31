namespace :volcashare do
  desc 'Populates slugs retroactively'
  task populate_slugs: :environment do
    Patch.where(slug: nil).each do |patch|
      begin
        patch.update_attribute(:slug, patch.name.parameterize)
      rescue
        puts patch.inspect
      end
    end

    User.where(slug: nil).each do |user|
      begin
        user.update_attribute(:slug, user.username.parameterize)
      rescue
        puts user.inspect
      end
    end
  end
end
