class AudioSampleValidator < ActiveModel::EachValidator
  def self.kind
    :custom
  end

  def validate_each(record, _attribute, _value)
    return unless record.audio_sample.present?
    unless compare(record.audio_sample)
      record.errors[:audio_sample] <<
        'needs to be direct SoundCloud, Freesound or YouTube link.'
    end
  end

  def compare(audio_sample)
    regexes.any? do |regex|
      !!(audio_sample =~ Regexp.new("https?://(.*\\.)?#{regex}/?#?(&.*)?"))
    end
  end

  def regexes
    youtube_id = '[A-Za-z\d]{11}'
    [
      '(soundcloud\.com|snd\.sc)/[a-z\-\d]+/[a-z\-\d]+',
      'freesound\.org/people/.*/sounds/\d{2,7}',
      "youtube\\.com/watch\\?v=#{youtube_id}",
      "youtu\\.be/#{youtube_id}"
    ]
  end
end
