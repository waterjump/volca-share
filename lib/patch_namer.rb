# frozen_string_literal: true

class PatchNamer
  ADJECTIVES =
    %w[
      Squishy Cheap Broken Jaded Sad Aromatic Dumb Awful Lousy
      Gyrating Catatonic Scary Holy Precise Rejected Court-Ordered
      Hermetically\ Sealed Chaotic Underwhelming
      Uncertified Pro\ Bono K-Mart\ Brand Tiny Obligatory Muscular
      Unpopular Unwanted Unwashed OG Recalled Obnoxious Failure-prone Discount
      Second-story Failed Polluted British Hairy Geriatric Minimum\ Wage
      Boring Corporate North\ Korean Sizzling Top\ 10 Pathetic Unauthorized
      Non-Union Double-Glazed Yesterday's Desperate Farty Annoying Tainted
      Delightful Dainty Atomic Sensitive Rotten Delicate Sweaty
    ].freeze

  NOUNS = [
    'Alien', 'Porn', 'Stink', 'Donkey', 'Coffin',
    'Fist', 'Dominatrix', 'Fairy', 'Laundromat',
    'Toilet', 'Truck Stop', 'Burn Ward', 'Tinkle', 'Trash', 'DMV',
    'Bodybuilder', 'COVID', 'Diarrhea', 'Prostitute', 'Divorce Lawyer', 'Dog Show',
    'Flat Earth Conference', 'Bankruptcy', 'Fyre Fest', 'Nostril',
    'Motel 6', 'Piss', 'Barf', 'Shart', 'Kindergartner', 'N64', 'Beanie Baby',
    'Fidget Spinner', 'Gangnam Style', 'Cosby', 'Funeral Home', 'Orthodontist',
    'Deportation', 'Eviction', 'ALF Pog', 'Dumpster', 'Dunning-Kruger', 'Cotton Eye Joe',
    'Hanukkah', 'Christmas', 'Kwanzaa', 'Landlord', 'Jet Ski', 'On Hold',
    'Internet Celebrity', 'On Hold', 'Uncle', 'Egg', 'Tanning Booth'
  ].freeze

  SOUNDS = %w[
    Bass Lead FX Drone Notes Thump Notes Noise Rumble Vibes Rhythms Loop Squelch
    Aura Bloops Plonks Donks Buzz Slapper Pad Stabs Rage Whooshes Reese Farts
    Stab Hit Blast Knocker Bumper Banger Banjo Riser Bomb Chords Bings Pings Muzak™
    Fire /\ Pence\ 2020 Boi Wheeze Womps Smooches Beats
  ].freeze

  SUFFIXES = ['(FINAL)', '(revised)', '(Try #3)', '(Good version)'].freeze

  def call
    suffix = ''
    suffix += " #{SUFFIXES.sample}" if (1..5).to_a.sample == 5

    "#{ADJECTIVES.sample} #{NOUNS.sample} #{SOUNDS.sample}#{suffix}"
  end
end
